-- ============================================
-- Easy HR - Complete Database Setup
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. SUPER ADMINS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS super_admins (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Ensure companies table has required columns
-- ============================================
DO $$ 
BEGIN
  -- Add is_suspended column if not exists
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'is_suspended') THEN
    ALTER TABLE companies ADD COLUMN is_suspended BOOLEAN DEFAULT false;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'suspended_reason') THEN
    ALTER TABLE companies ADD COLUMN suspended_reason TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_plan') THEN
    ALTER TABLE companies ADD COLUMN subscription_plan TEXT DEFAULT 'free';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_status') THEN
    ALTER TABLE companies ADD COLUMN subscription_status TEXT DEFAULT 'active';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_expires_at') THEN
    ALTER TABLE companies ADD COLUMN subscription_expires_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'max_employees') THEN
    ALTER TABLE companies ADD COLUMN max_employees INTEGER DEFAULT 9;
  END IF;
END $$;

-- 3. COMPANY DETAILS VIEW (for super admin dashboard)
-- ============================================
CREATE OR REPLACE VIEW company_details_view AS
SELECT 
  c.id,
  c.name,
  c.name_mm,
  c.email,
  c.phone,
  c.city,
  c.state_region,
  c.business_type,
  c.is_active,
  c.is_suspended,
  c.suspended_reason,
  c.subscription_plan,
  c.subscription_status,
  c.created_at,
  c.updated_at,
  COALESCE(emp.employee_count, 0) AS employee_count,
  COALESCE(emp.active_employee_count, 0) AS active_employee_count
FROM companies c
LEFT JOIN (
  SELECT 
    company_id,
    COUNT(*) AS employee_count,
    COUNT(*) FILTER (WHERE is_active = true) AS active_employee_count
  FROM employees
  GROUP BY company_id
) emp ON emp.company_id = c.id;

-- 4. PLATFORM OVERVIEW VIEW (for super admin dashboard)
-- ============================================
CREATE OR REPLACE VIEW platform_overview AS
SELECT
  (SELECT COUNT(*) FROM companies) AS total_companies,
  (SELECT COUNT(*) FROM companies WHERE is_active = true AND (is_suspended IS NULL OR is_suspended = false)) AS active_companies,
  (SELECT COUNT(*) FROM companies WHERE is_suspended = true) AS suspended_companies,
  (SELECT COUNT(*) FROM employees) AS total_employees,
  (SELECT COUNT(*) FROM employees WHERE is_active = true) AS active_employees,
  (SELECT COUNT(*) FROM attendance WHERE date = CURRENT_DATE) AS check_ins_today,
  (SELECT COUNT(*) FROM companies WHERE created_at >= CURRENT_DATE) AS new_today,
  (SELECT COUNT(*) FROM companies WHERE created_at >= date_trunc('week', CURRENT_DATE)) AS new_this_week,
  (SELECT COUNT(*) FROM companies WHERE created_at >= date_trunc('month', CURRENT_DATE)) AS new_this_month;

-- 5. OTP CODES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS otp_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  phone TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  is_used BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(phone)
);

-- 6. AUTH CREDENTIALS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS auth_credentials (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 7. SALARY STRUCTURES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS salary_structures (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  basic_salary DECIMAL(12,2) DEFAULT 0,
  transport_allowance DECIMAL(12,2) DEFAULT 0,
  meal_allowance DECIMAL(12,2) DEFAULT 0,
  phone_allowance DECIMAL(12,2) DEFAULT 0,
  housing_allowance DECIMAL(12,2) DEFAULT 0,
  other_allowance DECIMAL(12,2) DEFAULT 0,
  other_allowance_name TEXT,
  ot_rate_per_hour DECIMAL(10,2) DEFAULT 0,
  attendance_bonus DECIMAL(10,2) DEFAULT 0,
  ssb_employee_percent DECIMAL(5,2) DEFAULT 2.0,
  effective_date DATE DEFAULT CURRENT_DATE,
  is_current BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 8. SALARY ADVANCES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS salary_advances (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL,
  reason TEXT,
  installment_months INTEGER DEFAULT 1,
  monthly_deduction DECIMAL(12,2) DEFAULT 0,
  remaining_amount DECIMAL(12,2) DEFAULT 0,
  status TEXT DEFAULT 'pending',
  approved_by UUID,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 9. PAYROLL TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS payroll (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  basic_salary DECIMAL(12,2) DEFAULT 0,
  attendance_bonus DECIMAL(10,2) DEFAULT 0,
  ot_hours DECIMAL(8,2) DEFAULT 0,
  ot_amount DECIMAL(12,2) DEFAULT 0,
  bonus DECIMAL(12,2) DEFAULT 0,
  total_allowances DECIMAL(12,2) DEFAULT 0,
  gross_salary DECIMAL(12,2) DEFAULT 0,
  tax_amount DECIMAL(12,2) DEFAULT 0,
  ssb_amount DECIMAL(12,2) DEFAULT 0,
  advance_deduction DECIMAL(12,2) DEFAULT 0,
  other_deductions DECIMAL(12,2) DEFAULT 0,
  total_deductions DECIMAL(12,2) DEFAULT 0,
  net_salary DECIMAL(12,2) DEFAULT 0,
  total_working_days INTEGER DEFAULT 0,
  days_present INTEGER DEFAULT 0,
  days_absent INTEGER DEFAULT 0,
  days_late INTEGER DEFAULT 0,
  days_on_leave INTEGER DEFAULT 0,
  status TEXT DEFAULT 'calculated',
  calculated_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(employee_id, month, year)
);

-- 10. PUBLIC HOLIDAYS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public_holidays (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_mm TEXT,
  date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 11. Enable Row Level Security (Optional but recommended)
-- ============================================
-- ALTER TABLE super_admins ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE auth_credentials ENABLE ROW LEVEL SECURITY;

-- ============================================
-- DONE! Now you can use the Super Admin dashboard.
-- First, call POST /api/v1/super-admin/setup to create your super admin account.
-- ============================================

-- 12. CHATBOT MESSAGES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS chatbot_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chatbot_messages_employee ON chatbot_messages(employee_id, created_at);

-- 13. PAYMENTS TABLE (SaaS Billing)
-- ============================================
CREATE TABLE IF NOT EXISTS payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  employee_id UUID REFERENCES employees(id) ON DELETE SET NULL,
  plan TEXT NOT NULL,
  payment_method TEXT NOT NULL,
  transaction_id TEXT,
  amount NUMERIC NOT NULL,
  expected_amount NUMERIC,
  months INTEGER DEFAULT 1,
  currency TEXT DEFAULT 'MMK',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  screenshot_url TEXT,
  notes TEXT,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payments_company ON payments(company_id, created_at);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
