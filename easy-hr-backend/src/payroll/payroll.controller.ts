import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { CreateSalaryComponentDto, UpdateSalaryComponentDto, SetEmployeeComponentDto } from './dto/payroll.dto';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { PayrollService } from './payroll.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';
import { SubscriptionGuard, PremiumFeature } from '../auth/guards/subscription.guard';

@ApiTags('Payroll')
@Controller('payroll')
@UseGuards(JwtAuthGuard, RolesGuard, SubscriptionGuard)
@ApiBearerAuth()
export class PayrollController {
  constructor(private readonly payrollService: PayrollService) {}

  // ============================================
  // Salary Structure
  // ============================================

  @Post('salary-structure/:employeeId')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Set employee salary structure (Owner/HR)' })
  async setSalaryStructure(
    @Request() req,
    @Param('employeeId') employeeId: string,
    @Body() data: any,
  ) {
    return this.payrollService.setSalaryStructure(req.user.company_id, employeeId, data);
  }

  @Get('salary-structure/:employeeId')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Get employee salary structure' })
  async getSalaryStructure(@Request() req, @Param('employeeId') employeeId: string) {
    return this.payrollService.getSalaryStructure(req.user.company_id, employeeId);
  }

  @Get('salary-structures')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Get all salary structures' })
  async getAllSalaryStructures(@Request() req) {
    return this.payrollService.getAllSalaryStructures(req.user.company_id);
  }

  // ============================================
  // Salary Advance (ကြိုတင်ထုတ်ငွေ)
  // ============================================

  @Post('advance/request')
  @ApiOperation({ summary: 'Request salary advance (Employee)' })
  async requestAdvance(@Request() req, @Body() data: any) {
    return this.payrollService.requestAdvance(req.user.id, req.user.company_id, data);
  }

  @Put('advance/:id/approve')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Approve salary advance' })
  async approveAdvance(@Request() req, @Param('id') id: string) {
    return this.payrollService.approveAdvance(req.user.company_id, id, req.user.id, true);
  }

  @Put('advance/:id/reject')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Reject salary advance' })
  async rejectAdvance(@Request() req, @Param('id') id: string) {
    return this.payrollService.approveAdvance(req.user.company_id, id, req.user.id, false);
  }

  @Get('advances')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'List all salary advances' })
  @ApiQuery({ name: 'employee_id', required: false })
  async getAdvances(@Request() req, @Query('employee_id') employeeId?: string) {
    return this.payrollService.getAdvances(req.user.company_id, employeeId);
  }

  @Get('my-advances')
  @ApiOperation({ summary: 'Get my salary advances (Employee)' })
  async getMyAdvances(@Request() req) {
    return this.payrollService.getAdvances(req.user.company_id, req.user.id);
  }

  // ============================================
  // One-Click Salary Calculation 🔥
  // ============================================

  @Post('calculate')
  @Roles('owner', 'hr_manager')
  @PremiumFeature()
  @ApiOperation({ summary: '🔥 One-click salary calculation for all employees' })
  @ApiQuery({ name: 'year', required: true, example: 2026 })
  @ApiQuery({ name: 'month', required: true, example: 2 })
  async calculateSalary(@Request() req, @Query('year') year: number, @Query('month') month: number) {
    try {
      return await this.payrollService.calculateMonthlySalary(req.user.company_id, Number(year), Number(month));
    } catch (error) {
      console.error('Payroll calculation error:', error);
      throw error;
    }
  }

  // ============================================
  // Payroll Management
  // ============================================

  @Get('monthly')
  @Roles('owner', 'hr_manager')
  @PremiumFeature()
  @ApiOperation({ summary: 'Get monthly payroll with summary + chart data' })
  @ApiQuery({ name: 'year', required: true })
  @ApiQuery({ name: 'month', required: true })
  async getMonthlyPayroll(@Request() req, @Query('year') year: number, @Query('month') month: number) {
    return this.payrollService.getMonthlyPayroll(req.user.company_id, Number(year), Number(month));
  }

  @Put('adjust/:payrollId')
  @Roles('owner', 'hr_manager')
  @PremiumFeature()
  @ApiOperation({ summary: 'Adjust payroll (add bonus, deductions)' })
  async adjustPayroll(@Request() req, @Param('payrollId') payrollId: string, @Body() data: any) {
    return this.payrollService.adjustPayroll(req.user.company_id, payrollId, data);
  }

  @Post('approve')
  @Roles('owner')
  @PremiumFeature()
  @ApiOperation({ summary: 'Approve all payrolls for the month (Owner only)' })
  @ApiQuery({ name: 'year', required: true })
  @ApiQuery({ name: 'month', required: true })
  async approvePayroll(@Request() req, @Query('year') year: number, @Query('month') month: number) {
    return this.payrollService.approvePayroll(req.user.company_id, Number(year), Number(month), req.user.id);
  }

  @Post('send-payslips')
  @Roles('owner', 'hr_manager')
  @PremiumFeature()
  @ApiOperation({ summary: 'Send payslips to all employees' })
  @ApiQuery({ name: 'year', required: true })
  @ApiQuery({ name: 'month', required: true })
  async sendPayslips(@Request() req, @Query('year') year: number, @Query('month') month: number) {
    return this.payrollService.sendPayslips(req.user.company_id, Number(year), Number(month));
  }

  // ============================================
  // Employee Payslip
  // ============================================

  @Get('my-payslip')
  @ApiOperation({ summary: 'Get my payslip (Employee)' })
  @ApiQuery({ name: 'year', required: true })
  @ApiQuery({ name: 'month', required: true })
  async getMyPayslip(@Request() req, @Query('year') year: number, @Query('month') month: number) {
    return this.payrollService.getMyPayslip(req.user.id, Number(year), Number(month));
  }

  // ============================================
  // Custom Salary Components
  // ============================================

  @Get('components')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Get company salary components' })
  async getSalaryComponents(@Request() req) {
    return this.payrollService.getSalaryComponents(req.user.company_id);
  }

  @Post('components')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Create salary component' })
  async createSalaryComponent(@Request() req, @Body() dto: CreateSalaryComponentDto) {
    return this.payrollService.createSalaryComponent(req.user.company_id, dto);
  }

  @Put('components/:id')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Update salary component' })
  async updateSalaryComponent(@Request() req, @Param('id') id: string, @Body() dto: UpdateSalaryComponentDto) {
    return this.payrollService.updateSalaryComponent(req.user.company_id, id, dto);
  }

  @Delete('components/:id')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Delete salary component' })
  async deleteSalaryComponent(@Request() req, @Param('id') id: string) {
    return this.payrollService.deleteSalaryComponent(req.user.company_id, id);
  }

  @Get('components/employee/:employeeId')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Get employee salary components with values' })
  async getEmployeeComponents(@Request() req, @Param('employeeId') employeeId: string) {
    return this.payrollService.getEmployeeComponents(req.user.company_id, employeeId);
  }

  @Post('components/employee/:employeeId')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Set employee salary component value' })
  async setEmployeeComponent(@Request() req, @Param('employeeId') employeeId: string, @Body() dto: SetEmployeeComponentDto) {
    return this.payrollService.setEmployeeComponent(req.user.company_id, employeeId, dto.component_id, dto.value);
  }
}
