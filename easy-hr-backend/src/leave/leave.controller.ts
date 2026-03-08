import { Controller, Get, Post, Put, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { LeaveService } from './leave.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';

@ApiTags('Leave Management')
@Controller('leave')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class LeaveController {
  constructor(private readonly leaveService: LeaveService) {}

  // ============================================
  // Leave Types
  // ============================================

  @Get('types')
  @ApiOperation({ summary: 'Get all leave types' })
  async getLeaveTypes(@Request() req) {
    return this.leaveService.getLeaveTypes(req.user.company_id);
  }

  @Post('types')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Create custom leave type (Owner/HR)' })
  async createLeaveType(@Request() req, @Body() data: any) {
    return this.leaveService.createLeaveType(req.user.company_id, data);
  }

  @Put('types/:id')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Update leave type (Owner/HR)' })
  async updateLeaveType(@Request() req, @Param('id') id: string, @Body() data: any) {
    return this.leaveService.updateLeaveType(req.user.company_id, id, data);
  }

  // ============================================
  // Employee Endpoints
  // ============================================

  @Get('my-balances')
  @ApiOperation({ summary: 'Get my leave balances' })
  async getMyBalances(@Request() req) {
    return this.leaveService.getMyLeaveBalances(req.user.id);
  }

  @Post('request')
  @ApiOperation({ summary: 'Submit leave request (Employee)' })
  async requestLeave(@Request() req, @Body() data: any) {
    return this.leaveService.requestLeave(req.user.id, req.user.company_id, data);
  }

  @Get('my-requests')
  @ApiOperation({ summary: 'Get my leave requests' })
  @ApiQuery({ name: 'status', required: false, enum: ['pending', 'approved', 'rejected'] })
  async getMyRequests(@Request() req, @Query('status') status?: string) {
    return this.leaveService.getMyLeaveRequests(req.user.id, status);
  }

  // ============================================
  // Admin Endpoints (Owner / HR)
  // ============================================

  @Get('pending')
  @Roles('owner', 'hr_manager', 'department_head')
  @ApiOperation({ summary: 'Get pending leave requests (Admin)' })
  @ApiQuery({ name: 'department_id', required: false })
  async getPending(@Request() req, @Query('department_id') departmentId?: string) {
    return this.leaveService.getPendingRequests(req.user.company_id, departmentId);
  }

  @Put('requests/:id/approve')
  @Roles('owner', 'hr_manager', 'department_head')
  @ApiOperation({ summary: 'Approve leave request' })
  async approve(@Request() req, @Param('id') id: string) {
    return this.leaveService.updateLeaveStatus(req.user.company_id, id, req.user.id, { status: 'approved' });
  }

  @Put('requests/:id/reject')
  @Roles('owner', 'hr_manager', 'department_head')
  @ApiOperation({ summary: 'Reject leave request' })
  async reject(@Request() req, @Param('id') id: string, @Body() data: { rejection_reason?: string }) {
    return this.leaveService.updateLeaveStatus(req.user.company_id, id, req.user.id, {
      status: 'rejected',
      rejection_reason: data.rejection_reason,
    });
  }

  @Get('calendar')
  @Roles('owner', 'hr_manager', 'department_head')
  @ApiOperation({ summary: 'Leave calendar view (Admin)' })
  @ApiQuery({ name: 'year', required: true })
  @ApiQuery({ name: 'month', required: true })
  async getCalendar(@Request() req, @Query('year') year: number, @Query('month') month: number) {
    return this.leaveService.getLeaveCalendar(req.user.company_id, Number(year), Number(month));
  }
}
