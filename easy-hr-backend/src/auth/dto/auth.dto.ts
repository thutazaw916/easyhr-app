// src/auth/dto/auth.dto.ts
import { IsString, IsEmail, IsOptional, IsNotEmpty, MinLength, MaxLength, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

// ============================================
// Company Sign Up
// ============================================
export class CompanySignUpDto {
  @ApiProperty({ example: 'ABC Company' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'ABC ကုမ္ပဏီ', required: false })
  @IsString()
  @IsOptional()
  name_mm?: string;

  @ApiProperty({ example: 'retail', enum: ['manufacturing', 'retail', 'fnb', 'service', 'technology', 'construction', 'education', 'healthcare', 'other'] })
  @IsString()
  @IsNotEmpty()
  business_type: string;

  @ApiProperty({ example: 'admin@abc.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: '09123456789' })
  @IsString()
  @IsNotEmpty()
  // @Matches(/^(09|\+959)\d{7,9}$/, { message: 'Invalid Myanmar phone number' })
  phone: string;

  @ApiProperty({ example: 'No. 123, Bogyoke Road, Yangon' })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiProperty({ example: 'Yangon', required: false })
  @IsString()
  @IsOptional()
  city?: string;

  @ApiProperty({ example: 'Yangon Region', required: false })
  @IsString()
  @IsOptional()
  state_region?: string;
}

// ============================================
// Verify Company (after sign up)
// ============================================
export class VerifyCompanyDto {
  @ApiProperty({ example: 'admin@abc.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @IsNotEmpty()
  verification_code: string;
}

// ============================================
// Company Owner Set Password (first time)
// ============================================
export class SetPasswordDto {
  @ApiProperty({ example: 'admin@abc.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'MySecureP@ss123' })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiProperty({ example: 'Owner Name' })
  @IsString()
  @IsNotEmpty()
  owner_name: string;

  @ApiProperty({ example: '09123456789' })
  @IsString()
  // @Matches(/^(09|\+959)\d{7,9}$/, { message: 'Invalid Myanmar phone number' })
  owner_phone: string;
}

// ============================================
// Owner / HR Login (Email + Password)
// ============================================
export class AdminLoginDto {
  @ApiProperty({ example: 'admin@abc.com' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'MySecureP@ss123' })
  @IsString()
  @IsNotEmpty()
  password: string;
}

// ============================================
// Employee Login - Request OTP
// ============================================
export class RequestOtpDto {
  @ApiProperty({ example: '09123456789' })
  @IsString()
  @IsNotEmpty()
  // @Matches(/^(09|\+959)\d{7,9}$/, { message: 'Invalid Myanmar phone number' })
  phone: string;
}

// ============================================
// Employee Login - Verify OTP
// ============================================
export class VerifyOtpDto {
  @ApiProperty({ example: '09123456789' })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiProperty({ example: '123456' })
  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  @MaxLength(6)
  otp: string;
}

// ============================================
// Employee Login - Firebase Phone Auth
// ============================================
export class FirebasePhoneLoginDto {
  @ApiProperty({ example: 'eyJhbGciOiJSUzI1NiIs...' })
  @IsString()
  @IsNotEmpty()
  firebase_id_token: string;

  @ApiProperty({ example: '09123456789' })
  @IsString()
  @IsNotEmpty()
  phone: string;
}