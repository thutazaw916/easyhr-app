import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AnnouncementService } from './announcement.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';

@ApiTags('Announcements')
@Controller('announcements')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class AnnouncementController {
  constructor(private readonly service: AnnouncementService) {}

  @Post()
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Create announcement' })
  async create(@Request() req, @Body() data: any) {
    return this.service.create(req.user.company_id, req.user.id, data);
  }

  @Get()
  @ApiOperation({ summary: 'Get all announcements' })
  async getAll(@Request() req) {
    return this.service.getAll(req.user.company_id, req.user.id, req.user.department_id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get announcement detail' })
  async getOne(@Param('id') id: string) {
    return this.service.getOne(id);
  }

  @Put(':id/read')
  @ApiOperation({ summary: 'Mark announcement as read' })
  async markRead(@Request() req, @Param('id') id: string) {
    return this.service.markAsRead(id, req.user.id);
  }

  @Put(':id/pin')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Pin/Unpin announcement' })
  async pin(@Param('id') id: string, @Body() data: { pin: boolean }) {
    return this.service.pin(id, data.pin);
  }

  @Delete(':id')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Delete announcement' })
  async remove(@Param('id') id: string) {
    return this.service.remove(id);
  }
}