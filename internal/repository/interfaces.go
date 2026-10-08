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
	// GetActiveSession returns the active (CHECKED_IN or CARRIED_OVER) session for an employee, or domain.ErrNoActiveSession
	GetActiveSession(ctx context.Context, employeeID uuid.UUID) (*domain.AttendanceSession, error)
	// CreateSession records a new session. Returns domain.ErrActiveSessionExists if one is already open
	CreateSession(ctx context.Context, session *domain.AttendanceSession) error
	// UpdateSession persists checkout completion details for an existing session
	UpdateSession(ctx context.Context, session *domain.AttendanceSession) error
	// UpdateSessionStatus transitions a session's status (e.g., from CHECKED_IN to CARRIED_OVER)
	UpdateSessionStatus(ctx context.Context, sessionID uuid.UUID, status domain.AttendanceStatus) error
	// UpdateInitialOutOfRadiusAt updates the initial breach timestamp for an active session
	UpdateInitialOutOfRadiusAt(ctx context.Context, sessionID uuid.UUID, breachTime *time.Time) error
	// GetExpiredBreachSessions returns all active sessions with an out-of-radius breach timestamp older than or equal to the cutoff
	GetExpiredBreachSessions(ctx context.Context, cutoff time.Time) ([]*domain.AttendanceSession, error)
	// GetSessionsByAttendanceDay returns all sessions belonging to a specific attendance day (e.g. 2026-10-05)
	GetSessionsByAttendanceDay(ctx context.Context, employeeID uuid.UUID, attendanceDay string) ([]*domain.AttendanceSession, error)
	// GetHistoryByEmployeeID returns paginated attendance history belonging exclusively to the employee, optionally filtered by date range
	GetHistoryByEmployeeID(ctx context.Context, employeeID uuid.UUID, from, to *time.Time, limit, offset int) ([]*domain.AttendanceSession, int64, error)
}

// SettingsRepository defines persistence operations for SystemSettings
type SettingsRepository interface {
	GetSettings(ctx context.Context) (*domain.SystemSettings, error)
	UpdateSettings(ctx context.Context, settings *domain.SystemSettings) error
}

