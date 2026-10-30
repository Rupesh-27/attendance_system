package service

import (
	"context"
	"time"

	"github.com/google/uuid"

	"location-attendance/internal/domain"
)

type AuthResult struct {
	AccessToken string           `json:"accessToken"`
	ExpiresAt   time.Time        `json:"expiresAt"`
	Employee    *domain.Employee `json:"employee"`
}

type DailyAttendanceSummary struct {
	AttendanceDay      string `json:"attendanceDay"`
	TotalWorkSeconds   int64  `json:"totalWorkSeconds"`
	TotalWorkFormatted string `json:"totalWorkFormatted"`
	RequiredSeconds    int64  `json:"requiredSeconds"`
	ShortfallSeconds   int64  `json:"shortfallSeconds"`
	ShortfallFormatted string `json:"shortfallFormatted,omitempty"`
	OvertimeSeconds    int64  `json:"overtimeSeconds"`
	Status             string `json:"status"` // "PRESENT", "SHORTFALL", "PRESENT_WEEK_OFF", "ABSENT"
	SessionsCount      int    `json:"sessionsCount"`
}

type AttendanceHistoryResult struct {
	Total          int64                     `json:"total"`
	Page           int                       `json:"page"`
	PageSize       int                       `json:"pageSize"`
	Sessions       []*domain.AttendanceSession `json:"sessions"`
	DailySummaries []*DailyAttendanceSummary `json:"dailySummaries,omitempty"`
}

type TodayAttendanceStatus struct {
	AttendanceDay    string                      `json:"attendanceDay"`
	IsCarriedOver    bool                        `json:"isCarriedOver"`
	ActiveSession    *domain.AttendanceSession   `json:"activeSession,omitempty"`
	TodaySessions    []*domain.AttendanceSession `json:"todaySessions"`
	TotalWorkSeconds int64                       `json:"totalWorkSeconds"`
	IsOnLeave        bool                        `json:"isOnLeave,omitempty"`
	ApprovedLeave    *domain.LeaveApplication    `json:"approvedLeave,omitempty"`
}


type AuthService interface {
	Login(ctx context.Context, employeeCode, password string, force ...bool) (*AuthResult, error)
	Logout(ctx context.Context, employeeID uuid.UUID) error
}

type EmployeeService interface {
	GetProfile(ctx context.Context, employeeID uuid.UUID) (*domain.Employee, error)
	GetAssignedOffice(ctx context.Context, employeeID uuid.UUID) (*domain.Office, error)
}

type AttendanceService interface {
	CheckIn(ctx context.Context, employeeID uuid.UUID, gps domain.GPSLocation) (*domain.AttendanceSession, error)
	CheckOut(ctx context.Context, employeeID uuid.UUID, gps domain.GPSLocation) (*domain.AttendanceSession, error)
	ForceCheckOut(ctx context.Context, employeeID uuid.UUID, gps domain.GPSLocation, reason domain.CheckoutReason, breachedAt *time.Time) (*domain.AttendanceSession, error)
	RecordOutOfRadiusBreach(ctx context.Context, employeeID uuid.UUID, breachTime *time.Time) error
	ClearOutOfRadiusBreach(ctx context.Context, employeeID uuid.UUID) error
	ProcessAutoForceCheckouts(ctx context.Context) (int, error)
	GetTodayStatus(ctx context.Context, employeeID uuid.UUID) (*TodayAttendanceStatus, error)
	GetMyHistory(ctx context.Context, employeeID uuid.UUID, from, to *time.Time, page, pageSize int) (*AttendanceHistoryResult, error)
}

type ApplyLeaveRequest struct {
	LeaveTypeID    uuid.UUID              `json:"leaveTypeId"`
	StartDate      string                 `json:"startDate"`
	EndDate        string                 `json:"endDate"`
	IsHalfDay      bool                   `json:"isHalfDay"`
	HalfDaySession *domain.HalfDaySession `json:"halfDaySession,omitempty"`
	Reason         string                 `json:"reason"`
	AttachmentURL  *string                `json:"attachmentUrl,omitempty"`
	ApplyingTo     *string                `json:"applyingTo,omitempty"`
	CC             *string                `json:"cc,omitempty"`
}

type LeaveService interface {
	GetLeaveTypes(ctx context.Context) ([]*domain.LeaveType, error)
	GetLeaveBalances(ctx context.Context, employeeID uuid.UUID, year int) ([]*domain.EmployeeLeaveBalance, error)
	ApplyLeave(ctx context.Context, employeeID uuid.UUID, req ApplyLeaveRequest) (*domain.LeaveApplication, error)
	GetMyApplications(ctx context.Context, employeeID uuid.UUID, status *domain.LeaveStatus) ([]*domain.LeaveApplication, error)
	CancelApplication(ctx context.Context, employeeID, applicationID uuid.UUID) error
	GetPendingApprovals(ctx context.Context) ([]*domain.LeaveApplication, error)
	ApproveApplication(ctx context.Context, applicationID, reviewerID uuid.UUID, remarks *string) (*domain.LeaveApplication, error)
	RejectApplication(ctx context.Context, applicationID, reviewerID uuid.UUID, remarks *string) (*domain.LeaveApplication, error)
}


