-- Migration: 000001_init_schema.up.sql
-- Standalone Location-Based Attendance System

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Offices Table
CREATE TABLE IF NOT EXISTS offices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meters DOUBLE PRECISION NOT NULL DEFAULT 10.0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_office_latitude CHECK (latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_office_longitude CHECK (longitude BETWEEN -180 AND 180),
    CONSTRAINT chk_office_radius CHECK (radius_meters > 0)
);

-- 2. Employees Table
CREATE TABLE IF NOT EXISTS employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_code VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NULL UNIQUE,
    role VARCHAR(20) NOT NULL DEFAULT 'EMPLOYEE',
    office_id UUID NOT NULL REFERENCES offices(id) ON DELETE RESTRICT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_employee_role CHECK (role = 'EMPLOYEE')
);

CREATE INDEX IF NOT EXISTS idx_employees_code ON employees(employee_code);
CREATE INDEX IF NOT EXISTS idx_employees_office ON employees(office_id);

-- 3. Attendance Sessions Table
CREATE TABLE IF NOT EXISTS attendance_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    office_id UUID NOT NULL REFERENCES offices(id) ON DELETE RESTRICT,
    
    -- Office Decision Snapshot at Check-In
    office_snapshot_name VARCHAR(100) NOT NULL,
    office_snapshot_lat DOUBLE PRECISION NOT NULL,
    office_snapshot_lon DOUBLE PRECISION NOT NULL,
    office_snapshot_radius DOUBLE PRECISION NOT NULL,

    -- Check-In Details
    check_in_time TIMESTAMPTZ NOT NULL,
    check_in_latitude DOUBLE PRECISION NOT NULL,
    check_in_longitude DOUBLE PRECISION NOT NULL,
    check_in_accuracy_meters DOUBLE PRECISION NOT NULL,
    check_in_captured_at TIMESTAMPTZ NOT NULL,
    check_in_distance_meters DOUBLE PRECISION NOT NULL,

    -- Check-Out Details (NULL until checked out)
    check_out_time TIMESTAMPTZ NULL,
    check_out_latitude DOUBLE PRECISION NULL,
    check_out_longitude DOUBLE PRECISION NULL,
    check_out_accuracy_meters DOUBLE PRECISION NULL,
    check_out_captured_at TIMESTAMPTZ NULL,
    check_out_distance_meters DOUBLE PRECISION NULL,

    -- Duration & Status
    duration_seconds BIGINT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'CHECKED_IN',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_attendance_status CHECK (status IN ('CHECKED_IN', 'COMPLETED')),
    CONSTRAINT chk_duration_non_negative CHECK (duration_seconds IS NULL OR duration_seconds >= 0)
);

-- CRITICAL: Concurrency & State Invariant
-- Ensures an employee can have at most ONE active 'CHECKED_IN' session at any given time.
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_session_per_employee 
ON attendance_sessions (employee_id) 
WHERE status = 'CHECKED_IN';

-- Index for fetching employee attendance history ordered by check_in_time
CREATE INDEX IF NOT EXISTS idx_attendance_employee_history 
ON attendance_sessions (employee_id, check_in_time DESC);
