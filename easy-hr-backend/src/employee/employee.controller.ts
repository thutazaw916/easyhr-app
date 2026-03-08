// src/employee/employee.controller.ts
import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { EmployeeService } from './employee.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';

@ApiTags('Employees')
@Controller('employees')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class EmployeeController {
  constructor(private readonly employeeService: EmployeeService) {}

  // ============================================
  // Admin Endpoints (Owner / HR)
  // ============================================

  @Post()
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Add new employee (Owner/HR)' })
  async addEmployee(@Request() req, @Body() data: any) {
    return this.employeeService.addEmployee(req.user.company_id, data);
  }

  @Get()
  @Roles('owner', 'hr_manager', 'department_head', 'employee')
  @ApiOperation({ summary: 'List employees with filters' })
  @ApiQuery({ name: 'department_id', required: false })
  @ApiQuery({ name: 'branch_id', required: false })
  @ApiQuery({ name: 'role', required: false })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'page', required: false })
  @ApiQuery({ name: 'limit', required: false })
  async listEmployees(@Request() req, @Query() query: any) {
    return this.employeeService.listEmployees(req.user.company_id, query);
  }

  @Get('me')
  @ApiOperation({ summary: 'Get my profile (any employee)' })
  async getMyProfile(@Request() req) {
    return this.employeeService.getMyProfile(req.user.id);
  }

  @Put('me/settings')
  @ApiOperation({ summary: 'Update my settings (language, dark mode)' })
  async updateMySettings(@Request() req, @Body() data: any) {
    return this.employeeService.updateMySettings(req.user.id, data);
  }

  @Get(':id')
  @Roles('owner', 'hr_manager', 'department_head')
  @ApiOperation({ summary: 'Get employee detail' })
  async getEmployee(@Request() req, @Param('id') id: string) {
    return this.employeeService.getEmployee(req.user.company_id, id);
  }

  @Put(':id')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Update employee (Owner/HR)' })
  async updateEmployee(@Request() req, @Param('id') id: string, @Body() data: any) {
    return this.employeeService.updateEmployee(req.user.company_id, id, data);
  }

  @Delete(':id')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Deactivate employee (Owner/HR)' })
  async deactivateEmployee(@Request() req, @Param('id') id: string) {
    return this.employeeService.deactivateEmployee(req.user.company_id, id);
  }
}
