-- ============================================
-- EasyHR - All New Migrations (Phase 1-9)
-- Run this in Supabase SQL Editor
-- ============================================

-- ============================================
-- 1. Subscription Guard Columns (Phase 1)
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_start') THEN
    ALTER TABLE companies ADD COLUMN subscription_start TIMESTAMPTZ;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_end') THEN
    ALTER TABLE companies ADD COLUMN subscription_end TIMESTAMPTZ;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_plan') THEN
    ALTER TABLE companies ADD COLUMN subscription_plan TEXT DEFAULT 'free';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'subscription_status') THEN
    ALTER TABLE companies ADD COLUMN subscription_status TEXT DEFAULT 'active';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'companies' AND column_name = 'max_employees') THEN
    ALTER TABLE companies ADD COLUMN max_employees INTEGER DEFAULT 9;
  END IF;
END $$;

-- Backfill existing companies with 30-day trial
UPDATE companies
SET
  subscription_start = created_at,
  subscription_end = created_at + INTERVAL '30 days',
  subscription_plan = COALESCE(subscription_plan, 'free'),
  subscription_status = COALESCE(subscription_status, 'active'),
  max_employees = COALESCE(max_employees, 9)
WHERE verified = true
  AND subscription_end IS NULL;

-- ============================================
-- 2. Employee Invitations Table (Phase 5)
-- ============================================
CREATE TABLE IF NOT EXISTS employee_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  phone VARCHAR(20) NOT NULL,
  name VARCHAR(100) NOT NULL,
  role VARCHAR(30) DEFAULT 'employee',
  department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
  branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
  position_id UUID REFERENCES positions(id) ON DELETE SET NULL,
  invite_code VARCHAR(10) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_invitations_company ON employee_invitations(company_id);
CREATE INDEX IF NOT EXISTS idx_invitations_code ON employee_invitations(invite_code);
CREATE INDEX IF NOT EXISTS idx_invitations_phone ON employee_invitations(phone);

-- ============================================
-- 3. Custom Salary Components Tables (Phase 6)
-- ============================================
CREATE TABLE IF NOT EXISTS salary_components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  name_mm VARCHAR(100),
  type VARCHAR(20) NOT NULL CHECK (type IN ('earning', 'deduction')),
  category VARCHAR(30) DEFAULT 'allowance',
  is_percentage BOOLEAN DEFAULT FALSE,
  default_value NUMERIC(12,2) DEFAULT 0,
  is_taxable BOOLEAN DEFAULT TRUE,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS employee_salary_components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  component_id UUID NOT NULL REFERENCES salary_components(id) ON DELETE CASCADE,
  value NUMERIC(12,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(employee_id, component_id)
);

CREATE INDEX IF NOT EXISTS idx_salary_components_company ON salary_components(company_id);
CREATE INDEX IF NOT EXISTS idx_emp_salary_comp_employee ON employee_salary_components(employee_id);
CREATE INDEX IF NOT EXISTS idx_emp_salary_comp_component ON employee_salary_components(component_id);

-- Seed default components for existing companies
INSERT INTO salary_components (company_id, name, name_mm, type, category, is_percentage, default_value, is_taxable, sort_order)
SELECT c.id, comp.name, comp.name_mm, comp.type, comp.category, comp.is_percentage, comp.default_value, comp.is_taxable, comp.sort_order
FROM companies c
CROSS JOIN (VALUES
  ('Transport Allowance', 'သွားလာစရိတ်', 'earning', 'allowance', FALSE, 0::numeric, TRUE, 1),
  ('Meal Allowance', 'ထမင်းစရိတ်', 'earning', 'allowance', FALSE, 0::numeric, TRUE, 2),
  ('Phone Allowance', 'ဖုန်းစရိတ်', 'earning', 'allowance', FALSE, 0::numeric, TRUE, 3),
  ('Housing Allowance', 'အိမ်ခန်းစရိတ်', 'earning', 'allowance', FALSE, 0::numeric, TRUE, 4),
  ('Attendance Bonus', 'ရက်မှန်ကြေး', 'earning', 'bonus', FALSE, 0::numeric, TRUE, 5),
  ('SSB Employee', 'SSB ဝန်ထမ်း', 'deduction', 'tax', TRUE, 2.0::numeric, FALSE, 10)
) AS comp(name, name_mm, type, category, is_percentage, default_value, is_taxable, sort_order)
WHERE NOT EXISTS (
  SELECT 1 FROM salary_components sc WHERE sc.company_id = c.id AND sc.name = comp.name
);

-- ============================================
-- 4. Enable QR for existing branches
-- ============================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branches' AND column_name = 'qr_enabled') THEN
    ALTER TABLE branches ADD COLUMN qr_enabled BOOLEAN DEFAULT FALSE;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'branches' AND column_name = 'qr_code_data') THEN
    ALTER TABLE branches ADD COLUMN qr_code_data TEXT;
  END IF;
END $$;

-- ============================================
-- 5. Storage bucket for uploads (payment screenshots)
-- ============================================
-- Create 'uploads' bucket (public)
INSERT INTO storage.buckets (id, name, public)
SELECT 'uploads', 'uploads', true
WHERE NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'uploads');

-- RLS Policy: Allow authenticated users to upload files
CREATE POLICY IF NOT EXISTS "Allow authenticated uploads"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'uploads');

-- RLS Policy: Allow public read access
CREATE POLICY IF NOT EXISTS "Allow public read uploads"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'uploads');
