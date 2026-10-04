package repository

import (
	"context"
	"time"

	"github.com/google/uuid"

	"location-attendance/internal/domain"
)

// EmployeeRepository defines persistence operations for Employee entities
type EmployeeRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*domain.Employee, error)
	GetByCode(ctx context.Context, code string) (*domain.Employee, error)
}

// OfficeRepository defines persistence operations for Office entities
type OfficeRepository interface {
	GetByID(ctx context.Context, id uuid.UUID) (*domain.Office, error)
}

// AttendanceRepository defines persistence operations for AttendanceSession entities
type AttendanceRepository interface {
	// GetActiveSession returns the active (CHECKED_IN) session for an employee, or domain.ErrNoActiveSession
	GetActiveSession(ctx context.Context, employeeID uuid.UUID) (*domain.AttendanceSession, error)
	// CreateSession records a new CHECKED_IN session. Returns domain.ErrActiveSessionExists if one is already open
	CreateSession(ctx context.Context, session *domain.AttendanceSession) error
	// UpdateSession persists checkout completion details for an existing session
	UpdateSession(ctx context.Context, session *domain.AttendanceSession) error
	// GetHistoryByEmployeeID returns paginated attendance history belonging exclusively to the employee, optionally filtered by date range
	GetHistoryByEmployeeID(ctx context.Context, employeeID uuid.UUID, from, to *time.Time, limit, offset int) ([]*domain.AttendanceSession, int64, error)
}
