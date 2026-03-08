import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PositionService } from './position.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard, Roles } from '../auth/guards/roles.guard';

@ApiTags('Positions')
@Controller('positions')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class PositionController {
  constructor(private readonly positionService: PositionService) {}

  @Post()
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Create position' })
  async create(@Request() req, @Body() data: any) {
    return this.positionService.create(req.user.company_id, data);
  }

  @Get()
  @ApiOperation({ summary: 'List positions' })
  async list(@Request() req, @Query('department_id') departmentId?: string) {
    return this.positionService.list(req.user.company_id, departmentId);
  }

  @Put(':id')
  @Roles('owner', 'hr_manager')
  @ApiOperation({ summary: 'Update position' })
  async update(@Request() req, @Param('id') id: string, @Body() data: any) {
    return this.positionService.update(req.user.company_id, id, data);
  }

  @Delete(':id')
  @Roles('owner')
  @ApiOperation({ summary: 'Delete position' })
  async delete(@Request() req, @Param('id') id: string) {
    return this.positionService.delete(req.user.company_id, id);
  }
}