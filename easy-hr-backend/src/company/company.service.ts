// src/company/company.service.ts
import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class CompanyService {
  constructor(private supabaseService: SupabaseService) {}

  // Get company profile
  async getCompanyProfile(companyId: string) {
    const db = this.supabaseService.getClient();

    const { data: company, error } = await db
      .from('companies')
      .select('*')
      .eq('id', companyId)
      .single();

    if (error || !company) throw new NotFoundException('Company not found');

    // Get stats
    const { count: employeeCount } = await db
      .from('employees')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('is_active', true);

    const { count: branchCount } = await db
      .from('branches')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('is_active', true);

    const { count: departmentCount } = await db
      .from('departments')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('is_active', true);

    return {
      ...company,
      stats: {
        total_employees: employeeCount || 0,
        total_branches: branchCount || 0,
        total_departments: departmentCount || 0,
      },
    };
  }

  // Update company profile
  async updateCompanyProfile(companyId: string, data: any) {
    return this.supabaseService.update('companies', companyId, data);
  }

  // Update working hours
  async updateWorkingHours(companyId: string, data: {
    work_start_time: string;
    work_end_time: string;
    working_days: number[];
    checkin_reminder_minutes?: number;
  }) {
    return this.supabaseService.update('companies', companyId, data);
  }

  // Get company dashboard stats
  async getDashboardStats(companyId: string) {
    const db = this.supabaseService.getClient();
    const today = new Date().toISOString().split('T')[0];

    // Today's attendance
    const { data: todayAttendance } = await db
      .from('attendance')
      .select('status')
      .eq('company_id', companyId)
      .eq('date', today);

    const present = todayAttendance?.filter(a => a.status === 'present').length || 0;
    const late = todayAttendance?.filter(a => a.status === 'late').length || 0;
    const absent = todayAttendance?.filter(a => a.status === 'absent').length || 0;
    const onLeave = todayAttendance?.filter(a => a.status === 'on_leave').length || 0;

    // Total employees
    const { count: totalEmployees } = await db
      .from('employees')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('is_active', true);

    // Pending leave requests
    const { count: pendingLeaves } = await db
      .from('leave_requests')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('status', 'pending');

    return {
      today: today,
      total_employees: totalEmployees || 0,
      attendance: {
        present,
        late,
        absent,
        on_leave: onLeave,
        not_checked_in: (totalEmployees || 0) - present - late - absent - onLeave,
      },
      pending_leave_requests: pendingLeaves || 0,
    };
  }
}
