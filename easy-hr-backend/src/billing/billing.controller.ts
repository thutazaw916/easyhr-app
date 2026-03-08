import { Controller, Get, Post, Put, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { BillingService } from './billing.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';
import { SuperAdminGuard } from '../super-admin/super-admin.guard';

@ApiTags('Billing & Subscription')
@Controller('billing')
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

  // ============================================
  // PUBLIC: Get pricing plans
  // ============================================
  @Get('plans')
  @ApiOperation({ summary: 'Get all pricing plans (public)' })
  getPlans() {
    return this.billingService.getPlans();
  }

  // ============================================
  // COMPANY: Current subscription
  // ============================================
  @Get('subscription')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get current company subscription' })
  async getSubscription(@Request() req) {
    return this.billingService.getCurrentSubscription(req.user.company_id);
  }

  // ============================================
  // COMPANY: Submit payment
  // ============================================
  @Post('pay')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('owner', 'hr_manager')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Submit payment for plan upgrade (Owner/HR)' })
  async submitPayment(@Request() req, @Body() data: any) {
    return this.billingService.submitPayment(req.user.company_id, req.user.id, data);
  }

  // ============================================
  // COMPANY: Payment history
  // ============================================
  @Get('payments')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get company payment history' })
  async getPaymentHistory(@Request() req) {
    return this.billingService.getPaymentHistory(req.user.company_id);
  }

  // ============================================
  // SUPER ADMIN: Pending payments
  // ============================================
  @Get('admin/pending')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '🔐 Get pending payments for approval' })
  async getPendingPayments() {
    return this.billingService.getPendingPayments();
  }

  // ============================================
  // SUPER ADMIN: All payments
  // ============================================
  @Get('admin/all')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '🔐 Get all payments with filters' })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'page', required: false })
  async getAllPayments(@Query() query: any) {
    return this.billingService.getAllPayments(query);
  }

  // ============================================
  // SUPER ADMIN: Approve payment
  // ============================================
  @Put('admin/approve/:id')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '🔐 Approve payment & activate plan' })
  async approvePayment(@Param('id') id: string) {
    return this.billingService.approvePayment(id);
  }

  // ============================================
  // SUPER ADMIN: Reject payment
  // ============================================
  @Put('admin/reject/:id')
  @UseGuards(SuperAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '🔐 Reject payment' })
  async rejectPayment(@Param('id') id: string, @Body() data: any) {
    return this.billingService.rejectPayment(id, data?.reason);
  }
}
