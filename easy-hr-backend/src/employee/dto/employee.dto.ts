import { IsString, IsEmail, IsOptional, IsNotEmpty, IsEnum, IsBoolean } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateEmployeeDto {
  @ApiProperty({ example: 'Aung' })
  @IsString()
  @IsNotEmpty()
  first_name: string;

  @ApiProperty({ example: 'Aung', required: false })
  @IsString()
  @IsOptional()
  last_name?: string;

  @ApiProperty({ example: 'aung@abc.com', required: false })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({ example: '09123456789' })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiProperty({ example: 'employee', enum: ['owner', 'hr_manager', 'department_head', 'employee'] })
  @IsString()
  @IsOptional()
  role?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  department_id?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  branch_id?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  position_id?: string;

  @ApiProperty({ example: 500000, required: false })
  @IsOptional()
  base_salary?: number;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  date_of_birth?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  hire_date?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  nrc_number?: string;
}

export class UpdateEmployeeDto {
  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  first_name?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  last_name?: string;

  @ApiProperty({ required: false })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  role?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  department_id?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  branch_id?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  position_id?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  base_salary?: number;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  date_of_birth?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  hire_date?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  nrc_number?: string;
}

export class UpdateSettingsDto {
  @ApiProperty({ example: 'mm', required: false })
  @IsString()
  @IsOptional()
  language?: string;

  @ApiProperty({ example: false, required: false })
  @IsBoolean()
  @IsOptional()
  dark_mode?: boolean;
}

export class InviteEmployeeDto {
  @ApiProperty({ example: '09123456789' })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiProperty({ example: 'Aung Aung' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'employee', enum: ['hr_manager', 'department_head', 'employee'] })
  @IsString()
  @IsOptional()
  role?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  department_id?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  branch_id?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  position_id?: string;
}
