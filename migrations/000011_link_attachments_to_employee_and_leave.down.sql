DROP INDEX IF EXISTS idx_leave_attachment_files_application_id;
DROP INDEX IF EXISTS idx_leave_attachment_files_employee_id;

ALTER TABLE leave_attachment_files 
DROP COLUMN IF EXISTS leave_application_id,
DROP COLUMN IF EXISTS employee_id;

