-- Add employee_id and leave_application_id to leave_attachment_files
ALTER TABLE leave_attachment_files 
ADD COLUMN IF NOT EXISTS employee_id UUID NULL REFERENCES employees(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS leave_application_id UUID NULL REFERENCES leave_applications(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_leave_attachment_files_employee_id ON leave_attachment_files(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_attachment_files_application_id ON leave_attachment_files(leave_application_id);

