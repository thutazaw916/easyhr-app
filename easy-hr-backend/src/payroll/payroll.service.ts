import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class PayrollService {
  constructor(private supabaseService: SupabaseService) {}

  // ============================================
  // SALARY STRUCTURE CRUD
  // ============================================

  // Set/Update employee salary structure
  async setSalaryStructure(companyId: string, employeeId: string, data: {
    basic_salary: number;
    transport_allowance?: number;
    meal_allowance?: number;
    phone_allowance?: number;
    housing_allowance?: number;
    other_allowance?: number;
    other_allowance_name?: string;
    ot_rate_per_hour?: number;
    attendance_bonus?: number;
    ssb_employee_percent?: number;
  }) {
    const db = this.supabaseService.getClient();

    // Verify employee belongs to company
    const { data: employee } = await db
      .from('employees')
      .select('id')
      .eq('id', employeeId)
      .eq('company_id', companyId)
      .single();

    if (!employee) throw new NotFoundException('Employee not found');

    // Deactivate old salary structure
    await db
      .from('salary_structures')
      .update({ is_current: false })
      .eq('employee_id', employeeId)
      .eq('is_current', true);

    // Create new salary structure
    const { data: structure, error } = await db
      .from('salary_structures')
      .insert({
        employee_id: employeeId,
        company_id: companyId,
        basic_salary: data.basic_salary,
        transport_allowance: data.transport_allowance || 0,
        meal_allowance: data.meal_allowance || 0,
        phone_allowance: data.phone_allowance || 0,
        housing_allowance: data.housing_allowance || 0,
        other_allowance: data.other_allowance || 0,
        other_allowance_name: data.other_allowance_name,
        ot_rate_per_hour: data.ot_rate_per_hour || 0,
        attendance_bonus: data.attendance_bonus || 0,
        ssb_employee_percent: data.ssb_employee_percent || 2.0,
        effective_date: new Date().toISOString().split('T')[0],
        is_current: true,
      })
      .select()
      .single();

    if (error) throw error;

    return {
      message: 'Salary structure updated',
      salary_structure: structure,
    };
  }

  // Get employee's current salary structure
  async getSalaryStructure(companyId: string, employeeId: string) {
    const db = this.supabaseService.getClient();

    const { data, error } = await db
      .from('salary_structures')
      .select('*')
      .eq('employee_id', employeeId)
      .eq('company_id', companyId)
      .eq('is_current', true)
      .single();

    if (error && error.code !== 'PGRST116') throw error;
    return data;
  }

  // Get all employees salary structures
  async getAllSalaryStructures(companyId: string) {
    const db = this.supabaseService.getClient();

    const { data, error } = await db
      .from('salary_structures')
      .select(`
        *,
        employee:employee_id(id, first_name, last_name, name_mm, employee_code,
          department:department_id(name),
          position:position_id(title)
        )
      `)
      .eq('company_id', companyId)
      .eq('is_current', true)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data;
  }

  // ============================================
  // SALARY ADVANCE (ကြိုတင်ထုတ်ငွေ)
  // ============================================

  async requestAdvance(employeeId: string, companyId: string, data: {
    amount: number;
    reason?: string;
    installment_months?: number;
  }) {
    const db = this.supabaseService.getClient();

    const monthlyDeduction = data.installment_months
      ? Math.ceil(data.amount / data.installment_months)
      : data.amount;

    const { data: advance, error } = await db
      .from('salary_advances')
      .insert({
        employee_id: employeeId,
        company_id: companyId,
        amount: data.amount,
        reason: data.reason,
        installment_months: data.installment_months || 1,
        monthly_deduction: monthlyDeduction,
        remaining_amount: data.amount,
        status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;
    return { message: 'Advance request submitted', advance };
  }

  async approveAdvance(companyId: string, advanceId: string, approverId: string, approve: boolean) {
    const db = this.supabaseService.getClient();

    const { data, error } = await db
      .from('salary_advances')
      .update({
        status: approve ? 'approved' : 'rejected',
        approved_by: approverId,
        approved_at: new Date().toISOString(),
      })
      .eq('id', advanceId)
      .eq('company_id', companyId)
      .eq('status', 'pending')
      .select()
      .single();

    if (error) throw new NotFoundException('Advance request not found');
    return data;
  }

  async getAdvances(companyId: string, employeeId?: string) {
    const db = this.supabaseService.getClient();

    let query = db
      .from('salary_advances')
      .select(`
        *,
        employee:employee_id(id, first_name, last_name, employee_code)
      `)
      .eq('company_id', companyId)
      .order('created_at', { ascending: false });

    if (employeeId) query = query.eq('employee_id', employeeId);

    const { data, error } = await query;
    if (error) throw error;
    return data;
  }

  // ============================================
  // ONE-CLICK SALARY CALCULATION 🔥
  // ============================================

  async calculateMonthlySalary(companyId: string, year: number, month: number) {
    const db = this.supabaseService.getClient();

    // 1. Get all active employees with salary structures
    const { data: structures } = await db
      .from('salary_structures')
      .select(`
        *,
        employee:employee_id(id, first_name, last_name, employee_code, department_id, is_active)
      `)
      .eq('company_id', companyId)
      .eq('is_current', true);

    if (!structures || structures.length === 0) {
      return {
        message: 'No salary structures configured. Please set up salary for employees first.',
        month,
        year,
        total_working_days: 0,
        results: [],
      };
    }

    const results = [];
    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const endDate = `${year}-${String(month).padStart(2, '0')}-31`;

    // Calculate working days in month (exclude weekends)
    let companyWorkingDays = [1, 2, 3, 4, 5]; // Mon-Fri default
    try {
      const { data: company } = await db
        .from('companies')
        .select('working_days')
        .eq('id', companyId)
        .single();
      if (company?.working_days) companyWorkingDays = company.working_days;
    } catch (e) {
      // working_days column may not exist, use default
    }

    const workingDays = this.getWorkingDaysInMonth(year, month, companyWorkingDays);

    // Get public holidays
    let holidayCount = 0;
    try {
      const { data: holidays } = await db
        .from('public_holidays')
        .select('date')
        .eq('company_id', companyId)
        .gte('date', startDate)
        .lte('date', endDate);
      holidayCount = holidays?.length || 0;
    } catch (e) {
      // public_holidays table may not exist
    }

    const totalWorkingDays = Math.max(1, workingDays - holidayCount);

    for (const structure of structures) {
      if (!structure.employee?.is_active) continue;

      const empId = structure.employee_id;

      // 2. Get attendance data for this month
      const { data: attendance } = await db
        .from('attendance')
        .select('*')
        .eq('employee_id', empId)
        .gte('date', startDate)
        .lte('date', endDate);

      const attendanceRecords = attendance?.length || 0;
      const daysPresent = attendance?.filter(a => a.status === 'present' || a.status === 'late').length || 0;
      const daysLate = attendance?.filter(a => a.status === 'late').length || 0;
      // If no attendance records exist, assume full attendance (no deduction)
      const daysAbsent = attendanceRecords > 0 ? Math.max(0, totalWorkingDays - daysPresent) : 0;
      const totalOTHours = attendance?.reduce((sum, a) => sum + (a.overtime_hours || 0), 0) || 0;

      // 3. Get leave days
      const { data: leaves } = await db
        .from('leave_requests')
        .select('total_days, leave_type:leave_type_id(is_paid)')
        .eq('employee_id', empId)
        .eq('status', 'approved')
        .gte('start_date', startDate)
        .lte('end_date', endDate);

      const paidLeaveDays = leaves?.filter((l: any) => {
        const lt = Array.isArray(l.leave_type) ? l.leave_type[0] : l.leave_type;
        return lt?.is_paid;
      }).reduce((sum: number, l: any) => sum + l.total_days, 0) || 0;
      const unpaidLeaveDays = leaves?.filter((l: any) => {
        const lt = Array.isArray(l.leave_type) ? l.leave_type[0] : l.leave_type;
        return !lt?.is_paid;
      }).reduce((sum: number, l: any) => sum + l.total_days, 0) || 0;

      // 4. Calculate earnings
      const basicSalary = Number(structure.basic_salary);
      const dailyRate = basicSalary / totalWorkingDays;

      // Attendance bonus (ရက်မှန်ကြေး) - only if no absent days
      const attendanceBonus = daysAbsent <= 0 ? Number(structure.attendance_bonus) : 0;

      // OT calculation
      const otAmount = totalOTHours * Number(structure.ot_rate_per_hour);

      // Allowances
      const totalAllowances =
        Number(structure.transport_allowance) +
        Number(structure.meal_allowance) +
        Number(structure.phone_allowance) +
        Number(structure.housing_allowance) +
        Number(structure.other_allowance);

      // Deduction for unpaid leave / absent
      const absentDeduction = (daysAbsent > 0 ? daysAbsent : 0) * dailyRate;
      const unpaidLeaveDeduction = unpaidLeaveDays * dailyRate;

      // Gross salary
      const grossSalary = basicSalary + attendanceBonus + otAmount + totalAllowances - absentDeduction - unpaidLeaveDeduction;

      // 5. Calculate deductions
      // SSB (Social Security Board) - 2% employee contribution
      const ssbAmount = grossSalary * (Number(structure.ssb_employee_percent) / 100);

      // Myanmar Income Tax (simplified progressive brackets)
      const taxAmount = this.calculateMyanmarTax(grossSalary * 12) / 12; // Monthly tax

      // Advance deduction
      let advanceDeduction = 0;
      let activeAdvances: any[] = [];
      try {
        const { data } = await db
          .from('salary_advances')
          .select('monthly_deduction, remaining_amount')
          .eq('employee_id', empId)
          .eq('status', 'approved')
          .gt('remaining_amount', 0);
        activeAdvances = data || [];
        advanceDeduction = activeAdvances.reduce((sum, a) => {
          return sum + Math.min(Number(a.monthly_deduction), Number(a.remaining_amount));
        }, 0);
      } catch (e) {
        // salary_advances table may not exist
      }

      const totalDeductions = ssbAmount + taxAmount + advanceDeduction;
      const netSalary = grossSalary - totalDeductions;

      // 6. Save or update payroll record
      const payrollData = {
        employee_id: empId,
        company_id: companyId,
        month,
        year,
        basic_salary: basicSalary,
        attendance_bonus: attendanceBonus,
        ot_hours: totalOTHours,
        ot_amount: Math.round(otAmount),
        bonus: 0,
        total_allowances: totalAllowances,
        gross_salary: Math.round(grossSalary),
        tax_amount: Math.round(taxAmount),
        ssb_amount: Math.round(ssbAmount),
        advance_deduction: Math.round(advanceDeduction),
        other_deductions: 0,
        total_deductions: Math.round(totalDeductions),
        net_salary: Math.round(netSalary),
        total_working_days: totalWorkingDays,
        days_present: daysPresent,
        days_absent: daysAbsent > 0 ? daysAbsent : 0,
        days_late: daysLate,
        days_on_leave: paidLeaveDays + unpaidLeaveDays,
        status: 'calculated',
        calculated_at: new Date().toISOString(),
      };

      // Upsert (update if exists, insert if not)
      const { data: existing } = await db
        .from('payroll')
        .select('id')
        .eq('employee_id', empId)
        .eq('month', month)
        .eq('year', year)
        .single();

      let payroll;
      if (existing) {
        const { data: updated, error } = await db
          .from('payroll')
          .update(payrollData)
          .eq('id', existing.id)
          .select()
          .single();
        if (error) throw error;
        payroll = updated;
      } else {
        const { data: created, error } = await db
          .from('payroll')
          .insert(payrollData)
          .select()
          .single();
        if (error) throw error;
        payroll = created;
      }

      // Update advance remaining amounts
      if (activeAdvances && advanceDeduction > 0) {
        for (const adv of activeAdvances) {
          const deducted = Math.min(Number(adv.monthly_deduction), Number(adv.remaining_amount));
          const newRemaining = Number(adv.remaining_amount) - deducted;
          await db.from('salary_advances').update({
            remaining_amount: newRemaining,
            status: newRemaining <= 0 ? 'completed' : 'approved',
          }).eq('employee_id', empId).eq('status', 'approved').gt('remaining_amount', 0);
        }
      }

      results.push({
        employee: structure.employee,
        payroll,
      });
    }

    return {
      message: `Salary calculated for ${results.length} employees`,
      month, year,
      total_working_days: totalWorkingDays,
      results,
    };
  }

  // ============================================
  // GET PAYROLL LIST (for a month)
  // ============================================
  async getMonthlyPayroll(companyId: string, year: number, month: number) {
    const db = this.supabaseService.getClient();

    const { data, error } = await db
      .from('payroll')
      .select(`
        *,
        employee:employee_id(id, first_name, last_name, name_mm, employee_code,
          department:department_id(name),
          position:position_id(title),
          bank_name, bank_account_number
        )
      `)
      .eq('company_id', companyId)
      .eq('year', year)
      .eq('month', month)
      .order('created_at');

    if (error) {
      return this.emptyMonthlyPayrollResponse(year, month);
    }

    // Summary totals
    const totalGross = data?.reduce((sum, p) => sum + Number(p.gross_salary), 0) || 0;
    const totalDeductions = data?.reduce((sum, p) => sum + Number(p.total_deductions), 0) || 0;
    const totalNet = data?.reduce((sum, p) => sum + Number(p.net_salary), 0) || 0;
    const totalOT = data?.reduce((sum, p) => sum + Number(p.ot_amount), 0) || 0;
    const totalBonus = data?.reduce((sum, p) => sum + Number(p.bonus), 0) || 0;
    const totalBasic = data?.reduce((sum, p) => sum + Number(p.basic_salary), 0) || 0;
    const totalAllowances = data?.reduce((sum, p) => sum + Number(p.total_allowances), 0) || 0;
    const totalSSB = data?.reduce((sum, p) => sum + Number(p.ssb_amount), 0) || 0;
    const totalTax = data?.reduce((sum, p) => sum + Number(p.tax_amount), 0) || 0;

    return {
      year, month,
      employee_count: data?.length || 0,
      payrolls: data ?? [],
      summary: {
        total_basic: totalBasic,
        total_allowances: totalAllowances,
        total_ot: totalOT,
        total_bonus: totalBonus,
        total_gross: totalGross,
        total_ssb: totalSSB,
        total_tax: totalTax,
        total_deductions: totalDeductions,
        total_net: totalNet,
      },
      // For pie chart
      chart_data: {
        labels: ['Basic Salary', 'Allowances', 'OT', 'Bonus', 'SSB', 'Tax', 'Other Deductions'],
        values: [totalBasic, totalAllowances, totalOT, totalBonus, totalSSB, totalTax, totalDeductions - totalSSB - totalTax],
      },
    };
  }

  private emptyMonthlyPayrollResponse(year: number, month: number) {
    return {
      year,
      month,
      employee_count: 0,
      payrolls: [],
      summary: {
        total_basic: 0,
        total_allowances: 0,
        total_ot: 0,
        total_bonus: 0,
        total_gross: 0,
        total_ssb: 0,
        total_tax: 0,
        total_deductions: 0,
        total_net: 0,
      },
      chart_data: {
        labels: ['Basic Salary', 'Allowances', 'OT', 'Bonus', 'SSB', 'Tax', 'Other Deductions'],
        values: [0, 0, 0, 0, 0, 0, 0],
      },
    };
  }

  // ============================================
  // GET MY PAYSLIP (Employee)
  // ============================================
  async getMyPayslip(employeeId: string, year: number, month: number) {
    const db = this.supabaseService.getClient();

    const { data, error } = await db
      .from('payroll')
      .select(`
        *,
        employee:employee_id(
          id, first_name, last_name, name_mm, employee_code, phone, email,
          bank_name, bank_account_number, ssb_number, nrc_number,
          department:department_id(name),
          position:position_id(title),
          company:company_id(name, name_mm, address, phone, email, logo_url)
        )
      `)
      .eq('employee_id', employeeId)
      .eq('year', year)
      .eq('month', month)
      .single();

    if (error && error.code !== 'PGRST116') throw error;
    if (!data) throw new NotFoundException('Payslip not found for this month');

    return data;
  }

  // ============================================
  // ADD BONUS / ADJUST PAYROLL
  // ============================================
  async adjustPayroll(companyId: string, payrollId: string, data: {
    bonus?: number;
    bonus_description?: string;
    other_earnings?: number;
    other_earnings_description?: string;
    other_deductions?: number;
    other_deductions_description?: string;
  }) {
    const db = this.supabaseService.getClient();

    // Get existing payroll
    const { data: payroll } = await db
      .from('payroll')
      .select('*')
      .eq('id', payrollId)
      .eq('company_id', companyId)
      .single();

    if (!payroll) throw new NotFoundException('Payroll record not found');

    // Recalculate
    const bonus = data.bonus || Number(payroll.bonus);
    const otherEarnings = data.other_earnings || Number(payroll.other_earnings);
    const otherDeductions = data.other_deductions || Number(payroll.other_deductions);

    const newGross = Number(payroll.basic_salary) + Number(payroll.attendance_bonus) +
      Number(payroll.ot_amount) + bonus + Number(payroll.total_allowances) + otherEarnings;

    const newTotalDeductions = Number(payroll.tax_amount) + Number(payroll.ssb_amount) +
      Number(payroll.advance_deduction) + otherDeductions;

    const netSalary = newGross - newTotalDeductions;

    const { data: updated, error } = await db
      .from('payroll')
      .update({
        bonus: bonus,
        bonus_description: data.bonus_description || payroll.bonus_description,
        other_earnings: otherEarnings,
        other_earnings_description: data.other_earnings_description || payroll.other_earnings_description,
        other_deductions: otherDeductions,
        other_deductions_description: data.other_deductions_description || payroll.other_deductions_description,
        gross_salary: Math.round(newGross),
        total_deductions: Math.round(newTotalDeductions),
        net_salary: Math.round(netSalary),
      })
      .eq('id', payrollId)
      .select()
      .single();

    if (error) throw error;
    return { message: 'Payroll adjusted', payroll: updated };
  }

  // ============================================
  // APPROVE PAYROLL (Owner)
  // ============================================
  async approvePayroll(companyId: string, year: number, month: number, approverId: string) {
    const db = this.supabaseService.getClient();

    const { data, error } = await db
      .from('payroll')
      .update({
        status: 'approved',
        approved_by: approverId,
        approved_at: new Date().toISOString(),
      })
      .eq('company_id', companyId)
      .eq('year', year)
      .eq('month', month)
      .eq('status', 'calculated')
      .select();

    if (error) throw error;
    return { message: `${data?.length || 0} payrolls approved`, payrolls: data };
  }

  // ============================================
  // SEND PAYSLIPS TO EMPLOYEES
  // ============================================
  async sendPayslips(companyId: string, year: number, month: number) {
    const db = this.supabaseService.getClient();

    // Mark as sent (in real app, send push notification)
    const { data, error } = await db
      .from('payroll')
      .update({
        sent_to_employee: true,
        sent_at: new Date().toISOString(),
        status: 'paid',
        paid_at: new Date().toISOString(),
      })
      .eq('company_id', companyId)
      .eq('year', year)
      .eq('month', month)
      .eq('status', 'approved')
      .select();

    if (error) throw error;

    // TODO: Send push notification to each employee
    // TODO: Generate PDF payslips

    return { message: `Payslips sent to ${data?.length || 0} employees` };
  }

  // ============================================
  // HELPERS
  // ============================================

  // Myanmar Income Tax Calculator (2025/2026 brackets)
  private calculateMyanmarTax(annualIncome: number): number {
    // Myanmar progressive tax rates
    // First 4,800,000 MMK → 0%
    // 4,800,001 - 7,600,000 → 5%
    // 7,600,001 - 12,600,000 → 10%
    // 12,600,001 - 19,600,000 → 15%
    // 19,600,001 - 30,600,000 → 20%
    // Above 30,600,000 → 25%

    const brackets = [
      { limit: 4800000, rate: 0 },
      { limit: 7600000, rate: 0.05 },
      { limit: 12600000, rate: 0.10 },
      { limit: 19600000, rate: 0.15 },
      { limit: 30600000, rate: 0.20 },
      { limit: Infinity, rate: 0.25 },
    ];

    let tax = 0;
    let previousLimit = 0;

    for (const bracket of brackets) {
      if (annualIncome <= previousLimit) break;
      const taxableInBracket = Math.min(annualIncome, bracket.limit) - previousLimit;
      tax += taxableInBracket * bracket.rate;
      previousLimit = bracket.limit;
    }

    return Math.max(0, tax);
  }

  // Calculate working days in a month
  private getWorkingDaysInMonth(year: number, month: number, workingDays: number[]): number {
    let count = 0;
    const date = new Date(year, month - 1, 1);
    while (date.getMonth() === month - 1) {
      const dayOfWeek = date.getDay(); // 0=Sun, 1=Mon...
      const isoDay = dayOfWeek === 0 ? 7 : dayOfWeek; // Convert to 1=Mon, 7=Sun
      if (workingDays.includes(isoDay)) count++;
      date.setDate(date.getDate() + 1);
    }
    return count;
  }
}
