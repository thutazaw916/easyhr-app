import { Controller, Post, Get, Delete, Body, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ChatbotService } from './chatbot.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { IsString, IsNotEmpty, IsOptional, IsArray } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

class ChatMessageDto {
  @ApiProperty({ example: 'How many leave days do I have left?' })
  @IsString()
  @IsNotEmpty()
  message: string;

  @ApiProperty({ required: false })
  @IsArray()
  @IsOptional()
  history?: { role: string; content: string }[];
}

@ApiTags('AI Chatbot')
@Controller('chatbot')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ChatbotController {
  constructor(private readonly chatbotService: ChatbotService) {}

  @Post('chat')
  @ApiOperation({ summary: 'Send message to AI chatbot' })
  async chat(@Request() req, @Body() dto: ChatMessageDto) {
    return this.chatbotService.chat(
      dto.message,
      req.user.id,
      req.user.company_id,
      dto.history || [],
    );
  }

  @Get('history')
  @ApiOperation({ summary: 'Get chatbot conversation history' })
  async getHistory(@Request() req, @Query('limit') limit?: number) {
    return this.chatbotService.getChatHistory(req.user.id, Number(limit) || 50);
  }

  @Delete('history')
  @ApiOperation({ summary: 'Clear chatbot conversation history' })
  async clearHistory(@Request() req) {
    return this.chatbotService.clearHistory(req.user.id);
  }
}
