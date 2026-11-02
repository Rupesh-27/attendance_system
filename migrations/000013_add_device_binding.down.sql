DROP INDEX IF EXISTS idx_mob_employees_device_id;

ALTER TABLE mob_employees 
DROP COLUMN IF EXISTS device_bound_at,
DROP COLUMN IF EXISTS device_model,
DROP COLUMN IF EXISTS device_id;

