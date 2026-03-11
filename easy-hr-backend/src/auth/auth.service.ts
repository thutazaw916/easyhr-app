// src/auth/auth.service.ts
import { Injectable, BadRequestException, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { SupabaseService } from '../supabase/supabase.service';
import { EmailService } from '../email/email.service';
import {
  CompanySignUpDto,
  VerifyCompanyDto,
  SetPasswordDto,
  AdminLoginDto,
  RequestOtpDto,
  VerifyOtpDto,
  FirebasePhoneLoginDto,
  GoogleLoginDto,
  AppleLoginDto,
  OnboardCompanyDto,
  AcceptInviteDto,
} from './dto/auth.dto';
import * as admin from 'firebase-admin';

@Injectable()
export class AuthService {
  constructor(
    private supabaseService: SupabaseService,
    private jwtService: JwtService,
    private emailService: EmailService,
  ) {}

  // ============================================
  // 1. Company Sign Up
  // ============================================
  async companySignUp(dto: CompanySignUpDto) {
    const db = this.supabaseService.getClient();

    const normalizedEmail = dto.email.trim().toLowerCase();

    // Check whitelist enforcement
    const { data: whitelistSetting } = await db
      .from('platform_settings')
      .select('value')
      .eq('key', 'whitelist_enabled')
      .single();

    if (whitelistSetting?.value === 'true') {
      const { data: whitelisted } = await db
        .from('email_whitelist')
        .select('id')
        .eq('email', normalizedEmail)
        .single();

      if (!whitelisted) {
        throw new BadRequestException(
          'Registration is currently by invitation only. Please contact the platform admin for access.'
        );
      }
    }

    // Check if email already exists
    const { data: existing } = await db
      .from('companies')
      .select('id, verified')
      .eq('email', normalizedEmail)
      .single();

    if (existing) {
      if (existing.verified) {
        throw new ConflictException('Company with this email already exists');
      }
      // Not verified yet - delete old record and allow re-registration
      await db.from('companies').delete().eq('id', existing.id);
    }

    // Generate 6-digit verification code
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();

    // Create company
    const { data: company, error } = await db
      .from('companies')
      .insert({
        name: dto.name,
        name_mm: dto.name_mm,
        business_type: dto.business_type,
        email: normalizedEmail,
        phone: dto.phone,
        address: dto.address,
        city: dto.city,
        state_region: dto.state_region,
        verification_code: verificationCode,
        verified: false,
      })
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);

    // Send verification code via email (non-blocking - don't wait)
    this.emailService.sendVerificationCode(
      normalizedEmail,
      dto.name,
      verificationCode,
    ).catch(() => {});

    return {
      message: 'Company registered! Verification code generated.',
      company_id: company.id,
      company_name: company.name,
      dev_verification_code: verificationCode,
    };
  }

  // ============================================
  // 2. Verify Company
  // ============================================
  async verifyCompany(dto: VerifyCompanyDto) {
    const db = this.supabaseService.getClient();

    const normalizedEmail = dto.email.trim().toLowerCase();

    const { data: company, error } = await db
      .from('companies')
      .select('*')
      .eq('email', normalizedEmail)
      .eq('verification_code', dto.verification_code)
      .single();

    if (error || !company) {
      throw new BadRequestException('Invalid verification code');
    }

    if (company.verified) {
      throw new BadRequestException('Company already verified');
    }

    // Update company as verified
    await db
      .from('companies')
      .update({
        verified: true,
        verification_code: null,
        subscription_start: new Date().toISOString(),
        subscription_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30-day trial
      })
      .eq('id', company.id);

    // Auto-create default "Head Office" branch with QR enabled
    const qrSecret = 'EHR-' + Math.random().toString(36).substring(2, 15) + Date.now().toString(36);
    await db.from('branches').insert({
      company_id: company.id,
      name: 'Head Office',
      name_mm: 'ရုံးချုပ်',
      is_active: true,
      qr_code_enabled: true,
      qr_secret_key: qrSecret,
    });

    return {
      message: 'Company verified successfully! Please set up your owner account.',
      company_id: company.id,
    };
  }

  // ============================================
  // 3. Set Owner Password (First Time Setup)
  // ============================================
  async setOwnerPassword(dto: SetPasswordDto) {
    const db = this.supabaseService.getClient();

    const normalizedEmail = dto.email.trim().toLowerCase();

    // Find verified company
    const { data: company } = await db
      .from('companies')
      .select('*')
      .eq('email', normalizedEmail)
      .eq('verified', true)
      .single();

    if (!company) {
      throw new BadRequestException('Company not found or not verified');
    }

    // Check if owner already exists
    const { data: existingOwner } = await db
      .from('employees')
      .select('id')
      .eq('company_id', company.id)
      .eq('role', 'owner')
      .single();

    // Hash password
    const hashedPassword = await bcrypt.hash(dto.password, 12);

    let ownerId: string;

    if (existingOwner?.id) {
      ownerId = existingOwner.id;

      // Keep owner profile info reasonably up to date
      await db
        .from('employees')
        .update({
          first_name: dto.owner_name,
          phone: dto.owner_phone,
          email: normalizedEmail,
        })
        .eq('id', ownerId);
    } else {
      // Create owner employee record
      const { data: owner, error } = await db
        .from('employees')
        .insert({
          company_id: company.id,
          first_name: dto.owner_name,
          phone: dto.owner_phone,
          email: normalizedEmail,
          role: 'owner',
          join_date: new Date().toISOString().split('T')[0],
          contract_type: 'permanent',
          is_active: true,
        })
        .select()
        .single();

      if (error) throw new BadRequestException(error.message);
      ownerId = owner.id;
    }

    // Store / update password hash (custom auth_credentials table)
    await db
      .from('auth_credentials')
      .upsert(
        {
          employee_id: ownerId,
          email: normalizedEmail,
          password_hash: hashedPassword,
        },
        { onConflict: 'email' },
      );

    // Fetch owner for token generation
    const { data: owner } = await db
      .from('employees')
      .select('*')
      .eq('id', ownerId)
      .single();

    // Generate JWT token
    const token = this.generateToken(owner, company);

    return {
      message: 'Owner account created successfully!',
      access_token: token,
      user: {
        id: owner.id,
        name: owner.first_name,
        email: owner.email,
        role: owner.role,
        company_id: company.id,
        company_name: company.name,
      },
    };
  }

  // ============================================
  // 4. Admin Login (Owner / HR - Email + Password)
  // ============================================
  async adminLogin(dto: AdminLoginDto) {
    const db = this.supabaseService.getClient();

    const normalizedEmail = dto.email.trim().toLowerCase();

    // Find credentials
    const { data: cred } = await db
      .from('auth_credentials')
      .select('*, employee:employee_id(*)')
      .eq('email', normalizedEmail)
      .single();

    if (!cred) {
      throw new UnauthorizedException('Invalid email or password');
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(dto.password, cred.password_hash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const employee = cred.employee;

    // Check if employee is active
    if (!employee.is_active) {
      throw new UnauthorizedException('Account is deactivated');
    }

    // Get company
    const { data: company } = await db
      .from('companies')
      .select('*')
      .eq('id', employee.company_id)
      .single();

    // Update last login
    await db
      .from('employees')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', employee.id);

    // Generate JWT
    const token = this.generateToken(employee, company);

    // Calculate subscription info (with whitelist bypass)
    const subscription = await this._getSubscriptionInfo(company);

    return {
      access_token: token,
      user: {
        id: employee.id,
        name: employee.first_name + ' ' + (employee.last_name || ''),
        email: employee.email,
        phone: employee.phone,
        role: employee.role,
        company_id: company.id,
        company_name: company.name,
        profile_photo_url: employee.profile_photo_url,
        language: employee.language,
        dark_mode: employee.dark_mode,
      },
      subscription,
    };
  }

  // ============================================
  // 5. Employee Request OTP
  // ============================================
  async requestOtp(dto: RequestOtpDto) {
    const db = this.supabaseService.getClient();

    // Find employee by phone
    const { data: employee } = await db
      .from('employees')
      .select('*')
      .eq('phone', dto.phone)
      .eq('is_active', true)
      .single();

    if (!employee) {
      throw new BadRequestException('Phone number not registered. Please contact your HR.');
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    // Store OTP
    await db.from('otp_codes').upsert({
      phone: dto.phone,
      otp_code: otp,
      expires_at: expiresAt.toISOString(),
      is_used: false,
    });

    // TODO: Send OTP via Myanmar SMS gateway
    // In production: integrate with MPT/Ooredoo/Atom SMS API

    return {
      message: 'OTP sent to your phone number',
      // Remove in production!
      dev_otp: otp,
    };
  }

  // ============================================
  // 6. Employee Verify OTP & Login
  // ============================================
  async verifyOtp(dto: VerifyOtpDto) {
    const db = this.supabaseService.getClient();

    // Check OTP
    const { data: otpRecord } = await db
      .from('otp_codes')
      .select('*')
      .eq('phone', dto.phone)
      .eq('otp_code', dto.otp)
      .eq('is_used', false)
      .single();

    if (!otpRecord) {
      throw new BadRequestException('Invalid OTP');
    }

    // Check expiry
    if (new Date(otpRecord.expires_at) < new Date()) {
      throw new BadRequestException('OTP expired. Please request a new one.');
    }

    // Mark OTP as used
    await db
      .from('otp_codes')
      .update({ is_used: true })
      .eq('id', otpRecord.id);

    // Find employee
    const { data: employee } = await db
      .from('employees')
      .select('*')
      .eq('phone', dto.phone)
      .eq('is_active', true)
      .single();

    if (!employee) {
      throw new UnauthorizedException('Employee not found');
    }

    // Get company
    const { data: company } = await db
      .from('companies')
      .select('*')
      .eq('id', employee.company_id)
      .single();

    // Update last login
    await db
      .from('employees')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', employee.id);

    // Generate JWT
    const token = this.generateToken(employee, company);

    return {
      access_token: token,
      user: {
        id: employee.id,
        name: employee.first_name + ' ' + (employee.last_name || ''),
        email: employee.email,
        phone: employee.phone,
        role: employee.role,
        company_id: company.id,
        company_name: company.name,
        department_id: employee.department_id,
        branch_id: employee.branch_id,
        position_id: employee.position_id,
        profile_photo_url: employee.profile_photo_url,
        language: employee.language,
        dark_mode: employee.dark_mode,
      },
    };
  }

  // ============================================
  // 7. Firebase Phone Auth Login
  // ============================================
  async firebasePhoneLogin(dto: FirebasePhoneLoginDto) {
    const db = this.supabaseService.getClient();

    // Verify Firebase ID token
    let decodedToken: admin.auth.DecodedIdToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(dto.firebase_id_token);
    } catch (e) {
      throw new UnauthorizedException('Invalid Firebase token');
    }

    // Extract phone number from Firebase token
    const firebasePhone = decodedToken.phone_number; // Format: +959xxxxxxxx
    if (!firebasePhone) {
      throw new BadRequestException('No phone number in Firebase token');
    }

    // Normalize phone: convert +959xxx to 09xxx for DB lookup
    let normalizedPhone = dto.phone.trim();
    if (normalizedPhone.startsWith('+95')) {
      normalizedPhone = '0' + normalizedPhone.substring(3);
    }

    // Find employee by phone
    const { data: employee } = await db
      .from('employees')
      .select('*')
      .eq('phone', normalizedPhone)
      .eq('is_active', true)
      .single();

    if (!employee) {
      // Try with original phone format
      const { data: emp2 } = await db
        .from('employees')
        .select('*')
        .eq('phone', dto.phone.trim())
        .eq('is_active', true)
        .single();

      if (!emp2) {
        throw new BadRequestException('Phone number not registered. Please contact your HR.');
      }

      return this._loginEmployee(emp2);
    }

    return this._loginEmployee(employee);
  }

  private async _loginEmployee(employee: any) {
    const db = this.supabaseService.getClient();

    // Get company
    const { data: company } = await db
      .from('companies')
      .select('*')
      .eq('id', employee.company_id)
      .single();

    // Update last login
    await db
      .from('employees')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', employee.id);

    // Generate JWT
    const token = this.generateToken(employee, company);

    // Calculate subscription info (with whitelist bypass)
    const subscription = await this._getSubscriptionInfo(company);

    return {
      access_token: token,
      user: {
        id: employee.id,
        name: employee.first_name + ' ' + (employee.last_name || ''),
        email: employee.email,
        phone: employee.phone,
        role: employee.role,
        company_id: company.id,
        company_name: company.name,
        department_id: employee.department_id,
        branch_id: employee.branch_id,
        position_id: employee.position_id,
        profile_photo_url: employee.profile_photo_url,
        language: employee.language,
        dark_mode: employee.dark_mode,
      },
      subscription,
    };
  }

  // ============================================
  // 8. Google Social Login
  // ============================================
  async googleLogin(dto: GoogleLoginDto) {
    const db = this.supabaseService.getClient();

    // Verify Firebase ID token (Google Sign-In goes through Firebase Auth)
    let decodedToken: admin.auth.DecodedIdToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(dto.id_token);
    } catch (e) {
      throw new UnauthorizedException('Invalid Google token');
    }

    const email = decodedToken.email?.toLowerCase().trim();
    if (!email) {
      throw new BadRequestException('No email found in Google account');
    }

    const googleName = decodedToken.name || email.split('@')[0];
    const googlePhoto = decodedToken.picture || null;

    // Check if user exists as employee (by email)
    const { data: employee } = await db
      .from('employees')
      .select('*')
      .eq('email', email)
      .eq('is_active', true)
      .single();

    if (employee) {
      // Existing user — login normally
      return this._loginEmployee(employee);
    }

    // Check if company exists with this email (owner who signed up but maybe via email flow)
    const { data: company } = await db
      .from('companies')
      .select('*')
      .eq('email', email)
      .single();

    if (company) {
      // Company exists, find the owner employee
      const { data: ownerEmp } = await db
        .from('employees')
        .select('*')
        .eq('company_id', company.id)
        .eq('role', 'owner')
        .eq('is_active', true)
        .single();

      if (ownerEmp) {
        return this._loginEmployee(ownerEmp);
      }
    }

    // New user — needs company onboarding
    return {
      needs_onboarding: true,
      google_user: {
        email,
        name: googleName,
        photo_url: googlePhoto,
      },
    };
  }

  // ============================================
  // 8b. Apple Social Login
  // ============================================
  async appleLogin(dto: AppleLoginDto) {
    const db = this.supabaseService.getClient();

    // Verify Firebase ID token (Apple Sign-In goes through Firebase Auth)
    let decodedToken: admin.auth.DecodedIdToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(dto.id_token);
    } catch (e) {
      throw new UnauthorizedException('Invalid Apple token');
    }

    const email = decodedToken.email?.toLowerCase().trim();
    if (!email) {
      throw new BadRequestException('No email found in Apple account');
    }

    const appleName = decodedToken.name || email.split('@')[0];

    // Check if user exists as employee (by email)
    const { data: employee } = await db
      .from('employees')
      .select('*')
      .eq('email', email)
      .eq('is_active', true)
      .single();

    if (employee) {
      return this._loginEmployee(employee);
    }

    // Check if company exists with this email
    const { data: company } = await db
      .from('companies')
      .select('*')
      .eq('email', email)
      .single();

    if (company) {
      const { data: ownerEmp } = await db
        .from('employees')
        .select('*')
        .eq('company_id', company.id)
        .eq('role', 'owner')
        .eq('is_active', true)
        .single();

      if (ownerEmp) {
        return this._loginEmployee(ownerEmp);
      }
    }

    // New user — needs company onboarding
    return {
      needs_onboarding: true,
      apple_user: {
        email,
        name: appleName,
      },
    };
  }

  // ============================================
  // 9. Onboard Company (after Google/Apple login, new user)
  // ============================================
  async onboardCompany(dto: OnboardCompanyDto) {
    const db = this.supabaseService.getClient();

    // Verify Firebase ID token again
    let decodedToken: admin.auth.DecodedIdToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(dto.id_token);
    } catch (e) {
      throw new UnauthorizedException('Invalid Google token');
    }

    const email = decodedToken.email?.toLowerCase().trim();
    if (!email) {
      throw new BadRequestException('No email found in Google account');
    }

    // Check if company already exists with this email
    const { data: existing } = await db
      .from('companies')
      .select('id')
      .eq('email', email)
      .single();

    if (existing) {
      throw new ConflictException('A company with this email already exists');
    }

    // Create company (auto-verified since Google auth confirms email)
    const now = new Date();
    const trialEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const { data: company, error: companyError } = await db
      .from('companies')
      .insert({
        name: dto.company_name,
        name_mm: dto.company_name_mm || null,
        email,
        phone: dto.phone,
        business_type: dto.business_type,
        address: dto.address || null,
        city: dto.city || null,
        verified: true,
        is_active: true,
        subscription_plan: 'free',
        subscription_status: 'active',
        subscription_start: now.toISOString(),
        subscription_end: trialEnd.toISOString(),
        max_employees: 9,
      })
      .select()
      .single();

    if (companyError) throw new BadRequestException(companyError.message);

    // Auto-create default "Head Office" branch with QR
    const qrSecret = 'EHR-' + Math.random().toString(36).substring(2, 15) + Date.now().toString(36);
    await db.from('branches').insert({
      company_id: company.id,
      name: 'Head Office',
      name_mm: 'ရုံးချုပ်',
      is_active: true,
      qr_code_enabled: true,
      qr_secret_key: qrSecret,
    });

    // Create owner employee
    const nameParts = dto.owner_name.trim().split(' ');
    const firstName = nameParts[0];
    const lastName = nameParts.slice(1).join(' ') || null;

    const { data: owner, error: ownerError } = await db
      .from('employees')
      .insert({
        company_id: company.id,
        first_name: firstName,
        last_name: lastName,
        email,
        phone: dto.phone,
        role: 'owner',
        is_active: true,
      })
      .select()
      .single();

    if (ownerError) throw new BadRequestException(ownerError.message);

    // Generate JWT and return login response
    const token = this.generateToken(owner, company);

    return {
      access_token: token,
      user: {
        id: owner.id,
        name: dto.owner_name,
        email,
        phone: dto.phone,
        role: 'owner',
        company_id: company.id,
        company_name: company.name,
        profile_photo_url: decodedToken.picture || null,
        language: 'mm',
        dark_mode: false,
      },
      subscription: {
        plan: 'free',
        status: 'active',
        expires: trialEnd.toISOString(),
        days_remaining: 30,
        max_employees: 9,
        is_expired: false,
      },
    };
  }

  // ============================================
  // 10. Accept Employee Invitation
  // ============================================
  async acceptInvite(dto: AcceptInviteDto) {
    const db = this.supabaseService.getClient();

    // Find invitation by code and phone
    const { data: invite } = await db
      .from('employee_invitations')
      .select('*')
      .eq('invite_code', dto.invite_code.toUpperCase())
      .eq('phone', dto.phone)
      .eq('status', 'pending')
      .single();

    if (!invite) {
      throw new BadRequestException('Invalid or expired invitation code');
    }

    // Check expiry
    if (new Date(invite.expires_at) < new Date()) {
      await db.from('employee_invitations').update({ status: 'expired' }).eq('id', invite.id);
      throw new BadRequestException('Invitation has expired. Ask your employer for a new one.');
    }

    // Check if employee already exists
    const { data: existing } = await db
      .from('employees')
      .select('id')
      .eq('company_id', invite.company_id)
      .eq('phone', dto.phone)
      .single();

    if (existing) {
      throw new ConflictException('You are already registered in this company');
    }

    // Create employee from invitation
    const nameParts = invite.name.trim().split(' ');
    const { data: employee, error: empError } = await db
      .from('employees')
      .insert({
        company_id: invite.company_id,
        first_name: nameParts[0],
        last_name: nameParts.slice(1).join(' ') || null,
        phone: dto.phone,
        role: invite.role || 'employee',
        department_id: invite.department_id,
        branch_id: invite.branch_id,
        position_id: invite.position_id,
        is_active: true,
      })
      .select()
      .single();

    if (empError) throw new BadRequestException(empError.message);

    // Mark invitation as accepted
    await db.from('employee_invitations')
      .update({ status: 'accepted', accepted_at: new Date().toISOString() })
      .eq('id', invite.id);

    // Get company for token
    const { data: company } = await db
      .from('companies')
      .select('*')
      .eq('id', invite.company_id)
      .single();

    // Generate JWT and return login response
    const token = this.generateToken(employee, company);

    return {
      message: 'Welcome! You have joined the company.',
      message_mm: 'ကြိုဆိုပါတယ်! ကုမ္ပဏီသို့ ဝင်ရောက်ပြီးပါပြီ။',
      access_token: token,
      user: {
        id: employee.id,
        name: invite.name,
        phone: dto.phone,
        role: employee.role,
        company_id: company.id,
        company_name: company.name,
      },
    };
  }

  // ============================================
  // Helper: Get subscription info with whitelist bypass
  // ============================================
  private async _getSubscriptionInfo(company: any) {
    const db = this.supabaseService.getClient();

    // Check whitelist bypass
    const { data: whitelistSetting } = await db
      .from('platform_settings')
      .select('value')
      .eq('key', 'whitelist_enabled')
      .maybeSingle();

    if (whitelistSetting?.value === 'true') {
      const companyEmail = (company.email || '').toLowerCase();
      const { data: whitelisted } = await db
        .from('email_whitelist')
        .select('id')
        .eq('email', companyEmail)
        .maybeSingle();

      if (whitelisted) {
        return {
          plan: 'enterprise',
          status: 'active',
          expires: null,
          days_remaining: 99999,
          max_employees: 9999,
          is_expired: false,
          whitelisted: true,
        };
      }
    }

    // Normal subscription info
    const now = new Date();
    const subEnd = company.subscription_end ? new Date(company.subscription_end) : null;
    const daysLeft = subEnd
      ? Math.max(0, Math.ceil((subEnd.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)))
      : 0;

    return {
      plan: company.subscription_plan || 'free',
      status: company.subscription_status || 'active',
      expires: company.subscription_end,
      days_remaining: daysLeft,
      max_employees: company.max_employees || 9,
      is_expired: subEnd ? subEnd < now : false,
    };
  }

  // ============================================
  // Helper: Generate JWT Token
  // ============================================
  private generateToken(employee: any, company: any): string {
    const payload = {
      sub: employee.id,
      email: employee.email,
      phone: employee.phone,
      role: employee.role,
      company_id: company.id,
      company_name: company.name,
    };
    return this.jwtService.sign(payload);
  }
}