-- Migration: 000009_leave_attachment_url.down.sql
-- Remove attachment_url column from leave_applications table
ALTER TABLE leave_applications DROP COLUMN IF EXISTS attachment_url;

