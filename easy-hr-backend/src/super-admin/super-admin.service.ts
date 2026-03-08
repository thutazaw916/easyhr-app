import { Injectable, UnauthorizedException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SupabaseService } from '../supabase/supabase.service';
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';

// ============================================
// MYANMAR PRICING TIERS (MMK / month)
// ============================================
const PRICING_TIERS = [
  { name: 'free', label: 'Free', min: 1, max: 9, price: 0, priceLabel: 'အခမဲ့' },
  { name: 'starter', label: 'Starter', min: 10, max: 49, price: 49000, priceLabel: '49,000 ကျပ်' },
  { name: 'business', label: 'Business', min: 50, max: 99, price: 99000, priceLabel: '99,000 ကျပ်' },
  { name: 'enterprise', label: 'Enterprise', min: 100, max: 99999, price: 199000, priceLabel: '199,000 ကျပ်' },
];

function getPricingTier(employeeCount: number) {
  return PRICING_TIERS.find(t => employeeCount >= t.min && employeeCount <= t.max) || PRICING_TIERS[0];
}

@Injectable()
export class SuperAdminService {
  constructor(
    private supabaseService: SupabaseService,
    private configService: ConfigService,
  ) {}

  // ============================================
  // SUPER ADMIN LOGIN
  // ============================================
  async login(email: string, password: string) {
    const db = this.supabaseService.getClient();

    const { data: admin } = await db
      .from('super_admins')
      .select('*')
      .eq('email', email)
      .eq('is_active', true)
      .single();

    if (!admin) throw new UnauthorizedException('Invalid credentials');

    const isValid = await bcrypt.compare(password, admin.password_hash);
    if (!isValid) throw new UnauthorizedException('Invalid credentials');

    await db.from('super_admins').update({ last_login_at: new Date().toISOString() }).eq('id', admin.id);

    const token = jwt.sign(
      { id: admin.id, email: admin.email, role: 'super_admin' },
      this.configService.get('JWT_SECRET') || 'default-secret',
      { expiresIn: '7d' as const },
    );

    return {
      access_token: token,
      user: { id: admin.id, name: admin.name, email: admin.email, role: 'super_admin' },
    };
  }

  // ============================================
  // FIRST TIME SETUP
  // ============================================
  async setupSuperAdmin(data: { email: string; password: string; name: string; phone?: string }) {
    const db = this.supabaseService.getClient();

    const { count } = await db.from('super_admins').select('id', { count: 'exact' });
    if (count && count > 0) throw new UnauthorizedException('Super admin already exists. Use login.');

    const passwordHash = await bcrypt.hash(data.password, 10);

    const { data: admin, error } = await db
      .from('super_admins')
      .insert({ email: data.email, password_hash: passwordHash, name: data.name, phone: data.phone })
      .select()
      .single();

    if (error) throw error;
    return { message: 'Super Admin created! You can now login.', admin_id: admin.id };
  }

  // ============================================
  // PLATFORM OVERVIEW DASHBOARD
  // ============================================
  async getPlatformOverview() {
    const db = this.supabaseService.getClient();

    const { data: overview } = await db.from('platform_overview').select('*').single();

    // Get companies with employee counts for pricing calculation
    const { data: companies } = await db
      .from('company_details_view')
      .select('*')
      .eq('is_active', true);

    // Calculate revenue based on Myanmar pricing
    let totalMRR = 0;
    const planBreakdown = { free: 0, starter: 0, business: 0, enterprise: 0 };

    companies?.forEach((c: any) => {
      const empCount = c.employee_count || 0;
      const tier = getPricingTier(empCount);
      planBreakdown[tier.name]++;
      totalMRR += tier.price;
    });

    return {
      ...overview,
      pricing_tiers: PRICING_TIERS,
      subscription_breakdown: planBreakdown,
      total_mrr: totalMRR,
      total_mrr_formatted: `${totalMRR.toLocaleString()} MMK`,
      total_arr: totalMRR * 12,
      total_arr_formatted: `${(totalMRR * 12).toLocaleString()} MMK`,
    };
  }

  // ============================================
  // ALL COMPANIES LIST (with auto-pricing)
  // ============================================
  async getAllCompanies(filters?: {
    status?: string;
    plan?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const db = this.supabaseService.getClient();
    const page = filters?.page || 1;
    const limit = filters?.limit || 20;
    const offset = (page - 1) * limit;

    let query = db.from('company_details_view').select('*', { count: 'exact' });

    if (filters?.status === 'active') query = query.eq('is_active', true).eq('is_suspended', false);
    if (filters?.status === 'suspended') query = query.eq('is_suspended', true);
    if (filters?.status === 'inactive') query = query.eq('is_active', false);
    if (filters?.search) query = query.or(`name.ilike.%${filters.search}%,email.ilike.%${filters.search}%`);

    const { data, count, error } = await query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    // Add pricing info to each company
    const companiesWithPricing = data?.map((c: any) => {
      const tier = getPricingTier(c.employee_count || 0);
      return {
        ...c,
        pricing_tier: tier.name,
        monthly_fee: tier.price,
        monthly_fee_formatted: tier.price === 0 ? 'FREE' : `${tier.price.toLocaleString()} MMK`,
        pricing_label: tier.priceLabel,
      };
    });

    // Filter by plan if specified
    let filtered = companiesWithPricing;
    if (filters?.plan) {
      filtered = companiesWithPricing?.filter((c: any) => c.pricing_tier === filters.plan);
    }

    return {
      companies: filtered,
      pagination: { total: count, page, limit, total_pages: Math.ceil((count || 0) / limit) },
      pricing_tiers: PRICING_TIERS,
    };
  }

  // ============================================
  // COMPANY DETAIL
  // ============================================
  async getCompanyDetail(companyId: string) {
    const db = this.supabaseService.getClient();

    const { data: company } = await db.from('companies').select('*').eq('id', companyId).single();
    if (!company) throw new NotFoundException('Company not found');

    const { data: employees } = await db
      .from('employees')
      .select('id, first_name, last_name, employee_code, role, position, phone, is_active, created_at')
      .eq('company_id', companyId)
      .order('created_at', { ascending: false });

    const { data: branches } = await db.from('branches').select('id, name, city').eq('company_id', companyId);
    const { data: departments } = await db.from('departments').select('id, name').eq('company_id', companyId);

    const activeEmployees = employees?.filter((e: any) => e.is_active).length || 0;
    const tier = getPricingTier(activeEmployees);

    return {
      company,
      pricing: {
        tier: tier.name,
        employee_count: activeEmployees,
        monthly_fee: tier.price,
        monthly_fee_formatted: tier.price === 0 ? 'FREE (1-9 ဦး)' : `${tier.price.toLocaleString()} MMK/month`,
        pricing_label: tier.priceLabel,
        tier_range: `${tier.min}-${tier.max === 99999 ? '∞' : tier.max} ဦး`,
      },
      stats: {
        total_employees: employees?.length || 0,
        active_employees: activeEmployees,
        total_branches: branches?.length || 0,
        total_departments: departments?.length || 0,
      },
      employees,
      branches,
      departments,
    };
  }

  // ============================================
  // REVENUE REPORT
  // ============================================
  async getRevenueReport() {
    const db = this.supabaseService.getClient();

    const { data: companies } = await db
      .from('company_details_view')
      .select('*')
      .eq('is_active', true);

    const report = {
      pricing_tiers: PRICING_TIERS,
      breakdown: [] as any[],
      total_companies: 0,
      total_mrr: 0,
      total_arr: 0,
      companies_by_tier: [] as any[],
    };

    PRICING_TIERS.forEach(tier => {
      const tierCompanies = companies?.filter((c: any) => {
        const count = c.employee_count || 0;
        return count >= tier.min && count <= tier.max;
      }) || [];

      const tierRevenue = tierCompanies.length * tier.price;

      report.breakdown.push({
        tier: tier.name,
        label: tier.label,
        range: `${tier.min}-${tier.max === 99999 ? '∞' : tier.max} employees`,
        price: tier.price,
        price_formatted: tier.price === 0 ? 'FREE' : `${tier.price.toLocaleString()} MMK`,
        company_count: tierCompanies.length,
        monthly_revenue: tierRevenue,
        monthly_revenue_formatted: `${tierRevenue.toLocaleString()} MMK`,
        companies: tierCompanies.map((c: any) => ({
          id: c.id,
          name: c.name,
          employee_count: c.employee_count,
          city: c.city,
          created_at: c.created_at,
        })),
      });

      report.total_companies += tierCompanies.length;
      report.total_mrr += tierRevenue;
    });

    report.total_arr = report.total_mrr * 12;

    return report;
  }

  // ============================================
  // SUSPEND / UNSUSPEND
  // ============================================
  async suspendCompany(companyId: string, reason: string) {
    const db = this.supabaseService.getClient();
    const { data, error } = await db
      .from('companies')
      .update({ is_suspended: true, suspended_reason: reason })
      .eq('id', companyId)
      .select()
      .single();
    if (error) throw error;
    return { message: 'Company suspended', company: data };
  }

  async unsuspendCompany(companyId: string) {
    const db = this.supabaseService.getClient();
    const { data, error } = await db
      .from('companies')
      .update({ is_suspended: false, suspended_reason: null })
      .eq('id', companyId)
      .select()
      .single();
    if (error) throw error;
    return { message: 'Company unsuspended', company: data };
  }

  // ============================================
  // UPDATE COMPANY PLAN (Manual override)
  // ============================================
  async updateCompanyPlan(companyId: string, data: {
    subscription_plan: string;
    max_employees: number;
    subscription_expires_at?: string;
  }) {
    const db = this.supabaseService.getClient();
    const { data: updated, error } = await db
      .from('companies')
      .update({
        subscription_plan: data.subscription_plan,
        max_employees: data.max_employees,
        subscription_status: 'active',
        subscription_expires_at: data.subscription_expires_at,
      })
      .eq('id', companyId)
      .select()
      .single();
    if (error) throw error;
    return { message: 'Plan updated', company: updated };
  }

  // ============================================
  // DELETE COMPANY (Soft)
  // ============================================
  async deleteCompany(companyId: string) {
    const db = this.supabaseService.getClient();
    const { error } = await db.from('companies').update({ is_active: false }).eq('id', companyId);
    if (error) throw error;
    return { message: 'Company deactivated' };
  }

  // ============================================
  // GROWTH ANALYTICS
  // ============================================
  async getGrowthAnalytics(period: string = '30d') {
    const db = this.supabaseService.getClient();

    let days = 30;
    if (period === '7d') days = 7;
    if (period === '90d') days = 90;
    if (period === '365d') days = 365;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const { data: signups } = await db
      .from('companies')
      .select('created_at')
      .gte('created_at', startDate.toISOString())
      .order('created_at');

    const signupsByDate = {};
    signups?.forEach((c: any) => {
      const date = c.created_at.split('T')[0];
      signupsByDate[date] = (signupsByDate[date] || 0) + 1;
    });

    const { data: types } = await db.from('companies').select('business_type').eq('is_active', true);
    const typeBreakdown = {};
    types?.forEach((c: any) => { typeBreakdown[c.business_type || 'other'] = (typeBreakdown[c.business_type || 'other'] || 0) + 1; });

    const { data: regions } = await db.from('companies').select('state_region').eq('is_active', true);
    const regionBreakdown = {};
    regions?.forEach((c: any) => { regionBreakdown[c.state_region || 'Unknown'] = (regionBreakdown[c.state_region || 'Unknown'] || 0) + 1; });

    return { period, company_signups: signupsByDate, business_type_breakdown: typeBreakdown, region_breakdown: regionBreakdown };
  }
}