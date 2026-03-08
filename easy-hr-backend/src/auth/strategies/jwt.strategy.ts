// src/auth/strategies/jwt.strategy.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { SupabaseService } from '../../supabase/supabase.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    configService: ConfigService,
    private supabaseService: SupabaseService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET') || 'default-secret-change-me',
    });
  }

  async validate(payload: any) {
    const db = this.supabaseService.getClient();

    const { data: employee } = await db
      .from('employees')
      .select('*')
      .eq('id', payload.sub)
      .eq('is_active', true)
      .single();

    if (!employee) {
      throw new UnauthorizedException('Invalid token or account deactivated');
    }

    return {
      id: employee.id,
      email: employee.email,
      phone: employee.phone,
      role: employee.role,
      company_id: employee.company_id,
      department_id: employee.department_id,
      branch_id: employee.branch_id,
    };
  }
}