-- ============================================
-- Subscription & Feature Gating Setup
-- Ensures all subscription columns exist on companies table
-- Run in Supabase SQL Editor
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

-- Set 30-day trial for any verified companies missing subscription dates
UPDATE companies
SET
  subscription_start = created_at,
  subscription_end = created_at + INTERVAL '30 days',
  subscription_plan = COALESCE(subscription_plan, 'free'),
  subscription_status = COALESCE(subscription_status, 'active'),
  max_employees = COALESCE(max_employees, 9)
WHERE verified = true
  AND subscription_end IS NULL;
