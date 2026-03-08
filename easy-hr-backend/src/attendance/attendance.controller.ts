import { Controller, Get, Post, Body, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AttendanceService } from './attendance.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';

@ApiTags('Attendance')
@Controller('attendance')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) {}

  // ============================================
  // Employee Endpoints
  // ============================================

  @Post('check-in')
  @ApiOperation({ summary: 'GPS Check-in (Employee)' })
  async checkIn(@Request() req, @Body() data: { latitude: number; longitude: number; device_id?: string }) {
    return this.attendanceService.checkIn(req.user.id, req.user.company_id, data);
  }

  @Post('check-out')
  @ApiOperation({ summary: 'GPS Check-out (Employee)' })
  async checkOut(@Request() req, @Body() data: { latitude: number; longitude: number }) {
    return this.attendanceService.checkOut(req.user.id, req.user.company_id, data);
  }

  @Post('qr-check-in')
  @ApiOperation({ summary: 'QR Code Check-in (Employee)' })
  async qrCheckIn(@Request() req, @Body() data: { qr_code: string; latitude?: number; longitude?: number; device_id?: string }) {
    return this.attendanceService.qrCheckIn(req.user.id, req.user.company_id, data);
  }

  @Get('my-status')
  @ApiOperation({ summary: 'Get today check-in status & button state' })
  @ApiQuery({ name: 'latitude', required: false })
  @ApiQuery({ name: 'longitude', required: false })
  async getMyStatus(
    @Request() req,
    @Query('latitude') latitude?: number,
    @Query('longitude') longitude?: number,
  ) {
    return this.attendanceService.getMyTodayStatus(
      req.user.id, req.user.company_id,
      latitude ? Number(latitude) : undefined,
      longitude ? Number(longitude) : undefined,
    );
  }

  @Get('my-history')
  @ApiOperation({ summary: 'Get my attendance history (Employee)' })
  @ApiQuery({ name: 'month', required: false })
  @ApiQuery({ name: 'year', required: false })
  async getMyHistory(@Request() req, @Query() query: any) {
    return this.attendanceService.getMyAttendanceHistory(req.user.id, query);
  }

  // ============================================
  // Admin Endpoints (Owner / HR)
  // ============================================

  @Get('daily-report')
  @Roles('owner', 'hr_manager', 'department_head')
  @ApiOperation({ summary: 'Daily attendance report (Admin)' })
  @ApiQuery({ name: 'date', required: false, example: '2026-02-25' })
  @ApiQuery({ name: 'department_id', required: false })
  async getDailyReport(
    @Request() req,
    @Query('date') date?: string,
    @Query('department_id') departmentId?: string,
  ) {
    return this.attendanceService.getDailyReport(req.user.company_id, date, departmentId);
  }

  @Get('monthly-report')
  @Roles('owner', 'hr_manager', 'department_head')
  @ApiOperation({ summary: 'Monthly attendance report (Admin)' })
  @ApiQuery({ name: 'year', required: true, example: 2026 })
  @ApiQuery({ name: 'month', required: true, example: 2 })
  @ApiQuery({ name: 'department_id', required: false })
  async getMonthlyReport(
    @Request() req,
    @Query('year') year: number,
    @Query('month') month: number,
    @Query('department_id') departmentId?: string,
  ) {
    return this.attendanceService.getMonthlyReport(
      req.user.company_id, Number(year), Number(month), departmentId,
    );
  }
}
