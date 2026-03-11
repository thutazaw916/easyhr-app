import { IsString, IsOptional, IsNotEmpty, IsBoolean, IsNumber, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateSalaryComponentDto {
  @ApiProperty({ example: 'Transport Allowance' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'သွားလာစရိတ်', required: false })
  @IsString()
  @IsOptional()
  name_mm?: string;

  @ApiProperty({ example: 'earning', enum: ['earning', 'deduction'] })
  @IsString()
  @IsNotEmpty()
  type: string;

  @ApiProperty({ example: 'allowance', enum: ['allowance', 'bonus', 'deduction', 'tax'], required: false })
  @IsString()
  @IsOptional()
  category?: string;

  @ApiProperty({ example: false, required: false })
  @IsBoolean()
  @IsOptional()
  is_percentage?: boolean;

  @ApiProperty({ example: 50000, required: false })
  @IsNumber()
  @IsOptional()
  default_value?: number;

  @ApiProperty({ example: true, required: false })
  @IsBoolean()
  @IsOptional()
  is_taxable?: boolean;

  @ApiProperty({ example: 1, required: false })
  @IsNumber()
  @IsOptional()
  sort_order?: number;
}

export class UpdateSalaryComponentDto {
  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  name_mm?: string;

  @ApiProperty({ required: false })
  @IsBoolean()
  @IsOptional()
  is_percentage?: boolean;

  @ApiProperty({ required: false })
  @IsNumber()
  @IsOptional()
  default_value?: number;

  @ApiProperty({ required: false })
  @IsBoolean()
  @IsOptional()
  is_taxable?: boolean;

  @ApiProperty({ required: false })
  @IsBoolean()
  @IsOptional()
  is_active?: boolean;

  @ApiProperty({ required: false })
  @IsNumber()
  @IsOptional()
  sort_order?: number;
}

export class SetEmployeeComponentDto {
  @ApiProperty({ example: 'uuid-of-component' })
  @IsString()
  @IsNotEmpty()
  component_id: string;

  @ApiProperty({ example: 50000 })
  @IsNumber()
  @IsNotEmpty()
  value: number;
}
