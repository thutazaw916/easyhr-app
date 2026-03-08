// src/branch/branch.controller.ts
import { Controller, Get, Post, Put, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { BranchService } from './branch.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';

@ApiTags('Branches')
@Controller('branches')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class BranchController {
  constructor(private readonly branchService: BranchService) {}

  @Post()
  @Roles('owner')
  @ApiOperation({ summary: 'Create branch (Owner only)' })
  async create(@Request() req, @Body() data: any) {
    return this.branchService.createBranch(req.user.company_id, data);
  }

  @Get()
  @ApiOperation({ summary: 'List all branches' })
  async list(@Request() req) {
    return this.branchService.listBranches(req.user.company_id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get branch detail' })
  async get(@Request() req, @Param('id') id: string) {
    return this.branchService.getBranch(req.user.company_id, id);
  }

  @Put(':id')
  @Roles('owner')
  @ApiOperation({ summary: 'Update branch' })
  async update(@Request() req, @Param('id') id: string, @Body() data: any) {
    return this.branchService.updateBranch(req.user.company_id, id, data);
  }

  @Put(':id/gps')
  @Roles('owner')
  @ApiOperation({ summary: 'Set GPS location and radius for check-in' })
  async updateGps(@Request() req, @Param('id') id: string, @Body() data: any) {
    return this.branchService.updateGpsSettings(req.user.company_id, id, data);
  }

  @Put(':id/qr-toggle')
  @Roles('owner')
  @ApiOperation({ summary: 'Enable/disable QR code attendance' })
  async toggleQr(@Request() req, @Param('id') id: string, @Body() data: { enabled: boolean }) {
    return this.branchService.toggleQrCode(req.user.company_id, id, data.enabled);
  }
}
