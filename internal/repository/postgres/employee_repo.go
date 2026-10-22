package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type employeeRepo struct {
	db *DB
}

func NewEmployeeRepository(db *DB) repository.EmployeeRepository {
	return &employeeRepo{db: db}
}

func (r *employeeRepo) GetByID(ctx context.Context, id uuid.UUID) (*domain.Employee, error) {
	query := `
		SELECT id, employee_code, password_hash, full_name, role, office_id, is_active, created_at, updated_at, COALESCE(email, ''), COALESCE(location_attendance_enabled, TRUE), active_session_id
		FROM employees
		WHERE id = $1
	`
	var emp domain.Employee
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(
		&emp.ID,
		&emp.EmployeeCode,
		&emp.PasswordHash,
		&emp.FullName,
		&emp.Role,
		&emp.OfficeID,
		&emp.IsActive,
		&emp.CreatedAt,
		&emp.UpdatedAt,
		&emp.Email,
		&emp.LocationAttendanceEnabled,
		&emp.ActiveSessionID,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrEmployeeNotFound
		}
		return nil, err
	}

	return &emp, nil
}

func (r *employeeRepo) GetByCode(ctx context.Context, codeOrEmail string) (*domain.Employee, error) {
	query := `
		SELECT id, employee_code, password_hash, full_name, role, office_id, is_active, created_at, updated_at, COALESCE(email, ''), COALESCE(location_attendance_enabled, TRUE), active_session_id
		FROM employees
		WHERE employee_code = $1 OR email = $1
	`
	var emp domain.Employee
	err := r.db.Pool.QueryRow(ctx, query, codeOrEmail).Scan(
		&emp.ID,
		&emp.EmployeeCode,
		&emp.PasswordHash,
		&emp.FullName,
		&emp.Role,
		&emp.OfficeID,
		&emp.IsActive,
		&emp.CreatedAt,
		&emp.UpdatedAt,
		&emp.Email,
		&emp.LocationAttendanceEnabled,
		&emp.ActiveSessionID,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrEmployeeNotFound
		}
		return nil, err
	}

	return &emp, nil
}

func (r *employeeRepo) UpdateActiveSessionID(ctx context.Context, id uuid.UUID, sessionID *uuid.UUID) error {
	query := `
		UPDATE employees
		SET active_session_id = $2, updated_at = NOW()
		WHERE id = $1
	`
	_, err := r.db.Pool.Exec(ctx, query, id, sessionID)
	return err
}
