// src/employee/employee.service.ts
import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class EmployeeService {
  constructor(private supabaseService: SupabaseService) {}

  // ============================================
  // Add New Employee (Owner/HR)
  // ============================================
  async addEmployee(companyId: string, data: {
    first_name: string;
    last_name?: string;
    name_mm?: string;
    phone: string;
    email?: string;
    department_id?: string;
    position_id?: string;
    branch_id?: string;
    role?: string;
    join_date?: string;
    hire_date?: string;
    contract_type?: string;
    gender?: string;
    position?: string;
    employee_code?: string;
    base_salary?: number;
    nrc_number?: string;
    date_of_birth?: string;
  }) {
    const db = this.supabaseService.getClient();

    // Check phone uniqueness within company
    const { data: existing } = await db
      .from('employees')
      .select('id')
      .eq('company_id', companyId)
      .eq('phone', data.phone)
      .maybeSingle();

    if (existing) {
      throw new ConflictException('Employee with this phone number already exists in your company');
    }

    // Check max employees limit
    const { data: company } = await db
      .from('companies')
      .select('max_employees')
      .eq('id', companyId)
      .single();

    const { count: currentCount } = await db
      .from('employees')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('is_active', true);

    if (currentCount >= company.max_employees) {
      throw new BadRequestException(
        `Employee limit reached (${company.max_employees}). Please upgrade your plan.`
      );
    }

    // Auto-generate employee code if not provided
    let employeeCode = data.employee_code;
    if (!employeeCode) {
      const nextNum = (currentCount || 0) + 1;
      let attempt = nextNum;
      employeeCode = `EMP-${String(attempt).padStart(3, '0')}`;
      // Check uniqueness and increment if needed
      let maxAttempts = 100;
      while (maxAttempts-- > 0) {
        const { data: codeCheck } = await db
          .from('employees')
          .select('id')
          .eq('company_id', companyId)
          .eq('employee_code', employeeCode)
          .maybeSingle();
        if (!codeCheck) break;
        attempt++;
        employeeCode = `EMP-${String(attempt).padStart(3, '0')}`;
      }
    }

    // Use join_date (the actual DB column name)
    const joinDate = data.join_date || data.hire_date;

    // Build insert data — only include non-null fields
    const insertData: Record<string, any> = {
      company_id: companyId,
      first_name: data.first_name,
      phone: data.phone,
      role: data.role || 'employee',
      employee_code: employeeCode,
      is_active: true,
    };
    if (data.last_name) insertData.last_name = data.last_name;
    if (data.name_mm) insertData.name_mm = data.name_mm;
    if (data.email) insertData.email = data.email;
    if (data.department_id) insertData.department_id = data.department_id;
    if (data.position_id) insertData.position_id = data.position_id;
    if (data.branch_id) insertData.branch_id = data.branch_id;
    if (data.gender) insertData.gender = data.gender;
    if (data.position) insertData.position = data.position;
    if (data.base_salary) insertData.base_salary = Number(data.base_salary);
    if (data.nrc_number) insertData.nrc_number = data.nrc_number;
    if (joinDate) insertData.join_date = joinDate;
    if (data.date_of_birth) insertData.date_of_birth = data.date_of_birth;
    if (data.contract_type) insertData.contract_type = data.contract_type;

    // Create employee
    try {
      const employee = await this.supabaseService.create('employees', insertData);
      return {
        message: 'Employee added successfully',
        employee,
      };
    } catch (err: any) {
      console.error('Employee create error:', err);
      throw new BadRequestException(
        err?.message || err?.details || JSON.stringify(err) || 'Failed to create employee'
      );
    }
  }

  // ============================================
  // List Employees
  // ============================================
  async listEmployees(companyId: string, filters?: {
    department_id?: string;
    branch_id?: string;
    role?: string;
    is_active?: boolean;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const db = this.supabaseService.getClient();
    const page = filters?.page || 1;
    const limit = filters?.limit || 20;
    const offset = (page - 1) * limit;

    let query = db
      .from('employees')
      .select(`
        *,
        department:department_id(id, name, name_mm),
        position:position_id(id, title, title_mm),
        branch:branch_id(id, name, name_mm)
      `, { count: 'exact' })
      .eq('company_id', companyId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (filters?.department_id) query = query.eq('department_id', filters.department_id);
    if (filters?.branch_id) query = query.eq('branch_id', filters.branch_id);
    if (filters?.role) query = query.eq('role', filters.role);
    if (filters?.is_active !== undefined) query = query.eq('is_active', filters.is_active);
    if (filters?.search) {
      query = query.or(`first_name.ilike.%${filters.search}%,last_name.ilike.%${filters.search}%,phone.ilike.%${filters.search}%,employee_code.ilike.%${filters.search}%`);
    }

    const { data, count, error } = await query;
    if (error) throw error;

    return {
      employees: data,
      pagination: {
        total: count,
        page,
        limit,
        total_pages: Math.ceil((count || 0) / limit),
      },
    };
  }

  // ============================================
  // Get Employee Detail
  // ============================================
  async getEmployee(companyId: string, employeeId: string) {
    const db = this.supabaseService.getClient();

    const { data, error } = await db
      .from('employees')
      .select(`
        *,
        department:department_id(id, name, name_mm),
        position:position_id(id, title, title_mm),
        branch:branch_id(id, name, name_mm)
      `)
      .eq('id', employeeId)
      .eq('company_id', companyId)
      .single();

    if (error || !data) throw new NotFoundException('Employee not found');
    return data;
  }

  // ============================================
  // Update Employee
  // ============================================
  async updateEmployee(companyId: string, employeeId: string, data: any) {
    const db = this.supabaseService.getClient();

    // Verify employee belongs to company
    const existing = await this.getEmployee(companyId, employeeId);
    if (!existing) throw new NotFoundException('Employee not found');

    const { data: updated, error } = await db
      .from('employees')
      .update(data)
      .eq('id', employeeId)
      .eq('company_id', companyId)
      .select()
      .single();

    if (error) throw error;
    return updated;
  }

  // ============================================
  // Deactivate Employee (Soft Delete)
  // ============================================
  async deactivateEmployee(companyId: string, employeeId: string) {
    return this.updateEmployee(companyId, employeeId, {
      is_active: false,
      resignation_date: new Date().toISOString().split('T')[0],
    });
  }

  // ============================================
  // Get My Profile (Employee Self)
  // ============================================
  async getMyProfile(employeeId: string) {
    const db = this.supabaseService.getClient();

    const { data, error } = await db
      .from('employees')
      .select(`
        *,
        department:department_id(id, name, name_mm),
        position:position_id(id, title, title_mm),
        branch:branch_id(id, name, name_mm),
        company:company_id(id, name, name_mm, logo_url)
      `)
      .eq('id', employeeId)
      .single();

    if (error) throw new NotFoundException('Profile not found');
    return data;
  }

  // ============================================
  // Update My Profile Settings
  // ============================================
  async updateMySettings(employeeId: string, data: {
    language?: string;
    dark_mode?: boolean;
    notification_enabled?: boolean;
  }) {
    const db = this.supabaseService.getClient();

    const { data: updated, error } = await db
      .from('employees')
      .update(data)
      .eq('id', employeeId)
      .select('id, language, dark_mode, notification_enabled')
      .single();

    if (error) throw error;
    return updated;
  }

  // ============================================
  // Invite Employee (generates invite code)
  // ============================================
  async inviteEmployee(companyId: string, data: {
    phone: string;
    name: string;
    role?: string;
    department_id?: string;
    branch_id?: string;
    position_id?: string;
  }) {
    const db = this.supabaseService.getClient();

    // Check if phone already exists in this company
    const { data: existing } = await db
      .from('employees')
      .select('id')
      .eq('company_id', companyId)
      .eq('phone', data.phone)
      .single();

    if (existing) {
      throw new ConflictException('Employee with this phone already exists');
    }

    // Check max employees limit
    const { data: company } = await db
      .from('companies')
      .select('max_employees, name')
      .eq('id', companyId)
      .single();

    const { count } = await db
      .from('employees')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('is_active', true);

    if (count >= company.max_employees) {
      throw new BadRequestException(`Employee limit reached (${company.max_employees}). Upgrade your plan.`);
    }

    // Generate 6-char invite code
    const inviteCode = Math.random().toString(36).substring(2, 8).toUpperCase();

    // Store invitation
    const { data: invitation, error } = await db
      .from('employee_invitations')
      .insert({
        company_id: companyId,
        phone: data.phone,
        name: data.name,
        role: data.role || 'employee',
        department_id: data.department_id || null,
        branch_id: data.branch_id || null,
        position_id: data.position_id || null,
        invite_code: inviteCode,
        status: 'pending',
        expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(), // 7 days
      })
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);

    return {
      message: `Invitation sent! Share code: ${inviteCode}`,
      message_mm: `ဖိတ်ကြားချက် ပို့ပြီးပါပြီ! ကုဒ်: ${inviteCode}`,
      invitation,
      invite_code: inviteCode,
      company_name: company.name,
    };
  }

  // ============================================
  // List Pending Invitations
  // ============================================
  async listInvitations(companyId: string) {
    const db = this.supabaseService.getClient();

    const { data, error } = await db
      .from('employee_invitations')
      .select('*')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw error;
    return data || [];
  }
}
