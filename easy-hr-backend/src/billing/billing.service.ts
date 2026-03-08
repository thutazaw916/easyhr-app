import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

// Myanmar Pricing Tiers (MMK/month)
export const PRICING_PLANS = {
  free: { name: 'free', label: 'Free', label_mm: 'အခမဲ့', price: 0, max_employees: 9, features: ['Basic HR', 'Attendance', 'Up to 9 employees'] },
  starter: { name: 'starter', label: 'Starter', label_mm: 'စတင်', price: 49000, max_employees: 49, features: ['All Free features', 'Leave Management', 'Payroll', 'Up to 49 employees'] },
  business: { name: 'business', label: 'Business', label_mm: 'စီးပွားရေး', price: 99000, max_employees: 99, features: ['All Starter features', 'AI Chatbot', 'Reports', 'Up to 99 employees'] },
  enterprise: { name: 'enterprise', label: 'Enterprise', label_mm: 'လုပ်ငန်းကြီး', price: 199000, max_employees: 9999, features: ['All Business features', 'Unlimited employees', 'Priority Support', 'Custom Integrations'] },
};

export const PAYMENT_METHODS = [
  { id: 'kbzpay', name: 'KBZPay', name_mm: 'KBZPay', icon: '💳', account: '09971489502' },
  { id: 'wavepay', name: 'WavePay', name_mm: 'WavePay', icon: '📱', account: '09971489502' },
  { id: 'kbz_bank', name: 'KBZ Bank Transfer', name_mm: 'KBZ ဘဏ်လွှဲ', icon: '�', account: '06651199910919301' },
];

@Injectable()
export class BillingService {
  constructor(private supabaseService: SupabaseService) {}

  // ============================================
  // GET PRICING PLANS
  // ============================================
  getPlans() {
    return {
      plans: Object.values(PRICING_PLANS),
      payment_methods: PAYMENT_METHODS,
      currency: 'MMK',
    };
  }

  // ============================================
  // GET CURRENT SUBSCRIPTION
  // ============================================
  async getCurrentSubscription(companyId: string) {
    const db = this.supabaseService.getClient();

    const { data: company } = await db
      .from('companies')
      .select('id, name, subscription_plan, subscription_start, subscription_end, max_employees, subscription_status, is_suspended')
      .eq('id', companyId)
      .single();

    if (!company) throw new NotFoundException('Company not found');

    // Count active employees
    const { count } = await db
      .from('employees')
      .select('*', { count: 'exact', head: true })
      .eq('company_id', companyId)
      .eq('is_active', true);

    const currentPlan = PRICING_PLANS[company.subscription_plan] || PRICING_PLANS.free;
    const daysLeft = company.subscription_end
      ? Math.max(0, Math.ceil((new Date(company.subscription_end).getTime() - Date.now()) / (1000 * 60 * 60 * 24)))
      : 0;

    return {
      company_id: company.id,
      company_name: company.name,
      current_plan: currentPlan,
      subscription_status: company.subscription_status,
      subscription_start: company.subscription_start,
      subscription_end: company.subscription_end,
      days_remaining: daysLeft,
      is_suspended: company.is_suspended,
      employee_count: count || 0,
      max_employees: company.max_employees,
      available_upgrades: this._getAvailableUpgrades(company.subscription_plan),
    };
  }

  // ============================================
  // SUBMIT PAYMENT (Company Owner/HR)
  // ============================================
  async submitPayment(companyId: string, employeeId: string, data: {
    plan: string;
    payment_method: string;
    transaction_id?: string;
    amount: number;
    months?: number;
    screenshot_url?: string;
    notes?: string;
  }) {
    const db = this.supabaseService.getClient();

    const plan = PRICING_PLANS[data.plan];
    if (!plan) throw new BadRequestException('Invalid plan');
    if (plan.price === 0) throw new BadRequestException('Free plan does not require payment');

    const months = data.months || 1;
    const expectedAmount = plan.price * months;

    // Create payment record
    const { data: payment, error } = await db
      .from('payments')
      .insert({
        company_id: companyId,
        employee_id: employeeId,
        plan: data.plan,
        payment_method: data.payment_method,
        transaction_id: data.transaction_id,
        amount: data.amount,
        expected_amount: expectedAmount,
        months,
        currency: 'MMK',
        status: 'pending',
        screenshot_url: data.screenshot_url,
        notes: data.notes,
      })
      .select()
      .single();

    if (error) throw new BadRequestException(error.message);

    return {
      message: 'Payment submitted! We will verify and activate your plan within 24 hours.',
      message_mm: 'ငွေပေးချေမှု တင်ပြီးပါပြီ! ၂၄ နာရီအတွင်း စစ်ဆေးပြီး အစီအစဉ်ကို အသက်သွင်းပေးပါမယ်။',
      payment,
    };
  }

  // ============================================
  // APPROVE PAYMENT (Super Admin)
  // ============================================
  async approvePayment(paymentId: string) {
    const db = this.supabaseService.getClient();

    const { data: payment } = await db
      .from('payments')
      .select('*')
      .eq('id', paymentId)
      .single();

    if (!payment) throw new NotFoundException('Payment not found');
    if (payment.status !== 'pending') throw new BadRequestException('Payment already processed');

    const plan = PRICING_PLANS[payment.plan];
    const months = payment.months || 1;

    // Calculate subscription dates
    const now = new Date();
    const endDate = new Date(now);
    endDate.setMonth(endDate.getMonth() + months);

    // Update payment status
    await db.from('payments')
      .update({ status: 'approved', approved_at: now.toISOString() })
      .eq('id', paymentId);

    // Upgrade company subscription
    await db.from('companies')
      .update({
        subscription_plan: payment.plan,
        subscription_status: 'active',
        subscription_start: now.toISOString().split('T')[0],
        subscription_end: endDate.toISOString().split('T')[0],
        max_employees: plan.max_employees,
        is_suspended: false,
      })
      .eq('id', payment.company_id);

    return { message: `Payment approved. Plan upgraded to ${plan.label} for ${months} month(s).` };
  }

  // ============================================
  // REJECT PAYMENT (Super Admin)
  // ============================================
  async rejectPayment(paymentId: string, reason?: string) {
    const db = this.supabaseService.getClient();

    const { error } = await db.from('payments')
      .update({ status: 'rejected', notes: reason, approved_at: new Date().toISOString() })
      .eq('id', paymentId);

    if (error) throw new BadRequestException(error.message);
    return { message: 'Payment rejected' };
  }

  // ============================================
  // PAYMENT HISTORY (Company)
  // ============================================
  async getPaymentHistory(companyId: string) {
    const db = this.supabaseService.getClient();

    const { data } = await db
      .from('payments')
      .select('*, employee:employee_id(first_name, last_name)')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false })
      .limit(50);

    return data || [];
  }

  // ============================================
  // ALL PENDING PAYMENTS (Super Admin)
  // ============================================
  async getPendingPayments() {
    const db = this.supabaseService.getClient();

    const { data } = await db
      .from('payments')
      .select('*, company:company_id(name, email), employee:employee_id(first_name, last_name)')
      .eq('status', 'pending')
      .order('created_at', { ascending: true });

    return data || [];
  }

  // ============================================
  // ALL PAYMENTS (Super Admin)
  // ============================================
  async getAllPayments(filters?: { status?: string; page?: number; limit?: number }) {
    const db = this.supabaseService.getClient();
    const page = filters?.page || 1;
    const limit = filters?.limit || 20;
    const offset = (page - 1) * limit;

    let query = db
      .from('payments')
      .select('*, company:company_id(name, email), employee:employee_id(first_name, last_name)', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (filters?.status) query = query.eq('status', filters.status);

    const { data, count, error } = await query;
    if (error) throw error;

    return {
      payments: data,
      pagination: { total: count, page, limit, total_pages: Math.ceil((count || 0) / limit) },
    };
  }

  // ============================================
  // HELPERS
  // ============================================
  private _getAvailableUpgrades(currentPlan: string): any[] {
    const planOrder = ['free', 'starter', 'business', 'enterprise'];
    const currentIndex = planOrder.indexOf(currentPlan);
    return planOrder
      .filter((_, i) => i > currentIndex)
      .map(p => PRICING_PLANS[p]);
  }
}
