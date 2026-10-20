-- 000006_attendance_addresses.up.sql
ALTER TABLE attendance_sessions
ADD COLUMN IF NOT EXISTS check_in_address TEXT,
ADD COLUMN IF NOT EXISTS check_out_address TEXT;
