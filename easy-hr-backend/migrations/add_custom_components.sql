-- Add custom_components JSONB column to salary_structures
ALTER TABLE salary_structures 
ADD COLUMN IF NOT EXISTS custom_components JSONB DEFAULT '[]'::jsonb;
