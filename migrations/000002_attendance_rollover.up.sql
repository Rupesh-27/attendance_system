
ALTER TABLE attendance_sessions
ADD COLUMN IF NOT EXISTS attendance_day DATE;

UPDATE attendance_sessions
SET attendance_day = (check_in_time AT TIME ZONE 'Asia/Kolkata')::DATE
WHERE attendance_day IS NULL;

ALTER TABLE attendance_sessions
ALTER COLUMN attendance_day SET NOT NULL;

ALTER TABLE attendance_sessions
ALTER COLUMN attendance_day SET DEFAULT CURRENT_DATE;

ALTER TABLE attendance_sessions
DROP CONSTRAINT IF EXISTS chk_attendance_status;

ALTER TABLE attendance_sessions
ADD CONSTRAINT chk_attendance_status
CHECK (status IN ('CHECKED_IN', 'CARRIED_OVER', 'COMPLETED'));

DROP INDEX IF EXISTS idx_unique_active_session_per_employee;

CREATE UNIQUE INDEX idx_unique_active_session_per_employee
ON attendance_sessions (employee_id)
WHERE status IN ('CHECKED_IN', 'CARRIED_OVER');

CREATE INDEX IF NOT EXISTS idx_attendance_day
ON attendance_sessions (employee_id, attendance_day DESC);
