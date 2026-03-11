-- Custom Salary Components per company
CREATE TABLE IF NOT EXISTS salary_components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  name_mm VARCHAR(100),
  type VARCHAR(20) NOT NULL CHECK (type IN ('earning', 'deduction')),
  category VARCHAR(30) DEFAULT 'allowance', -- allowance, bonus, deduction, tax
  is_percentage BOOLEAN DEFAULT FALSE, -- true = % of basic, false = fixed amount
  default_value NUMERIC(12,2) DEFAULT 0,
  is_taxable BOOLEAN DEFAULT TRUE,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Employee-level component values (overrides company default)
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
  ('Transport Allowance', 'သွားလာစရိတ်', 'earning', 'allowance', FALSE, 0, TRUE, 1),
  ('Meal Allowance', 'ထမင်းစရိတ်', 'earning', 'allowance', FALSE, 0, TRUE, 2),
  ('Phone Allowance', 'ဖုန်းစရိတ်', 'earning', 'allowance', FALSE, 0, TRUE, 3),
  ('Housing Allowance', 'အိမ်ခန်းစရိတ်', 'earning', 'allowance', FALSE, 0, TRUE, 4),
  ('Attendance Bonus', 'ရက်မှန်ကြေး', 'earning', 'bonus', FALSE, 0, TRUE, 5),
  ('SSB Employee', 'SSB ဝန်ထမ်း', 'deduction', 'tax', TRUE, 2.0, FALSE, 10)
) AS comp(name, name_mm, type, category, is_percentage, default_value, is_taxable, sort_order)
WHERE NOT EXISTS (
  SELECT 1 FROM salary_components sc WHERE sc.company_id = c.id AND sc.name = comp.name
);
