package domain

import (
	"time"

	"github.com/google/uuid"
)

type Role string

const (
	RoleEmployee Role = "EMPLOYEE"
)

// Employee represents an authenticated employee user
type Employee struct {
	ID           uuid.UUID `json:"id"`
	EmployeeCode string    `json:"employeeCode"`
	PasswordHash string    `json:"-"`
	FullName     string    `json:"fullName"`
	Email        string    `json:"email,omitempty"`
	Role         Role      `json:"role"`
	OfficeID     uuid.UUID `json:"officeId"`
	IsActive     bool      `json:"isActive"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// CanAuthenticate checks if the employee is eligible to log in and use APIs
func (e *Employee) CanAuthenticate() error {
	if !e.IsActive {
		return ErrEmployeeInactive
	}
	if e.Role != RoleEmployee {
		return ErrForbiddenRole
	}
	return nil
}
