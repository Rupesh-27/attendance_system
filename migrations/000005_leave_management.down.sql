-- Migration: 000005_leave_management.down.sql
-- Rollback leave management tables

DROP TABLE IF EXISTS leave_applications;
DROP TABLE IF EXISTS employee_leave_balances;
DROP TABLE IF EXISTS leave_types;
