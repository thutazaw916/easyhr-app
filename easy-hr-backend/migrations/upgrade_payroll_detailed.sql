-- Upgrade payroll table with individual earning/deduction breakdowns
-- Like Yoma Bank and other professional payslips

-- =============================================
-- INDIVIDUAL EARNINGS COLUMNS
-- =============================================
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS transport_allowance NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS meal_allowance NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS phone_allowance NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS housing_allowance NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS position_allowance NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS other_allowance NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS performance_bonus NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS incentive NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS commission NUMERIC DEFAULT 0;

-- Ensure these exist (may already exist)
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS bonus NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS bonus_description TEXT;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS other_earnings NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS other_earnings_description TEXT;

-- =============================================
-- INDIVIDUAL DEDUCTIONS COLUMNS
-- =============================================
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS late_deduction NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS absent_deduction NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS unpaid_leave_deduction NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS loan_deduction NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS insurance_deduction NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS uniform_deduction NUMERIC DEFAULT 0;

-- Ensure these exist
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS other_deductions NUMERIC DEFAULT 0;
ALTER TABLE payroll ADD COLUMN IF NOT EXISTS other_deductions_description TEXT;

-- =============================================
-- SALARY STRUCTURE: add position_allowance, performance_bonus, incentive, commission
-- =============================================
ALTER TABLE salary_structures ADD COLUMN IF NOT EXISTS position_allowance NUMERIC DEFAULT 0;
ALTER TABLE salary_structures ADD COLUMN IF NOT EXISTS performance_bonus NUMERIC DEFAULT 0;
ALTER TABLE salary_structures ADD COLUMN IF NOT EXISTS incentive NUMERIC DEFAULT 0;
ALTER TABLE salary_structures ADD COLUMN IF NOT EXISTS commission NUMERIC DEFAULT 0;
ALTER TABLE salary_structures ADD COLUMN IF NOT EXISTS late_deduction_per_day NUMERIC DEFAULT 0;
