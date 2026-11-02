-- Add device_id, device_model, and device_bound_at to mob_employees table for strict HR device binding
ALTER TABLE mob_employees 
ADD COLUMN IF NOT EXISTS device_id VARCHAR(150) NULL,
ADD COLUMN IF NOT EXISTS device_model VARCHAR(150) NULL,
ADD COLUMN IF NOT EXISTS device_bound_at TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS idx_mob_employees_device_id ON mob_employees(device_id);

