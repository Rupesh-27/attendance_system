-- Rollback: Revert mob_ prefix back to original table names.

ALTER TABLE IF EXISTS mob_offices RENAME TO offices;
ALTER TABLE IF EXISTS mob_employees RENAME TO employees;
ALTER TABLE IF EXISTS mob_attendance_sessions RENAME TO attendance_sessions;
ALTER TABLE IF EXISTS mob_attendance_events RENAME TO attendance_events;
ALTER TABLE IF EXISTS mob_system_settings RENAME TO system_settings;
ALTER TABLE IF EXISTS mob_leave_types RENAME TO leave_types;
ALTER TABLE IF EXISTS mob_leave_applications RENAME TO leave_applications;
ALTER TABLE IF EXISTS mob_employee_leave_balances RENAME TO employee_leave_balances;
ALTER TABLE IF EXISTS mob_leave_attachment_files RENAME TO leave_attachment_files;

