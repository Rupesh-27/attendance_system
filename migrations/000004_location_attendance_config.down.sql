-- Migration: Rollback location_attendance_enabled configuration

ALTER TABLE system_settings 
DROP COLUMN IF EXISTS location_attendance_enabled;

ALTER TABLE employees 
DROP COLUMN IF EXISTS location_attendance_enabled;
