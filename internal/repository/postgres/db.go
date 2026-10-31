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

	// Idempotently ensure attachment tables and columns are present
	initCtx, initCancel := context.WithTimeout(ctx, 5*time.Second)
	defer initCancel()
	_, _ = pool.Exec(initCtx, `
		ALTER TABLE leave_applications ADD COLUMN IF NOT EXISTS attachment_url VARCHAR(500) NULL;
		CREATE TABLE IF NOT EXISTS leave_attachment_files (
			id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
			file_name VARCHAR(255) NOT NULL,
			content_type VARCHAR(100) NOT NULL,
			file_size INT NOT NULL,
			file_data BYTEA NOT NULL,
			created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		);
		ALTER TABLE leave_attachment_files ADD COLUMN IF NOT EXISTS employee_id UUID NULL REFERENCES employees(id) ON DELETE CASCADE;
		ALTER TABLE leave_attachment_files ADD COLUMN IF NOT EXISTS leave_application_id UUID NULL REFERENCES leave_applications(id) ON DELETE SET NULL;
		CREATE INDEX IF NOT EXISTS idx_leave_attachment_files_created_at ON leave_attachment_files(created_at);
		CREATE INDEX IF NOT EXISTS idx_leave_attachment_files_employee_id ON leave_attachment_files(employee_id);
		CREATE INDEX IF NOT EXISTS idx_leave_attachment_files_application_id ON leave_attachment_files(leave_application_id);
	`)

	return &DB{Pool: pool}, nil
}

func (db *DB) Close() {
	if db.Pool != nil {
		db.Pool.Close()
	}
}
