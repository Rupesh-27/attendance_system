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

type AttendanceHistoryResult struct {
	Total    int64                       `json:"total"`
	Page     int                         `json:"page"`
	PageSize int                         `json:"pageSize"`
	Sessions []*domain.AttendanceSession `json:"sessions"`
}

type AuthService interface {
	Login(ctx context.Context, employeeCode, password string) (*AuthResult, error)
}

type EmployeeService interface {
	GetProfile(ctx context.Context, employeeID uuid.UUID) (*domain.Employee, error)
	GetAssignedOffice(ctx context.Context, employeeID uuid.UUID) (*domain.Office, error)
}

type AttendanceService interface {
	CheckIn(ctx context.Context, employeeID uuid.UUID, gps domain.GPSLocation) (*domain.AttendanceSession, error)
	CheckOut(ctx context.Context, employeeID uuid.UUID, gps domain.GPSLocation) (*domain.AttendanceSession, error)
	GetMyHistory(ctx context.Context, employeeID uuid.UUID, from, to *time.Time, page, pageSize int) (*AttendanceHistoryResult, error)
}
