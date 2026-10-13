-- Migration: Add location_attendance_enabled configuration to system_settings and employees

ALTER TABLE system_settings 
ADD COLUMN IF NOT EXISTS location_attendance_enabled BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE employees 
ADD COLUMN IF NOT EXISTS location_attendance_enabled BOOLEAN NOT NULL DEFAULT TRUE;
