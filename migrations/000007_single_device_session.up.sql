-- Add active_session_id to employees table to enforce single-device active session lock
ALTER TABLE employees
ADD COLUMN IF NOT EXISTS active_session_id UUID NULL;

CREATE INDEX IF NOT EXISTS idx_employees_active_session ON employees(active_session_id);
