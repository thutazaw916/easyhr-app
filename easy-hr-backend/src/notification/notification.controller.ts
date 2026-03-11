import { Controller, Get, Put, Param, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { NotificationService } from './notification.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('Notifications')
@Controller('notifications')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Get()
  @ApiOperation({ summary: 'Get my notifications' })
  async getMyNotifications(@Request() req, @Query('limit') limit?: number) {
    return this.notificationService.getMyNotifications(req.user.id, limit || 50);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Get unread notification count' })
  async getUnreadCount(@Request() req) {
    return this.notificationService.getUnreadCount(req.user.id);
  }

  @Put('read')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  async markAllRead(@Request() req) {
    return this.notificationService.markAsRead(req.user.id);
  }

  @Put(':id/read')
  @ApiOperation({ summary: 'Mark single notification as read' })
  async markOneRead(@Request() req, @Param('id') id: string) {
    return this.notificationService.markAsRead(req.user.id, id);
  }
}
