-- Migration: Rename existing application tables to use mob_ prefix
-- to avoid collision with enterprise HRMS portal schema tables.

ALTER TABLE IF EXISTS offices RENAME TO mob_offices;
ALTER TABLE IF EXISTS employees RENAME TO mob_employees;
ALTER TABLE IF EXISTS attendance_sessions RENAME TO mob_attendance_sessions;
ALTER TABLE IF EXISTS attendance_events RENAME TO mob_attendance_events;
ALTER TABLE IF EXISTS system_settings RENAME TO mob_system_settings;
ALTER TABLE IF EXISTS leave_types RENAME TO mob_leave_types;
ALTER TABLE IF EXISTS leave_applications RENAME TO mob_leave_applications;
ALTER TABLE IF EXISTS employee_leave_balances RENAME TO mob_employee_leave_balances;
ALTER TABLE IF EXISTS leave_attachment_files RENAME TO mob_leave_attachment_files;

