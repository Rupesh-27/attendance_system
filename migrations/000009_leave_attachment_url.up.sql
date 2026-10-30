-- Migration: 000009_leave_attachment_url.up.sql
-- Add attachment_url column to leave_applications table
ALTER TABLE leave_applications ADD COLUMN IF NOT EXISTS attachment_url VARCHAR(500) NULL;

