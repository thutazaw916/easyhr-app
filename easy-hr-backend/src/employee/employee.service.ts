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
    contract_type?: string;
    gender?: string;
  }) {
    const db = this.supabaseService.getClient();

    // Check phone uniqueness within company
    const { data: existing } = await db
      .from('employees')
      .select('id')
      .eq('company_id', companyId)
      .eq('phone', data.phone)
      .single();

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

    // Create employee
    const employee = await this.supabaseService.create('employees', {
      company_id: companyId,
      ...data,
      role: data.role || 'employee',
      is_active: true,
    });

    // If role is hr_manager, also create auth_credentials
    // HR will set their own password via a separate endpoint

    return {
      message: 'Employee added successfully',
      employee,
    };
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
}
