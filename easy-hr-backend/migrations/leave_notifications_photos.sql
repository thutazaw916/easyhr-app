-- ============================================
-- 1. Notifications Table
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES employees(id),
  type TEXT NOT NULL DEFAULT 'general',
  title TEXT NOT NULL,
  title_mm TEXT,
  body TEXT,
  body_mm TEXT,
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_company ON notifications(company_id, created_at DESC);

-- RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notifications_all" ON notifications;
CREATE POLICY "notifications_all" ON notifications FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- 2. Add attachment_url to leave_requests
-- ============================================
ALTER TABLE leave_requests ADD COLUMN IF NOT EXISTS attachment_url TEXT;

-- ============================================
-- 3. Add requires_attachment to leave_types
-- ============================================
ALTER TABLE leave_types ADD COLUMN IF NOT EXISTS requires_attachment BOOLEAN DEFAULT false;

-- Set medical & maternity leave to require attachment
UPDATE leave_types SET requires_attachment = true WHERE code IN ('ML', 'MAT');

-- ============================================
-- 4. Ensure profile_photo_url column exists on employees
-- ============================================
ALTER TABLE employees ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;
ALTER TABLE employees ADD COLUMN IF NOT EXISTS gender TEXT;

-- ============================================
-- 5. Create Supabase Storage bucket for uploads
-- ============================================
INSERT INTO storage.buckets (id, name, public) 
VALUES ('uploads', 'uploads', true) 
ON CONFLICT (id) DO NOTHING;

-- Allow public access to uploads bucket
DROP POLICY IF EXISTS "uploads_public_read" ON storage.objects;
CREATE POLICY "uploads_public_read" ON storage.objects FOR SELECT USING (bucket_id = 'uploads');

DROP POLICY IF EXISTS "uploads_insert" ON storage.objects;
CREATE POLICY "uploads_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'uploads');

DROP POLICY IF EXISTS "uploads_update" ON storage.objects;
CREATE POLICY "uploads_update" ON storage.objects FOR UPDATE USING (bucket_id = 'uploads');

DROP POLICY IF EXISTS "uploads_delete" ON storage.objects;
CREATE POLICY "uploads_delete" ON storage.objects FOR DELETE USING (bucket_id = 'uploads');
