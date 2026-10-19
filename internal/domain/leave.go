package domain

import (
	"time"

	"github.com/google/uuid"
)

type LeaveStatus string

const (
	LeaveStatusPending             LeaveStatus = "PENDING"
	LeaveStatusApproved            LeaveStatus = "APPROVED"
	LeaveStatusRejected            LeaveStatus = "REJECTED"
	LeaveStatusCancelled           LeaveStatus = "CANCELLED"
	LeaveStatusWithdrawn           LeaveStatus = "WITHDRAWN"
	LeaveStatusCancellationPending LeaveStatus = "CANCELLATION_PENDING"
)

type HalfDaySession string

const (
	HalfDayFirstHalf  HalfDaySession = "FIRST_HALF"
	HalfDaySecondHalf HalfDaySession = "SECOND_HALF"
	HalfDaySession1   HalfDaySession = "Session 1"
	HalfDaySession2   HalfDaySession = "Session 2"
)

// LeaveType represents a company-defined leave policy category
type LeaveType struct {
	ID              uuid.UUID `json:"id"`
	Name            string    `json:"name"`
	Code            string    `json:"code"`
	Description     string    `json:"description,omitempty"`
	AnnualAllowance int       `json:"annualAllowance"`
	IsPaid          bool      `json:"isPaid"`
	IsActive        bool      `json:"isActive"`
	CreatedAt       time.Time `json:"createdAt"`
	UpdatedAt       time.Time `json:"updatedAt"`
}

// EmployeeLeaveBalance tracks an employee's allocated, used, and remaining days for a given year
type EmployeeLeaveBalance struct {
	ID            uuid.UUID `json:"id"`
	EmployeeID    uuid.UUID `json:"employeeId"`
	LeaveTypeID   uuid.UUID `json:"leaveTypeId"`
	LeaveTypeName string    `json:"leaveTypeName,omitempty"`
	LeaveTypeCode string    `json:"leaveTypeCode,omitempty"`
	Year          int       `json:"year"`
	AllocatedDays float64   `json:"allocatedDays"`
	UsedDays      float64   `json:"usedDays"`
	RemainingDays float64   `json:"remainingDays"`
	CreatedAt     time.Time `json:"createdAt"`
	UpdatedAt     time.Time `json:"updatedAt"`
}

// LeaveApplication represents a leave request submitted by an employee
type LeaveApplication struct {
	ID             uuid.UUID       `json:"id"`
	EmployeeID     uuid.UUID       `json:"employeeId"`
	EmployeeName   string          `json:"employeeName,omitempty"`
	EmployeeCode   string          `json:"employeeCode,omitempty"`
	LeaveTypeID    uuid.UUID       `json:"leaveTypeId"`
	LeaveTypeName  string          `json:"leaveTypeName,omitempty"`
	LeaveTypeCode  string          `json:"leaveTypeCode,omitempty"`
	StartDate      time.Time       `json:"startDate"`
	EndDate        time.Time       `json:"endDate"`
	TotalDays      float64         `json:"totalDays"`
	IsHalfDay      bool            `json:"isHalfDay"`
	HalfDaySession *HalfDaySession `json:"halfDaySession,omitempty"`
	Reason         string          `json:"reason"`
	AttachmentURL  *string         `json:"attachmentUrl,omitempty"`
	ApplyingTo     *string         `json:"applyingTo,omitempty"`
	CC             *string         `json:"cc,omitempty"`
	Status         LeaveStatus     `json:"status"`
	ReviewedBy     *uuid.UUID      `json:"reviewedBy,omitempty"`
	ReviewedByName string          `json:"reviewedByName,omitempty"`
	ReviewedAt     *time.Time      `json:"reviewedAt,omitempty"`
	ManagerRemarks *string         `json:"managerRemarks,omitempty"`
	CreatedAt      time.Time       `json:"createdAt"`
	UpdatedAt      time.Time       `json:"updatedAt"`
}
