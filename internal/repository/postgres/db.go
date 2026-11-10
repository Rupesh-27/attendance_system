package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DB struct {
	Pool *pgxpool.Pool
}

func NewDB(ctx context.Context, connString string) (*DB, error) {
	config, err := pgxpool.ParseConfig(connString)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database configuration: %w", err)
	}

	config.MaxConns = 25
	config.MinConns = 5
	config.MaxConnLifetime = 1 * time.Hour
	config.MaxConnIdleTime = 30 * time.Minute
	config.HealthCheckPeriod = 1 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("failed to create connection pool: %w", err)
	}

	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("database ping failed: %w", err)
	}

	// Idempotently ensure tables are renamed with mob_ prefix and attachment tables are present
	initCtx, initCancel := context.WithTimeout(ctx, 10*time.Second)
	defer initCancel()
	_, _ = pool.Exec(initCtx, `
		ALTER TABLE IF EXISTS offices RENAME TO mob_offices;
		ALTER TABLE IF EXISTS employees RENAME TO mob_employees;
		ALTER TABLE IF EXISTS attendance_sessions RENAME TO mob_attendance_sessions;
		ALTER TABLE IF EXISTS attendance_events RENAME TO mob_attendance_events;
		ALTER TABLE IF EXISTS system_settings RENAME TO mob_system_settings;
		ALTER TABLE IF EXISTS leave_types RENAME TO mob_leave_types;
		ALTER TABLE IF EXISTS leave_applications RENAME TO mob_leave_applications;
		ALTER TABLE IF EXISTS employee_leave_balances RENAME TO mob_employee_leave_balances;
		ALTER TABLE IF EXISTS leave_attachment_files RENAME TO mob_leave_attachment_files;

		ALTER TABLE IF EXISTS mob_leave_applications ADD COLUMN IF NOT EXISTS attachment_url VARCHAR(500) NULL;
		ALTER TABLE IF EXISTS mob_leave_applications ALTER COLUMN attachment_url TYPE TEXT;
		CREATE TABLE IF NOT EXISTS mob_leave_attachment_files (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			file_name VARCHAR(255) NOT NULL,
			content_type VARCHAR(100) NOT NULL,
			file_size INT NOT NULL,
			file_data BYTEA NOT NULL,
			created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		);
		ALTER TABLE mob_leave_attachment_files ADD COLUMN IF NOT EXISTS employee_id UUID NULL REFERENCES mob_employees(id) ON DELETE CASCADE;
		ALTER TABLE mob_leave_attachment_files ADD COLUMN IF NOT EXISTS leave_application_id UUID NULL REFERENCES mob_leave_applications(id) ON DELETE SET NULL;
		CREATE INDEX IF NOT EXISTS idx_mob_leave_attachment_files_created_at ON mob_leave_attachment_files(created_at);
		CREATE INDEX IF NOT EXISTS idx_mob_leave_attachment_files_employee_id ON mob_leave_attachment_files(employee_id);
		CREATE INDEX IF NOT EXISTS idx_mob_leave_attachment_files_application_id ON mob_leave_attachment_files(leave_application_id);
	`)

	return &DB{Pool: pool}, nil
}

func (db *DB) Close() {
	if db.Pool != nil {
		db.Pool.Close()
	}
}
