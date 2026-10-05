-- Migration: 000002_attendance_rollover.up.sql
-- Description: Implement Daily Attendance Session Rollover (Overnight Shift Support)

-- 1. Add attendance_day column to track which shift/attendance date this session belongs to
ALTER TABLE attendance_sessions 
ADD COLUMN IF NOT EXISTS attendance_day DATE;

-- 2. Backfill existing records with the check-in date in Indian Standard Time (Asia/Kolkata)
UPDATE attendance_sessions 
SET attendance_day = (check_in_time AT TIME ZONE 'Asia/Kolkata')::DATE 
WHERE attendance_day IS NULL;

-- 3. Enforce NOT NULL and default to CURRENT_DATE
ALTER TABLE attendance_sessions 
ALTER COLUMN attendance_day SET NOT NULL;

ALTER TABLE attendance_sessions 
ALTER COLUMN attendance_day SET DEFAULT CURRENT_DATE;

-- 4. Update status check constraint to include 'CARRIED_OVER'
ALTER TABLE attendance_sessions 
DROP CONSTRAINT IF EXISTS chk_attendance_status;

ALTER TABLE attendance_sessions 
ADD CONSTRAINT chk_attendance_status 
CHECK (status IN ('CHECKED_IN', 'CARRIED_OVER', 'COMPLETED'));

-- 5. Update unique active session index to prevent multiple concurrent open sessions
-- (An employee can have at most ONE open session across both CHECKED_IN and CARRIED_OVER)
DROP INDEX IF EXISTS idx_unique_active_session_per_employee;

CREATE UNIQUE INDEX idx_unique_active_session_per_employee 
ON attendance_sessions (employee_id) 
WHERE status IN ('CHECKED_IN', 'CARRIED_OVER');

-- 6. Add index for querying sessions by attendance_day
CREATE INDEX IF NOT EXISTS idx_attendance_day 
ON attendance_sessions (employee_id, attendance_day DESC);
