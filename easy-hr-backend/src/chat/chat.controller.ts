import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';

@ApiTags('Chat')
@Controller('chat')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('channels')
  @ApiOperation({ summary: 'Get my chat channels with unread counts' })
  async getChannels(@Request() req) {
    return this.chatService.getMyChannels(req.user.company_id, req.user.id, req.user.department_id);
  }

  @Post('channels')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Create chat channel' })
  async createChannel(@Request() req, @Body() data: any) {
    return this.chatService.createChannel(req.user.company_id, req.user.id, data);
  }

  @Post('channels/init')
  @Roles('owner')
  @ApiOperation({ summary: 'Initialize all company & department channels' })
  async initChannels(@Request() req) {
    return this.chatService.initCompanyChannels(req.user.company_id, req.user.id);
  }

  @Get('channels/:channelId/messages')
  @ApiOperation({ summary: 'Get channel messages' })
  async getMessages(
    @Request() req,
    @Param('channelId') channelId: string,
    @Query('page') page?: number,
  ) {
    return this.chatService.getMessages(channelId, req.user.id, Number(page) || 1);
  }

  @Post('channels/:channelId/messages')
  @ApiOperation({ summary: 'Send message' })
  async sendMessage(@Request() req, @Param('channelId') channelId: string, @Body() data: any) {
    return this.chatService.sendMessage(channelId, req.user.id, data);
  }

  @Put('messages/:messageId/pin')
  @Roles('owner', 'hr_manager', 'department_head')
  @ApiOperation({ summary: 'Pin/Unpin message' })
  async pinMessage(@Param('messageId') id: string, @Body() data: { pin: boolean }) {
    return this.chatService.pinMessage(id, data.pin);
  }

  @Delete('messages/:messageId')
  @ApiOperation({ summary: 'Delete own message' })
  async deleteMessage(@Request() req, @Param('messageId') id: string) {
    return this.chatService.deleteMessage(id, req.user.id);
  }
}