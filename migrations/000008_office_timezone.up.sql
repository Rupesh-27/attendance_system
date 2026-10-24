-- Add timezone column to offices table with default to Asia/Kolkata
ALTER TABLE offices ADD COLUMN IF NOT EXISTS timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Kolkata';
