-- Enable QR codes for all existing branches that don't have one yet
-- Run this in Supabase SQL Editor

UPDATE branches
SET 
  qr_code_enabled = true,
  qr_secret_key = 'EHR-' || substr(md5(random()::text), 1, 12) || substr(md5(clock_timestamp()::text), 1, 6)
WHERE qr_code_enabled IS NOT TRUE
   OR qr_secret_key IS NULL;

-- Also create a default "Head Office" branch for companies that have no branches
INSERT INTO branches (company_id, name, name_mm, is_active, qr_code_enabled, qr_secret_key)
SELECT 
  c.id,
  'Head Office',
  'ရုံးချုပ်',
  true,
  true,
  'EHR-' || substr(md5(random()::text), 1, 12) || substr(md5(clock_timestamp()::text), 1, 6)
FROM companies c
WHERE c.verified = true
  AND NOT EXISTS (SELECT 1 FROM branches b WHERE b.company_id = c.id);
