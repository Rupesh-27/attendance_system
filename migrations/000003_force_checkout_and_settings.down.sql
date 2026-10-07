DROP TABLE IF EXISTS system_settings;

ALTER TABLE attendance_sessions
DROP COLUMN IF EXISTS initial_out_of_radius_at;

ALTER TABLE attendance_sessions
DROP COLUMN IF EXISTS checkout_reason;
