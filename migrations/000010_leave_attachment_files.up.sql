-- Migration: 000010_leave_attachment_files.up.sql
-- Create leave_attachment_files table to store file attachments directly in PostgreSQL as binary data
CREATE TABLE IF NOT EXISTS leave_attachment_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_name VARCHAR(255) NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    file_size INT NOT NULL,
    file_data BYTEA NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_leave_attachment_files_created_at ON leave_attachment_files(created_at);

