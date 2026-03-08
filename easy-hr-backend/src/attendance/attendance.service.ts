import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class AttendanceService {
  constructor(private supabaseService: SupabaseService) {}

  // ============================================
  // GPS CHECK-IN
  // ============================================
  async checkIn(employeeId: string, companyId: string, data: {
    latitude: number;
    longitude: number;
    device_id?: string;
  }) {
    const db = this.supabaseService.getClient();
    const today = new Date().toISOString().split('T')[0];

    // 1. Check if already checked in today
    const { data: existing } = await db
      .from('attendance')
      .select('id, check_in_time')
      .eq('employee_id', employeeId)
      .eq('date', today)
      .single();

    if (existing?.check_in_time) {
      throw new BadRequestException('Already checked in today at ' + new Date(existing.check_in_time).toLocaleTimeString());
    }

    // 2. Get employee's branch GPS settings
    const { data: employee } = await db
      .from('employees')
      .select('branch_id')
      .eq('id', employeeId)
      .single();

    if (!employee?.branch_id) {
      throw new BadRequestException('No branch assigned. Contact your HR.');
    }

    const { data: branch } = await db
      .from('branches')
      .select('latitude, longitude, radius_meters, name')
      .eq('id', employee.branch_id)
      .single();

    if (!branch?.latitude || !branch?.longitude) {
      throw new BadRequestException('Branch GPS not configured. Contact your admin.');
    }

    // 3. Calculate distance between employee and branch
    const distance = this.calculateDistance(
      data.latitude, data.longitude,
      Number(branch.latitude), Number(branch.longitude)
    );

    if (distance > branch.radius_meters) {
      throw new BadRequestException(
        `You are ${Math.round(distance)}m away from ${branch.name}. ` +
        `You need to be within ${branch.radius_meters}m to check in.`
      );
    }

    // 4. Check if late
    const { data: company } = await db
      .from('companies')
      .select('work_start_time')
      .eq('id', companyId)
      .single();

    const now = new Date();
    const [startHour, startMin] = (company?.work_start_time || '09:00:00').split(':').map(Number);
    const workStart = new Date(now);
    workStart.setHours(startHour, startMin, 0, 0);

    const isLate = now > workStart;
    const lateMinutes = isLate ? Math.floor((now.getTime() - workStart.getTime()) / 60000) : 0;

    // 5. Create or update attendance record
    const attendanceData = {
      employee_id: employeeId,
      company_id: companyId,
      branch_id: employee.branch_id,
      date: today,
      check_in_time: now.toISOString(),
      check_in_latitude: data.latitude,
      check_in_longitude: data.longitude,
      check_in_method: 'gps',
      status: isLate ? 'late' : 'present',
      is_late: isLate,
      late_minutes: lateMinutes,
      is_mock_location: false,
      device_id: data.device_id || null,
    };

    let result;
    if (existing) {
      // Update existing record (was marked absent, now checking in)
      const { data: updated, error } = await db
        .from('attendance')
        .update(attendanceData)
        .eq('id', existing.id)
        .select()
        .single();
      if (error) throw error;
      result = updated;
    } else {
      const { data: created, error } = await db
        .from('attendance')
        .insert(attendanceData)
        .select()
        .single();
      if (error) throw error;
      result = created;
    }

    return {
      message: isLate
        ? `Checked in (${lateMinutes} minutes late)`
        : 'Checked in successfully! Have a great day!',
      attendance: result,
      distance_meters: Math.round(distance),
      is_late: isLate,
      late_minutes: lateMinutes,
    };
  }

  // ============================================
  // GPS CHECK-OUT
  // ============================================
  async checkOut(employeeId: string, companyId: string, data: {
    latitude: number;
    longitude: number;
  }) {
    const db = this.supabaseService.getClient();
    const today = new Date().toISOString().split('T')[0];

    // 1. Find today's check-in
    const { data: attendance } = await db
      .from('attendance')
      .select('*')
      .eq('employee_id', employeeId)
      .eq('date', today)
      .single();

    if (!attendance?.check_in_time) {
      throw new BadRequestException('You have not checked in today');
    }

    if (attendance.check_out_time) {
      throw new BadRequestException('Already checked out today');
    }

    // 2. Calculate total hours and OT
    const now = new Date();
    const checkIn = new Date(attendance.check_in_time);
    const totalHours = (now.getTime() - checkIn.getTime()) / (1000 * 60 * 60);

    // Get company working hours for OT calculation
    const { data: company } = await db
      .from('companies')
      .select('work_start_time, work_end_time')
      .eq('id', companyId)
      .single();

    const [endHour, endMin] = (company?.work_end_time || '17:00:00').split(':').map(Number);
    const workEnd = new Date(now);
    workEnd.setHours(endHour, endMin, 0, 0);

    const overtimeHours = now > workEnd
      ? (now.getTime() - workEnd.getTime()) / (1000 * 60 * 60)
      : 0;

    // Check early leave
    const isEarlyLeave = now < workEnd;

    // 3. Update attendance
    const { data: updated, error } = await db
      .from('attendance')
      .update({
        check_out_time: now.toISOString(),
        check_out_latitude: data.latitude,
        check_out_longitude: data.longitude,
        check_out_method: 'gps',
        total_hours: Math.round(totalHours * 100) / 100,
        overtime_hours: Math.round(overtimeHours * 100) / 100,
        is_early_leave: isEarlyLeave,
      })
      .eq('id', attendance.id)
      .select()
      .single();

    if (error) throw error;

    return {
      message: 'Checked out successfully! Good job today!',
      attendance: updated,
      total_hours: Math.round(totalHours * 100) / 100,
      overtime_hours: Math.round(overtimeHours * 100) / 100,
      is_early_leave: isEarlyLeave,
    };
  }

  // ============================================
  // QR CODE CHECK-IN
  // ============================================
  async qrCheckIn(employeeId: string, companyId: string, data: {
    qr_code: string;
    latitude?: number;
    longitude?: number;
    device_id?: string;
  }) {
    const db = this.supabaseService.getClient();

    // 1. Validate QR code against branch
    const { data: branch } = await db
      .from('branches')
      .select('*')
      .eq('company_id', companyId)
      .eq('qr_secret_key', data.qr_code)
      .eq('qr_code_enabled', true)
      .single();

    if (!branch) {
      throw new BadRequestException('Invalid or expired QR code');
    }

    // 2. Proceed with check-in using branch location
    return this.checkIn(employeeId, companyId, {
      latitude: data.latitude || Number(branch.latitude),
      longitude: data.longitude || Number(branch.longitude),
      device_id: data.device_id,
    });
  }

  // ============================================
  // CHECK STATUS (for app - is button active?)
  // ============================================
  async getMyTodayStatus(employeeId: string, companyId: string, latitude?: number, longitude?: number) {
    const db = this.supabaseService.getClient();
    const today = new Date().toISOString().split('T')[0];

    // Get today's attendance
    const { data: attendance } = await db
      .from('attendance')
      .select('*')
      .eq('employee_id', employeeId)
      .eq('date', today)
      .single();

    // Get branch GPS
    const { data: employee } = await db
      .from('employees')
      .select('branch_id')
      .eq('id', employeeId)
      .single();

    let isWithinRadius = false;
    let distanceMeters = 0;

    if (employee?.branch_id && latitude && longitude) {
      const { data: branch } = await db
        .from('branches')
        .select('latitude, longitude, radius_meters')
        .eq('id', employee.branch_id)
        .single();

      if (branch?.latitude && branch?.longitude) {
        distanceMeters = this.calculateDistance(
          latitude, longitude,
          Number(branch.latitude), Number(branch.longitude)
        );
        isWithinRadius = distanceMeters <= branch.radius_meters;
      }
    }

    return {
      date: today,
      checked_in: !!attendance?.check_in_time,
      checked_out: !!attendance?.check_out_time,
      check_in_time: attendance?.check_in_time || null,
      check_out_time: attendance?.check_out_time || null,
      status: attendance?.status || 'not_checked_in',
      total_hours: attendance?.total_hours || 0,
      is_within_radius: isWithinRadius,
      distance_meters: Math.round(distanceMeters),
      can_check_in: !attendance?.check_in_time && isWithinRadius,
      can_check_out: !!attendance?.check_in_time && !attendance?.check_out_time,
    };
  }

  // ============================================
  // ATTENDANCE HISTORY (Employee)
  // ============================================
  async getMyAttendanceHistory(employeeId: string, filters: {
    month?: number;
    year?: number;
    page?: number;
    limit?: number;
  }) {
    const db = this.supabaseService.getClient();
    const year = filters.year || new Date().getFullYear();
    const month = filters.month || new Date().getMonth() + 1;
    const page = filters.page || 1;
    const limit = filters.limit || 31;
    const offset = (page - 1) * limit;

    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const endDate = `${year}-${String(month).padStart(2, '0')}-31`;

    const { data, count, error } = await db
      .from('attendance')
      .select('*', { count: 'exact' })
      .eq('employee_id', employeeId)
      .gte('date', startDate)
      .lte('date', endDate)
      .order('date', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    // Summary
    const present = data?.filter(a => a.status === 'present').length || 0;
    const late = data?.filter(a => a.status === 'late').length || 0;
    const absent = data?.filter(a => a.status === 'absent').length || 0;
    const onLeave = data?.filter(a => a.status === 'on_leave').length || 0;
    const totalHours = data?.reduce((sum, a) => sum + (a.total_hours || 0), 0) || 0;
    const totalOT = data?.reduce((sum, a) => sum + (a.overtime_hours || 0), 0) || 0;

    return {
      records: data,
      summary: {
        year, month,
        present, late, absent, on_leave: onLeave,
        total_working_hours: Math.round(totalHours * 100) / 100,
        total_overtime_hours: Math.round(totalOT * 100) / 100,
      },
      pagination: { total: count, page, limit },
    };
  }

  // ============================================
  // DAILY REPORT (Owner/HR)
  // ============================================
  async getDailyReport(companyId: string, date?: string, departmentId?: string) {
    const db = this.supabaseService.getClient();
    const targetDate = date || new Date().toISOString().split('T')[0];

    let query = db
      .from('attendance')
      .select(`
        *,
        employee:employee_id(id, first_name, last_name, name_mm, employee_code, department_id, profile_photo_url,
          department:department_id(id, name),
          position:position_id(id, title)
        )
      `)
      .eq('company_id', companyId)
      .eq('date', targetDate)
      .order('check_in_time', { ascending: true });

    const { data, error } = await query;
    if (error) throw error;

    // Filter by department if specified
    let records = data || [];
    if (departmentId) {
      records = records.filter(r => r.employee?.department_id === departmentId);
    }

    // Get total employees for absent calculation
    let empQuery = db
      .from('employees')
      .select('id, first_name, last_name, employee_code, department_id', { count: 'exact' })
      .eq('company_id', companyId)
      .eq('is_active', true);
    if (departmentId) empQuery = empQuery.eq('department_id', departmentId);

    const { data: allEmployees, count: totalEmployees } = await empQuery;

    // Find who hasn't checked in
    const checkedInIds = records.map(r => r.employee_id);
    const notCheckedIn = allEmployees?.filter(e => !checkedInIds.includes(e.id)) || [];

    const present = records.filter(a => a.status === 'present').length;
    const late = records.filter(a => a.status === 'late').length;
    const onLeave = records.filter(a => a.status === 'on_leave').length;

    return {
      date: targetDate,
      summary: {
        total_employees: totalEmployees || 0,
        present,
        late,
        absent: notCheckedIn.length,
        on_leave: onLeave,
        checked_in: present + late,
      },
      records,
      not_checked_in: notCheckedIn,
    };
  }

  // ============================================
  // MONTHLY REPORT (Owner/HR)
  // ============================================
  async getMonthlyReport(companyId: string, year: number, month: number, departmentId?: string) {
    const db = this.supabaseService.getClient();

    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const endDate = `${year}-${String(month).padStart(2, '0')}-31`;

    let query = db
      .from('attendance')
      .select(`
        *,
        employee:employee_id(id, first_name, last_name, employee_code, department_id)
      `)
      .eq('company_id', companyId)
      .gte('date', startDate)
      .lte('date', endDate)
      .order('date');

    const { data, error } = await query;
    if (error) throw error;

    let records = data || [];
    if (departmentId) {
      records = records.filter(r => r.employee?.department_id === departmentId);
    }

    // Group by employee
    const employeeMap = {};
    records.forEach(record => {
      const empId = record.employee_id;
      if (!employeeMap[empId]) {
        employeeMap[empId] = {
          employee: record.employee,
          present: 0, late: 0, absent: 0, on_leave: 0,
          total_hours: 0, overtime_hours: 0, records: [],
        };
      }
      const emp = employeeMap[empId];
      if (record.status === 'present') emp.present++;
      if (record.status === 'late') emp.late++;
      if (record.status === 'absent') emp.absent++;
      if (record.status === 'on_leave') emp.on_leave++;
      emp.total_hours += record.total_hours || 0;
      emp.overtime_hours += record.overtime_hours || 0;
      emp.records.push(record);
    });

    return {
      year, month,
      employee_reports: Object.values(employeeMap),
    };
  }

  // ============================================
  // HELPER: Calculate distance between two GPS points (Haversine)
  // ============================================
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371000; // Earth's radius in meters
    const dLat = this.toRad(lat2 - lat1);
    const dLon = this.toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) * Math.cos(this.toRad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRad(deg: number): number {
    return deg * (Math.PI / 180);
  }
}
