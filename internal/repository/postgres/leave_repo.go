package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type leaveRepository struct {
	db *DB
}

func NewLeaveRepository(db *DB) repository.LeaveRepository {
	return &leaveRepository{db: db}
}

func (r *leaveRepository) GetLeaveTypes(ctx context.Context) ([]*domain.LeaveType, error) {
	query := `
		SELECT id, name, code, description, annual_allowance, is_paid, is_active, created_at, updated_at
		FROM leave_types
		WHERE is_active = TRUE
		ORDER BY name ASC
	`
	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch leave types: %w", err)
	}
	defer rows.Close()

	var types []*domain.LeaveType
	for rows.Next() {
		lt := &domain.LeaveType{}
		var desc *string
		if err := rows.Scan(&lt.ID, &lt.Name, &lt.Code, &desc, &lt.AnnualAllowance, &lt.IsPaid, &lt.IsActive, &lt.CreatedAt, &lt.UpdatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan leave type: %w", err)
		}
		if desc != nil {
			lt.Description = *desc
		}
		types = append(types, lt)
	}
	return types, nil
}

func (r *leaveRepository) GetLeaveTypeByID(ctx context.Context, id uuid.UUID) (*domain.LeaveType, error) {
	query := `
		SELECT id, name, code, description, annual_allowance, is_paid, is_active, created_at, updated_at
		FROM leave_types
		WHERE id = $1
	`
	lt := &domain.LeaveType{}
	var desc *string
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(
		&lt.ID, &lt.Name, &lt.Code, &desc, &lt.AnnualAllowance, &lt.IsPaid, &lt.IsActive, &lt.CreatedAt, &lt.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrLeaveTypeNotFound
		}
		return nil, fmt.Errorf("failed to fetch leave type by id: %w", err)
	}
	if desc != nil {
		lt.Description = *desc
	}
	return lt, nil
}

func (r *leaveRepository) GetLeaveBalances(ctx context.Context, employeeID uuid.UUID, year int) ([]*domain.EmployeeLeaveBalance, error) {
	query := `
		SELECT b.id, b.employee_id, b.leave_type_id, lt.name, lt.code, b.year, 
		       b.allocated_days, b.used_days, b.remaining_days, b.created_at, b.updated_at
		FROM employee_leave_balances b
		JOIN leave_types lt ON lt.id = b.leave_type_id
		WHERE b.employee_id = $1 AND b.year = $2
		ORDER BY lt.name ASC
	`
	rows, err := r.db.Pool.Query(ctx, query, employeeID, year)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch leave balances: %w", err)
	}
	defer rows.Close()

	var balances []*domain.EmployeeLeaveBalance
	for rows.Next() {
		b := &domain.EmployeeLeaveBalance{}
		if err := rows.Scan(&b.ID, &b.EmployeeID, &b.LeaveTypeID, &b.LeaveTypeName, &b.LeaveTypeCode,
			&b.Year, &b.AllocatedDays, &b.UsedDays, &b.RemainingDays, &b.CreatedAt, &b.UpdatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan leave balance: %w", err)
		}
		balances = append(balances, b)
	}
	return balances, nil
}

func (r *leaveRepository) GetLeaveBalance(ctx context.Context, employeeID, leaveTypeID uuid.UUID, year int) (*domain.EmployeeLeaveBalance, error) {
	query := `
		SELECT b.id, b.employee_id, b.leave_type_id, lt.name, lt.code, b.year, 
		       b.allocated_days, b.used_days, b.remaining_days, b.created_at, b.updated_at
		FROM employee_leave_balances b
		JOIN leave_types lt ON lt.id = b.leave_type_id
		WHERE b.employee_id = $1 AND b.leave_type_id = $2 AND b.year = $3
	`
	b := &domain.EmployeeLeaveBalance{}
	err := r.db.Pool.QueryRow(ctx, query, employeeID, leaveTypeID, year).Scan(
		&b.ID, &b.EmployeeID, &b.LeaveTypeID, &b.LeaveTypeName, &b.LeaveTypeCode,
		&b.Year, &b.AllocatedDays, &b.UsedDays, &b.RemainingDays, &b.CreatedAt, &b.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrLeaveTypeNotFound
		}
		return nil, fmt.Errorf("failed to fetch employee leave balance: %w", err)
	}
	return b, nil
}

func (r *leaveRepository) CreateApplication(ctx context.Context, app *domain.LeaveApplication) error {
	query := `
		INSERT INTO leave_applications (
			id, employee_id, leave_type_id, start_date, end_date, total_days,
			is_half_day, half_day_session, reason, applying_to, cc, attachment_url, status, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
	`
	var sessionVal *string
	if app.HalfDaySession != nil {
		s := string(*app.HalfDaySession)
		sessionVal = &s
	}

	applyingTo := "Mathumitha"
	if app.ApplyingTo != nil && *app.ApplyingTo != "" {
		applyingTo = *app.ApplyingTo
	}

	_, err := r.db.Pool.Exec(ctx, query,
		app.ID, app.EmployeeID, app.LeaveTypeID, app.StartDate, app.EndDate, app.TotalDays,
		app.IsHalfDay, sessionVal, app.Reason, applyingTo, app.CC, app.AttachmentURL, string(app.Status), app.CreatedAt, app.UpdatedAt,
	)
	if err != nil {
		return fmt.Errorf("failed to create leave application: %w", err)
	}
	return nil
}

func (r *leaveRepository) GetApplicationByID(ctx context.Context, id uuid.UUID) (*domain.LeaveApplication, error) {
	query := `
		SELECT a.id, a.employee_id, e.full_name, e.employee_code, a.leave_type_id, lt.name, lt.code,
		       a.start_date, a.end_date, a.total_days, a.is_half_day, a.half_day_session,
		       a.reason, a.attachment_url, a.applying_to, a.cc, a.status, a.reviewed_by, rev.full_name, a.reviewed_at, a.manager_remarks,
		       a.created_at, a.updated_at
		FROM leave_applications a
		JOIN employees e ON e.id = a.employee_id
		JOIN leave_types lt ON lt.id = a.leave_type_id
		LEFT JOIN employees rev ON rev.id = a.reviewed_by
		WHERE a.id = $1
	`
	app := &domain.LeaveApplication{}
	var halfDaySession, reviewedByName, managerRemarks *string
	var statusStr string

	err := r.db.Pool.QueryRow(ctx, query, id).Scan(
		&app.ID, &app.EmployeeID, &app.EmployeeName, &app.EmployeeCode, &app.LeaveTypeID, &app.LeaveTypeName, &app.LeaveTypeCode,
		&app.StartDate, &app.EndDate, &app.TotalDays, &app.IsHalfDay, &halfDaySession,
		&app.Reason, &app.AttachmentURL, &app.ApplyingTo, &app.CC, &statusStr, &app.ReviewedBy, &reviewedByName, &app.ReviewedAt, &managerRemarks,
		&app.CreatedAt, &app.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrLeaveApplicationNotFound
		}
		return nil, fmt.Errorf("failed to fetch leave application by id: %w", err)
	}

	app.Status = domain.LeaveStatus(statusStr)
	if halfDaySession != nil {
		h := domain.HalfDaySession(*halfDaySession)
		app.HalfDaySession = &h
	}
	if reviewedByName != nil {
		app.ReviewedByName = *reviewedByName
	}
	app.ManagerRemarks = managerRemarks

	return app, nil
}

func (r *leaveRepository) GetApplicationsByEmployee(ctx context.Context, employeeID uuid.UUID, status *domain.LeaveStatus) ([]*domain.LeaveApplication, error) {
	query := `
		SELECT a.id, a.employee_id, e.full_name, e.employee_code, a.leave_type_id, lt.name, lt.code,
		       a.start_date, a.end_date, a.total_days, a.is_half_day, a.half_day_session,
		       a.reason, a.attachment_url, a.applying_to, a.cc, a.status, a.reviewed_by, rev.full_name, a.reviewed_at, a.manager_remarks,
		       a.created_at, a.updated_at
		FROM leave_applications a
		JOIN employees e ON e.id = a.employee_id
		JOIN leave_types lt ON lt.id = a.leave_type_id
		LEFT JOIN employees rev ON rev.id = a.reviewed_by
		WHERE a.employee_id = $1
	`
	args := []interface{}{employeeID}
	if status != nil {
		query += " AND a.status = $2"
		args = append(args, string(*status))
	}
	query += " ORDER BY a.created_at DESC"

	rows, err := r.db.Pool.Query(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch employee applications: %w", err)
	}
	defer rows.Close()

	var apps []*domain.LeaveApplication
	for rows.Next() {
		app := &domain.LeaveApplication{}
		var halfDaySession, reviewedByName, managerRemarks *string
		var statusStr string

		if err := rows.Scan(
			&app.ID, &app.EmployeeID, &app.EmployeeName, &app.EmployeeCode, &app.LeaveTypeID, &app.LeaveTypeName, &app.LeaveTypeCode,
			&app.StartDate, &app.EndDate, &app.TotalDays, &app.IsHalfDay, &halfDaySession,
			&app.Reason, &app.AttachmentURL, &app.ApplyingTo, &app.CC, &statusStr, &app.ReviewedBy, &reviewedByName, &app.ReviewedAt, &managerRemarks,
			&app.CreatedAt, &app.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan application: %w", err)
		}

		app.Status = domain.LeaveStatus(statusStr)
		if halfDaySession != nil {
			h := domain.HalfDaySession(*halfDaySession)
			app.HalfDaySession = &h
		}
		if reviewedByName != nil {
			app.ReviewedByName = *reviewedByName
		}
		app.ManagerRemarks = managerRemarks
		apps = append(apps, app)
	}
	return apps, nil
}

func (r *leaveRepository) GetPendingApplications(ctx context.Context) ([]*domain.LeaveApplication, error) {
	query := `
		SELECT a.id, a.employee_id, e.full_name, e.employee_code, a.leave_type_id, lt.name, lt.code,
		       a.start_date, a.end_date, a.total_days, a.is_half_day, a.half_day_session,
		       a.reason, a.attachment_url, a.applying_to, a.cc, a.status, a.reviewed_by, rev.full_name, a.reviewed_at, a.manager_remarks,
		       a.created_at, a.updated_at
		FROM leave_applications a
		JOIN employees e ON e.id = a.employee_id
		JOIN leave_types lt ON lt.id = a.leave_type_id
		LEFT JOIN employees rev ON rev.id = a.reviewed_by
		WHERE a.status = 'PENDING'
		ORDER BY a.created_at ASC
	`
	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch pending applications: %w", err)
	}
	defer rows.Close()

	var apps []*domain.LeaveApplication
	for rows.Next() {
		app := &domain.LeaveApplication{}
		var halfDaySession, reviewedByName, managerRemarks *string
		var statusStr string

		if err := rows.Scan(
			&app.ID, &app.EmployeeID, &app.EmployeeName, &app.EmployeeCode, &app.LeaveTypeID, &app.LeaveTypeName, &app.LeaveTypeCode,
			&app.StartDate, &app.EndDate, &app.TotalDays, &app.IsHalfDay, &halfDaySession,
			&app.Reason, &app.AttachmentURL, &app.ApplyingTo, &app.CC, &statusStr, &app.ReviewedBy, &reviewedByName, &app.ReviewedAt, &managerRemarks,
			&app.CreatedAt, &app.UpdatedAt,
		); err != nil {
			return nil, fmt.Errorf("failed to scan pending application: %w", err)
		}

		app.Status = domain.LeaveStatus(statusStr)
		if halfDaySession != nil {
			h := domain.HalfDaySession(*halfDaySession)
			app.HalfDaySession = &h
		}
		if reviewedByName != nil {
			app.ReviewedByName = *reviewedByName
		}
		app.ManagerRemarks = managerRemarks
		apps = append(apps, app)
	}
	return apps, nil
}

func (r *leaveRepository) UpdateApplicationStatus(
	ctx context.Context,
	id uuid.UUID,
	status domain.LeaveStatus,
	reviewedBy *uuid.UUID,
	reviewedAt *time.Time,
	remarks *string,
) error {
	query := `
		UPDATE leave_applications
		SET status = $1, reviewed_by = $2, reviewed_at = $3, manager_remarks = $4, updated_at = NOW()
		WHERE id = $5
	`
	tag, err := r.db.Pool.Exec(ctx, query, string(status), reviewedBy, reviewedAt, remarks, id)
	if err != nil {
		return fmt.Errorf("failed to update application status: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return domain.ErrLeaveApplicationNotFound
	}
	return nil
}

func (r *leaveRepository) DeductLeaveBalance(ctx context.Context, employeeID, leaveTypeID uuid.UUID, year int, days float64) error {
	query := `
		UPDATE employee_leave_balances
		SET used_days = used_days + $1,
		    remaining_days = remaining_days - $1,
		    updated_at = NOW()
		WHERE employee_id = $2 AND leave_type_id = $3 AND year = $4
	`
	tag, err := r.db.Pool.Exec(ctx, query, days, employeeID, leaveTypeID, year)
	if err != nil {
		return fmt.Errorf("failed to deduct leave balance: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return domain.ErrLeaveTypeNotFound
	}
	return nil
}

func (r *leaveRepository) RefundLeaveBalance(ctx context.Context, employeeID, leaveTypeID uuid.UUID, year int, days float64) error {
	query := `
		UPDATE employee_leave_balances
		SET used_days = GREATEST(0.0, used_days - $1),
		    remaining_days = remaining_days + $1,
		    updated_at = NOW()
		WHERE employee_id = $2 AND leave_type_id = $3 AND year = $4
	`
	tag, err := r.db.Pool.Exec(ctx, query, days, employeeID, leaveTypeID, year)
	if err != nil {
		return fmt.Errorf("failed to refund leave balance: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return domain.ErrLeaveTypeNotFound
	}
	return nil
}

func (r *leaveRepository) HasOverlappingLeave(ctx context.Context, employeeID uuid.UUID, startDate, endDate time.Time) (bool, error) {
	query := `
		SELECT EXISTS (
			SELECT 1 FROM leave_applications
			WHERE employee_id = $1
			  AND status IN ('PENDING', 'APPROVED')
			  AND start_date <= $3
			  AND end_date >= $2
		)
	`
	var exists bool
	err := r.db.Pool.QueryRow(ctx, query, employeeID, startDate, endDate).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check overlapping leave: %w", err)
	}
	return exists, nil
}

func (r *leaveRepository) GetApprovedLeaveForDate(ctx context.Context, employeeID uuid.UUID, date time.Time) (*domain.LeaveApplication, error) {
	query := `
		SELECT a.id, a.employee_id, e.full_name, e.employee_code, a.leave_type_id, lt.name, lt.code,
		       a.start_date, a.end_date, a.total_days, a.is_half_day, a.half_day_session,
		       a.reason, a.attachment_url, a.applying_to, a.cc, a.status, a.reviewed_by, rev.full_name, a.reviewed_at, a.manager_remarks,
		       a.created_at, a.updated_at
		FROM leave_applications a
		JOIN employees e ON e.id = a.employee_id
		JOIN leave_types lt ON lt.id = a.leave_type_id
		LEFT JOIN employees rev ON rev.id = a.reviewed_by
		WHERE a.employee_id = $1
		  AND a.status = 'APPROVED'
		  AND $2::date BETWEEN a.start_date AND a.end_date
		LIMIT 1
	`
	app := &domain.LeaveApplication{}
	var halfDaySession, reviewedByName, managerRemarks *string
	var statusStr string

	err := r.db.Pool.QueryRow(ctx, query, employeeID, date).Scan(
		&app.ID, &app.EmployeeID, &app.EmployeeName, &app.EmployeeCode, &app.LeaveTypeID, &app.LeaveTypeName, &app.LeaveTypeCode,
		&app.StartDate, &app.EndDate, &app.TotalDays, &app.IsHalfDay, &halfDaySession,
		&app.Reason, &app.AttachmentURL, &app.ApplyingTo, &app.CC, &statusStr, &app.ReviewedBy, &reviewedByName, &app.ReviewedAt, &managerRemarks,
		&app.CreatedAt, &app.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil // No approved leave on this date
		}
		return nil, fmt.Errorf("failed to query approved leave for date: %w", err)
	}

	app.Status = domain.LeaveStatus(statusStr)
	if halfDaySession != nil {
		h := domain.HalfDaySession(*halfDaySession)
		app.HalfDaySession = &h
	}
	if reviewedByName != nil {
		app.ReviewedByName = *reviewedByName
	}
	app.ManagerRemarks = managerRemarks

	return app, nil
}

func (r *leaveRepository) HasCasualLeaveInMonth(ctx context.Context, employeeID uuid.UUID, year int, month time.Month) (bool, error) {
	query := `
		SELECT EXISTS(
			SELECT 1 FROM leave_applications a
			JOIN leave_types t ON a.leave_type_id = t.id
			WHERE a.employee_id = $1
			  AND t.code = 'CL'
			  AND a.status IN ('PENDING', 'APPROVED', 'CANCELLATION_PENDING')
			  AND EXTRACT(YEAR FROM a.start_date) = $2
			  AND EXTRACT(MONTH FROM a.start_date) = $3
		)
	`
	var exists bool
	err := r.db.Pool.QueryRow(ctx, query, employeeID, year, int(month)).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check casual leave monthly limit: %w", err)
	}
	return exists, nil
}
