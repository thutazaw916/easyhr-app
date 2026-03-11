-- Employee Invitations table
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
  status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, expired
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for lookups
CREATE INDEX IF NOT EXISTS idx_invitations_company ON employee_invitations(company_id);
CREATE INDEX IF NOT EXISTS idx_invitations_code ON employee_invitations(invite_code);
CREATE INDEX IF NOT EXISTS idx_invitations_phone ON employee_invitations(phone);
