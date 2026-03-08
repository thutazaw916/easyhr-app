import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { SuperAdminService } from './super-admin.service';
import { SuperAdminGuard } from './super-admin.guard';

@ApiTags('🔐 Super Admin (Platform Owner)')
@Controller('super-admin')
export class SuperAdminController {
  constructor(private readonly service: SuperAdminService) {}

  // ============================================
  // AUTH (No guard needed)
  // ============================================

  @Post('setup')
  @ApiOperation({ summary: '🔧 First-time setup: Create super admin account' })
  async setup(@Body() data: { email: string; password: string; name: string; phone?: string }) {
    return this.service.setupSuperAdmin(data);
  }

  @Post('login')
  @ApiOperation({ summary: '🔑 Super Admin login' })
  async login(@Body() data: { email: string; password: string }) {
    return this.service.login(data.email, data.password);
  }

  // ============================================
  // DASHBOARD (Protected)
  // ============================================

  @Get('dashboard')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '📊 Platform overview - companies, employees, MRR' })
  async getDashboard() {
    return this.service.getPlatformOverview();
  }

  @Get('revenue')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '💰 Revenue report - pricing tiers breakdown with MMK' })
  async getRevenue() {
    return this.service.getRevenueReport();
  }

  @Get('analytics')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '📈 Growth analytics (signups, regions, business types)' })
  @ApiQuery({ name: 'period', required: false, enum: ['7d', '30d', '90d', '365d'] })
  async getAnalytics(@Query('period') period?: string) {
    return this.service.getGrowthAnalytics(period || '30d');
  }

  // ============================================
  // COMPANY MANAGEMENT
  // ============================================

  @Get('companies')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '🏢 List all companies with auto-calculated pricing' })
  @ApiQuery({ name: 'status', required: false, enum: ['active', 'suspended', 'inactive'] })
  @ApiQuery({ name: 'plan', required: false, enum: ['free', 'starter', 'business', 'enterprise'] })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'page', required: false })
  async getCompanies(@Query() query: any) {
    return this.service.getAllCompanies(query);
  }

  @Get('companies/:id')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '🏢 Company detail + employees + pricing tier' })
  async getCompanyDetail(@Param('id') id: string) {
    return this.service.getCompanyDetail(id);
  }

  @Put('companies/:id/suspend')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '🚫 Suspend company (လစဥ်ကြေးမပေးလျှင်)' })
  async suspendCompany(@Param('id') id: string, @Body() data: { reason: string }) {
    return this.service.suspendCompany(id, data.reason);
  }

  @Put('companies/:id/unsuspend')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '✅ Unsuspend company' })
  async unsuspendCompany(@Param('id') id: string) {
    return this.service.unsuspendCompany(id);
  }

  @Put('companies/:id/plan')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '💎 Manual plan override' })
  async updatePlan(@Param('id') id: string, @Body() data: any) {
    return this.service.updateCompanyPlan(id, data);
  }

  @Delete('companies/:id')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '⚠️ Deactivate company (soft delete)' })
  async deleteCompany(@Param('id') id: string) {
    return this.service.deleteCompany(id);
  }
}