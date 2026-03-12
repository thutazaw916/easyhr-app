-- ============================================
-- Employee PIN Login + Device Binding Security
-- ============================================

-- Add login_pin column (6-digit PIN set by admin)
ALTER TABLE employees ADD COLUMN IF NOT EXISTS login_pin TEXT;

-- Add device binding columns
ALTER TABLE employees ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS device_name TEXT;

-- Index for quick lookup by phone + pin
CREATE INDEX IF NOT EXISTS idx_employees_phone_pin ON employees(phone, login_pin);

-- Generate default 6-digit PINs for existing employees who don't have one
UPDATE employees 
SET login_pin = LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0')
WHERE login_pin IS NULL AND is_active = true;
