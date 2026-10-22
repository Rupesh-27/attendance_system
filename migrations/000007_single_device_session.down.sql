DROP INDEX IF EXISTS idx_employees_active_session;

ALTER TABLE employees
DROP COLUMN IF EXISTS active_session_id;
