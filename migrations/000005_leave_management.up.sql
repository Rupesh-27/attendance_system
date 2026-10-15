-- Migration: 000005_leave_management.up.sql
-- Create leave_types, employee_leave_balances, and leave_applications tables

-- 1. Table: leave_types
CREATE TABLE IF NOT EXISTS leave_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT NULL,
    annual_allowance INT NOT NULL DEFAULT 0,
    is_paid BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed initial standard leave types
INSERT INTO leave_types (name, code, description, annual_allowance, is_paid)
VALUES 
    ('Casual Leave', 'CL', 'For short personal matters and unforeseen urgent personal work', 12, TRUE),
    ('Sick Leave', 'SL', 'For illness, doctor visits, and medical recovery', 8, TRUE),
    ('Paid Leave', 'PL', 'Annual privilege leave for vacations and planned family events', 15, TRUE)
ON CONFLICT (code) DO NOTHING;

-- 2. Table: employee_leave_balances
CREATE TABLE IF NOT EXISTS employee_leave_balances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    leave_type_id UUID NOT NULL REFERENCES leave_types(id) ON DELETE RESTRICT,
    year INT NOT NULL,
    allocated_days NUMERIC(4, 1) NOT NULL DEFAULT 0.0,
    used_days NUMERIC(4, 1) NOT NULL DEFAULT 0.0,
    remaining_days NUMERIC(4, 1) NOT NULL DEFAULT 0.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_employee_leave_balance UNIQUE (employee_id, leave_type_id, year),
    CONSTRAINT chk_balances_positive CHECK (allocated_days >= 0 AND used_days >= 0)
);

CREATE INDEX IF NOT EXISTS idx_leave_balances_emp_year ON employee_leave_balances(employee_id, year);

-- 3. Table: leave_applications
CREATE TABLE IF NOT EXISTS leave_applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    leave_type_id UUID NOT NULL REFERENCES leave_types(id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_days NUMERIC(4, 1) NOT NULL,
    is_half_day BOOLEAN NOT NULL DEFAULT FALSE,
    half_day_session VARCHAR(20) NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    reviewed_by UUID NULL REFERENCES employees(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ NULL,
    manager_remarks TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_leave_dates CHECK (start_date <= end_date),
    CONSTRAINT chk_leave_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
    CONSTRAINT chk_half_day_session CHECK (half_day_session IS NULL OR half_day_session IN ('FIRST_HALF', 'SECOND_HALF'))
);

CREATE INDEX IF NOT EXISTS idx_leave_applications_employee ON leave_applications(employee_id);
CREATE INDEX IF NOT EXISTS idx_leave_applications_status ON leave_applications(status);
CREATE INDEX IF NOT EXISTS idx_leave_applications_dates ON leave_applications(start_date, end_date);

-- Automatically initialize current year (2026) leave balances for all existing employees
INSERT INTO employee_leave_balances (employee_id, leave_type_id, year, allocated_days, used_days, remaining_days)
SELECT 
    e.id, 
    lt.id, 
    2026, 
    lt.annual_allowance, 
    0.0, 
    lt.annual_allowance
FROM employees e
CROSS JOIN leave_types lt
WHERE lt.is_active = TRUE
ON CONFLICT (employee_id, leave_type_id, year) DO NOTHING;
