-- ============================================
-- Fix Supabase RLS Security Warnings
-- Run this in Supabase SQL Editor
-- ============================================

-- Helper function to safely enable RLS and create policy
DO $$
DECLARE
  tbl TEXT;
  tables TEXT[] := ARRAY[
    'companies', 'employees', 'branches', 'departments',
    'attendance', 'leave_requests', 'leave_types', 'leave_balances',
    'announcements', 'chat_messages', 'chat_rooms',
    'invitations', 'otp_codes', 'payments',
    'platform_settings', 'email_whitelist', 'super_admins',
    'work_schedules', 'company_settings',
    'chatbot_messages', 'chatbot_conversations',
    'positions', 'payroll', 'payslips',
    'salary_components', 'salary_advances',
    'holidays', 'notifications'
  ];
BEGIN
  FOREACH tbl IN ARRAY tables
  LOOP
    -- Check if table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl) THEN
      -- Enable RLS
      EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
      -- Drop existing policy if any
      EXECUTE format('DROP POLICY IF EXISTS "service_role_all_%s" ON %I', tbl, tbl);
      -- Create service_role policy
      EXECUTE format('CREATE POLICY "service_role_all_%s" ON %I FOR ALL USING (auth.role() = ''service_role'')', tbl, tbl);
      RAISE NOTICE 'RLS enabled for table: %', tbl;
    ELSE
      RAISE NOTICE 'Table % does not exist, skipping', tbl;
    END IF;
  END LOOP;
END $$;
