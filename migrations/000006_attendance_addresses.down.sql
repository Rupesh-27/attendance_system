-- 000006_attendance_addresses.down.sql
ALTER TABLE attendance_sessions
DROP COLUMN IF EXISTS check_in_address,
DROP COLUMN IF EXISTS check_out_address;
