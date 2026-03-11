// src/auth/guards/subscription.guard.ts
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { SupabaseService } from '../../supabase/supabase.service';

// Decorator to mark endpoints as premium-only
export const PREMIUM_KEY = 'isPremiumFeature';
export const PremiumFeature = () => SetMetadata(PREMIUM_KEY, true);

// Plans that count as "paid" (not free trial)
const PAID_PLANS = ['starter', 'business', 'enterprise'];

@Injectable()
export class SubscriptionGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private supabaseService: SupabaseService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    // No user means JwtAuthGuard hasn't run yet (shouldn't happen)
    if (!user || !user.company_id) {
      return true;
    }

    const db = this.supabaseService.getClient();

    // Fetch company subscription info
    const { data: company } = await db
      .from('companies')
      .select('id, subscription_plan, subscription_status, subscription_start, subscription_end, max_employees, is_suspended')
      .eq('id', user.company_id)
      .single();

    if (!company) {
      throw new HttpException(
        {
          statusCode: HttpStatus.FORBIDDEN,
          message: 'Company not found',
          error: 'Forbidden',
        },
        HttpStatus.FORBIDDEN,
      );
    }

    // Check if company is suspended
    if (company.is_suspended) {
      throw new HttpException(
        {
          statusCode: HttpStatus.FORBIDDEN,
          message: 'Your company account has been suspended. Please contact support.',
          message_mm: 'သင့်ကုမ္ပဏီအကောင့်ကို ဆိုင်းငံ့ထားပါသည်။ အကူအညီအတွက် ဆက်သွယ်ပါ။',
          error: 'Suspended',
        },
        HttpStatus.FORBIDDEN,
      );
    }

    // Check subscription expiry
    const now = new Date();
    const subscriptionEnd = company.subscription_end ? new Date(company.subscription_end) : null;
    const isExpired = subscriptionEnd && subscriptionEnd < now;

    if (isExpired) {
      throw new HttpException(
        {
          statusCode: HttpStatus.PAYMENT_REQUIRED,
          message: 'Your subscription has expired. Please upgrade your plan to continue.',
          message_mm: 'သင့်အစီအစဉ် သက်တမ်းကုန်ဆုံးသွားပါပြီ။ ဆက်လက်အသုံးပြုရန် အဆင့်မြှင့်ပါ။',
          error: 'Payment Required',
          subscription_status: 'expired',
          subscription_end: company.subscription_end,
        },
        HttpStatus.PAYMENT_REQUIRED,
      );
    }

    // Check if endpoint requires premium plan
    const isPremium = this.reflector.getAllAndOverride<boolean>(PREMIUM_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPremium) {
      const plan = company.subscription_plan || 'free';
      if (!PAID_PLANS.includes(plan)) {
        throw new HttpException(
          {
            statusCode: HttpStatus.PAYMENT_REQUIRED,
            message: 'This feature requires a paid plan. Please upgrade to access Payroll, Reports, and more.',
            message_mm: 'ဤလုပ်ဆောင်ချက်အတွက် အခပေးအစီအစဉ် လိုအပ်ပါသည်။ Payroll, Reports စသည်တို့ကို သုံးရန် အဆင့်မြှင့်ပါ။',
            error: 'Payment Required',
            subscription_status: 'free',
            required_plan: 'starter',
          },
          HttpStatus.PAYMENT_REQUIRED,
        );
      }
    }

    // Attach subscription info to request for downstream use
    request.subscription = {
      plan: company.subscription_plan || 'free',
      status: company.subscription_status,
      expires: company.subscription_end,
      maxEmployees: company.max_employees,
    };

    return true;
  }
}
