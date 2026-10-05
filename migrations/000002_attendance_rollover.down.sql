-- Migration: 000002_attendance_rollover.down.sql
-- Description: Revert Daily Attendance Session Rollover

DROP INDEX IF EXISTS idx_attendance_day;

DROP INDEX IF EXISTS idx_unique_active_session_per_employee;

CREATE UNIQUE INDEX idx_unique_active_session_per_employee 
ON attendance_sessions (employee_id) 
WHERE status = 'CHECKED_IN';

ALTER TABLE attendance_sessions 
DROP CONSTRAINT IF EXISTS chk_attendance_status;

ALTER TABLE attendance_sessions 
ADD CONSTRAINT chk_attendance_status 
CHECK (status IN ('CHECKED_IN', 'COMPLETED'));

ALTER TABLE attendance_sessions 
DROP COLUMN IF EXISTS attendance_day;
