import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import {
  CompanySignUpDto,
  VerifyCompanyDto,
  SetPasswordDto,
  AdminLoginDto,
  RequestOtpDto,
  VerifyOtpDto,
  FirebasePhoneLoginDto,
} from './dto/auth.dto';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('company/signup')
  @ApiOperation({ summary: 'Register a new company' })
  @ApiResponse({ status: 201, description: 'Company registered, verification code sent' })
  async companySignUp(@Body() dto: CompanySignUpDto) {
    return this.authService.companySignUp(dto);
  }

  @Post('company/verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify company with code' })
  async verifyCompany(@Body() dto: VerifyCompanyDto) {
    return this.authService.verifyCompany(dto);
  }

  @Post('company/set-password')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Set owner password after verification' })
  async setOwnerPassword(@Body() dto: SetPasswordDto) {
    return this.authService.setOwnerPassword(dto);
  }

  @Post('admin/login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Admin login with email and password' })
  async adminLogin(@Body() dto: AdminLoginDto) {
    return this.authService.adminLogin(dto);
  }

  @Post('employee/request-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Request OTP for employee login' })
  async requestOtp(@Body() dto: RequestOtpDto) {
    return this.authService.requestOtp(dto);
  }

  @Post('employee/verify-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify OTP and login' })
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto);
  }

  @Post('employee/firebase-login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with Firebase Phone Auth token' })
  async firebasePhoneLogin(@Body() dto: FirebasePhoneLoginDto) {
    return this.authService.firebasePhoneLogin(dto);
  }
}