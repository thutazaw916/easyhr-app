// src/department/department.controller.ts
import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { DepartmentService } from './department.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';

@ApiTags('Departments')
@Controller('departments')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class DepartmentController {
  constructor(private readonly departmentService: DepartmentService) {}

  @Post()
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Create department' })
  async create(@Request() req, @Body() data: any) {
    return this.departmentService.create(req.user.company_id, data);
  }

  @Get()
  @ApiOperation({ summary: 'List departments' })
  async list(@Request() req) {
    return this.departmentService.list(req.user.company_id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get department' })
  async get(@Request() req, @Param('id') id: string) {
    return this.departmentService.get(req.user.company_id, id);
  }

  @Put(':id')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Update department' })
  async update(@Request() req, @Param('id') id: string, @Body() data: any) {
    return this.departmentService.update(req.user.company_id, id, data);
  }

  @Delete(':id')
  @Roles('owner')
  @ApiOperation({ summary: 'Delete department (Owner only)' })
  async delete(@Request() req, @Param('id') id: string) {
    return this.departmentService.delete(req.user.company_id, id);
  }
}
