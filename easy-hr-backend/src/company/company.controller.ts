// src/company/company.controller.ts
import { Controller, Get, Put, Body, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { CompanyService } from './company.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';

@ApiTags('Company')
@Controller('company')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class CompanyController {
  constructor(private readonly companyService: CompanyService) {}

  @Get('profile')
  @ApiOperation({ summary: 'Get company profile' })
  async getProfile(@Request() req) {
    return this.companyService.getCompanyProfile(req.user.company_id);
  }

  @Put('profile')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Update company profile (Owner/HR only)' })
  async updateProfile(@Request() req, @Body() data: any) {
    return this.companyService.updateCompanyProfile(req.user.company_id, data);
  }

  @Put('working-hours')
  @Roles('owner')
  @ApiOperation({ summary: 'Update working hours (Owner only)' })
  async updateWorkingHours(@Request() req, @Body() data: any) {
    return this.companyService.updateWorkingHours(req.user.company_id, data);
  }

  @Get('dashboard')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Get dashboard stats (Owner/HR only)' })
  async getDashboard(@Request() req) {
    return this.companyService.getDashboardStats(req.user.company_id);
  }
}
