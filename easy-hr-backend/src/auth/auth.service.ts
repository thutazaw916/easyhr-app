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

    // Check if email already exists
    const { data: existing } = await db
      .from('companies')
      .select('id')
      .eq('email', dto.email)
      .single();

    if (existing) {
      throw new ConflictException('Company with this email already exists');
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
        email: dto.email,
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

    // Send verification code via email
    const emailSent = await this.emailService.sendVerificationCode(
      dto.email,
      dto.name,
      verificationCode,
    );

    return {
      message: emailSent
        ? 'Company registered! Please check your email for the verification code.'
        : 'Company registered! Verification code generated (email delivery pending).',
      company_id: company.id,
      company_name: company.name,
      email_sent: emailSent,
      // Fallback: show code if email failed (dev safety net)
      ...(!emailSent && { verification_code: verificationCode }),
    };
  }

  // ============================================
  // 2. Verify Company
  // ============================================
  async verifyCompany(dto: VerifyCompanyDto) {
    const db = this.supabaseService.getClient();

    const { data: company, error } = await db
      .from('companies')
      .select('*')
      .eq('email', dto.email)
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

    // Find verified company
    const { data: company } = await db
      .from('companies')
      .select('*')
      .eq('email', dto.email)
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

    if (existingOwner) {
      throw new ConflictException('Owner account already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(dto.password, 12);

    // Create owner employee record
    const { data: owner, error } = await db
      .from('employees')
      .insert({
        company_id: company.id,
        first_name: dto.owner_name,
        phone: dto.owner_phone,
        email: dto.email,
        role: 'owner',
        join_date: new Date().toISOString().split('T')[0],
        contract_type: 'permanent',
        is_active: true,
      })
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);

    // Store password hash (in a separate auth table or Supabase Auth)
    // For simplicity, we'll use a custom auth_credentials table
    await db
      .from('auth_credentials')
      .insert({
        employee_id: owner.id,
        email: dto.email,
        password_hash: hashedPassword,
      });

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

    // Find credentials
    const { data: cred } = await db
      .from('auth_credentials')
      .select('*, employee:employee_id(*)')
      .eq('email', dto.email)
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