import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { NotificationService } from '../notification/notification.service';

@Injectable()
export class LeaveService {
  constructor(
    private supabaseService: SupabaseService,
    private notificationService: NotificationService,
  ) {}

  // ============================================
  // GET LEAVE TYPES (Company's configured leave types)
  // ============================================
  async getLeaveTypes(companyId: string) {
    return this.supabaseService.findAll('leave_types', { company_id: companyId, is_active: true });
  }

  // ============================================
  // UPDATE LEAVE TYPE (Owner can customize)
  // ============================================
  async updateLeaveType(companyId: string, leaveTypeId: string, data: any) {
    const existing = await this.supabaseService.findOneBy('leave_types', { id: leaveTypeId, company_id: companyId });
    if (!existing) throw new NotFoundException('Leave type not found');
    return this.supabaseService.update('leave_types', leaveTypeId, data);
  }

  // ============================================
  // CREATE CUSTOM LEAVE TYPE
  // ============================================
  async createLeaveType(companyId: string, data: any) {
    return this.supabaseService.create('leave_types', { company_id: companyId, ...data });
  }

  // ============================================
  // GET MY LEAVE BALANCES (Employee)
  // ============================================
  async getMyLeaveBalances(employeeId: string) {
    const db = this.supabaseService.getClient();
    const year = new Date().getFullYear();

    const { data, error } = await db
      .from('leave_balances')
      .select(`
        *,
        leave_type:leave_type_id(id, name, name_mm, code, is_paid)
      `)
      .eq('employee_id', employeeId)
      .eq('year', year);

    if (error) throw error;

    return data?.map(b => ({
      ...b,
      available_days: b.total_days - b.used_days - b.pending_days,
    }));
  }

  // ============================================
  // REQUEST LEAVE (Employee)
  // ============================================
  async requestLeave(employeeId: string, companyId: string, data: {
    leave_type_id: string;
    start_date: string;
    end_date: string;
    reason?: string;
    is_half_day?: boolean;
    half_day_period?: string;
    attachment_url?: string;
  }) {
    const db = this.supabaseService.getClient();

    // 1. Validate leave type
    const { data: leaveType } = await db
      .from('leave_types')
      .select('*')
      .eq('id', data.leave_type_id)
      .eq('company_id', companyId)
      .single();

    if (!leaveType) throw new NotFoundException('Leave type not found');

    // 2. Calculate total days
    const start = new Date(data.start_date);
    const end = new Date(data.end_date);
    let totalDays = data.is_half_day ? 0.5 : Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)) + 1;

    // 3. Check balance
    const year = start.getFullYear();
    const { data: balance } = await db
      .from('leave_balances')
      .select('*')
      .eq('employee_id', employeeId)
      .eq('leave_type_id', data.leave_type_id)
      .eq('year', year)
      .single();

    if (!balance) throw new BadRequestException('No leave balance found for this type');

    const available = balance.total_days - balance.used_days - balance.pending_days;
    if (totalDays > available) {
      throw new BadRequestException(`Insufficient leave balance. Available: ${available} days, Requested: ${totalDays} days`);
    }

    // 4. Check for overlapping requests
    // Overlap = existing.start_date <= requested.end_date AND existing.end_date >= requested.start_date
    const { data: overlapping } = await db
      .from('leave_requests')
      .select('id')
      .eq('employee_id', employeeId)
      .in('status', ['pending', 'approved'])
      .lte('start_date', data.end_date)
      .gte('end_date', data.start_date);

    if (overlapping && overlapping.length > 0) {
      throw new BadRequestException('You already have a leave request for overlapping dates');
    }

    // 5. Create request
    const insertData: Record<string, any> = {
      employee_id: employeeId,
      company_id: companyId,
      leave_type_id: data.leave_type_id,
      start_date: data.start_date,
      end_date: data.end_date,
      total_days: totalDays,
      reason: data.reason,
      is_half_day: data.is_half_day || false,
      half_day_period: data.half_day_period,
      status: 'pending',
    };
    if (data.attachment_url) insertData.attachment_url = data.attachment_url;

    const { data: request, error } = await db
      .from('leave_requests')
      .insert(insertData)
      .select()
      .single();

    if (error) throw error;

    // 6. Update pending days in balance
    await db
      .from('leave_balances')
      .update({ pending_days: balance.pending_days + totalDays })
      .eq('id', balance.id);

    // 7. Notify admins
    try {
      const { data: employee } = await db
        .from('employees')
        .select('first_name, last_name, employee_code')
        .eq('id', employeeId)
        .single();
      const empName = `${employee?.first_name || ''} ${employee?.last_name || ''}`.trim();
      const typeName = leaveType?.name || '';
      const typeNameMm = leaveType?.name_mm || typeName;

      await this.notificationService.notifyAdmins(companyId, {
        sender_id: employeeId,
        type: 'leave_request',
        title: `New Leave Request from ${empName}`,
        title_mm: `${empName} မှ ခွင့်တောင်းဆိုမှု အသစ်`,
        body: `${typeName}: ${data.start_date} to ${data.end_date} (${totalDays} day${totalDays > 1 ? 's' : ''})`,
        body_mm: `${typeNameMm}: ${data.start_date} မှ ${data.end_date} (${totalDays} ရက်)`,
        data: { leave_request_id: request.id, leave_type: typeName },
      });
    } catch (e) {
      console.error('Failed to send leave notification:', e);
    }

    return {
      message: 'Leave request submitted successfully',
      request,
    };
  }

  // ============================================
  // APPROVE / REJECT LEAVE (Owner/HR)
  // ============================================
  async updateLeaveStatus(companyId: string, requestId: string, approverId: string, data: {
    status: 'approved' | 'rejected';
    rejection_reason?: string;
  }) {
    const db = this.supabaseService.getClient();

    // 1. Find request (first without company filter to debug)
    const { data: anyRequest } = await db
      .from('leave_requests')
      .select('*')
      .eq('id', requestId)
      .single();

    if (!anyRequest) throw new NotFoundException('Leave request not found');
    if (anyRequest.company_id !== companyId) {
      throw new NotFoundException(`Leave request belongs to a different company`);
    }
    if (anyRequest.status !== 'pending') {
      throw new BadRequestException(`Leave request already ${anyRequest.status}`);
    }

    const request = anyRequest;

    // 2. Update request status
    const { data: updated, error } = await db
      .from('leave_requests')
      .update({
        status: data.status,
        approved_by: approverId,
        approved_at: new Date().toISOString(),
        rejection_reason: data.rejection_reason,
      })
      .eq('id', requestId)
      .select()
      .single();

    if (error) throw error;

    // 3. Update leave balance
    const year = new Date(request.start_date).getFullYear();
    const { data: balance } = await db
      .from('leave_balances')
      .select('*')
      .eq('employee_id', request.employee_id)
      .eq('leave_type_id', request.leave_type_id)
      .eq('year', year)
      .single();

    if (balance) {
      if (data.status === 'approved') {
        await db.from('leave_balances').update({
          pending_days: Math.max(0, balance.pending_days - request.total_days),
          used_days: balance.used_days + request.total_days,
        }).eq('id', balance.id);
      } else {
        // Rejected - remove from pending
        await db.from('leave_balances').update({
          pending_days: Math.max(0, balance.pending_days - request.total_days),
        }).eq('id', balance.id);
      }
    }

    // 4. Notify employee about approval/rejection
    try {
      const { data: approver } = await db
        .from('employees')
        .select('first_name, last_name')
        .eq('id', approverId)
        .single();
      const approverName = `${approver?.first_name || ''} ${approver?.last_name || ''}`.trim();

      const { data: leaveType } = await db
        .from('leave_types')
        .select('name, name_mm')
        .eq('id', request.leave_type_id)
        .single();
      const typeName = leaveType?.name || '';
      const typeNameMm = leaveType?.name_mm || typeName;

      const isApproved = data.status === 'approved';
      await this.notificationService.create({
        company_id: companyId,
        employee_id: request.employee_id,
        sender_id: approverId,
        type: isApproved ? 'leave_approved' : 'leave_rejected',
        title: isApproved ? `Leave Approved by ${approverName}` : `Leave Rejected by ${approverName}`,
        title_mm: isApproved ? `${approverName} မှ ခွင့်ခွင့်ပြုပြီး` : `${approverName} မှ ခွင့်ပယ်ချပြီး`,
        body: `${typeName}: ${request.start_date} to ${request.end_date}${data.rejection_reason ? '. Reason: ' + data.rejection_reason : ''}`,
        body_mm: `${typeNameMm}: ${request.start_date} မှ ${request.end_date}${data.rejection_reason ? '. အကြောင်းပြချက်: ' + data.rejection_reason : ''}`,
        data: { leave_request_id: requestId, status: data.status },
      });
    } catch (e) {
      console.error('Failed to notify employee:', e);
    }

    return {
      message: `Leave request ${data.status}`,
      request: updated,
    };
  }

  // ============================================
  // GET MY LEAVE REQUESTS (Employee)
  // ============================================
  async getMyLeaveRequests(employeeId: string, status?: string) {
    const db = this.supabaseService.getClient();

    let query = db
      .from('leave_requests')
      .select(`
        *,
        leave_type:leave_type_id(id, name, name_mm, code),
        approver:approved_by(id, first_name, last_name)
      `)
      .eq('employee_id', employeeId)
      .order('created_at', { ascending: false });

    if (status) query = query.eq('status', status);

    const { data, error } = await query;
    if (error) throw error;
    return data;
  }

  // ============================================
  // GET PENDING REQUESTS (Owner/HR)
  // ============================================
  async getPendingRequests(companyId: string, departmentId?: string) {
    const db = this.supabaseService.getClient();

    let query = db
      .from('leave_requests')
      .select(`
        *,
        leave_type:leave_type_id(id, name, name_mm, code),
        employee:employee_id(id, first_name, last_name, name_mm, employee_code, profile_photo_url,
          department:department_id(id, name),
          position:position_id(id, title)
        )
      `)
      .eq('company_id', companyId)
      .eq('status', 'pending')
      .order('created_at', { ascending: true });

    const { data, error } = await query;
    if (error) throw error;

    let results = data || [];
    if (departmentId) {
      results = results.filter(r => r.employee?.department_id === departmentId);
    }

    return results;
  }

  // ============================================
  // LEAVE CALENDAR (Team view)
  // ============================================
  async getLeaveCalendar(companyId: string, year: number, month: number) {
    const db = this.supabaseService.getClient();

    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const endDate = `${year}-${String(month).padStart(2, '0')}-31`;

    const { data, error } = await db
      .from('leave_requests')
      .select(`
        id, start_date, end_date, total_days, status, is_half_day,
        leave_type:leave_type_id(name, code),
        employee:employee_id(id, first_name, last_name, employee_code)
      `)
      .eq('company_id', companyId)
      .in('status', ['approved', 'pending'])
      .gte('start_date', startDate)
      .lte('end_date', endDate)
      .order('start_date');

    if (error) throw error;
    return data;
  }
}
