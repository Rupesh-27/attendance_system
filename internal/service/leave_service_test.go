package service_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository/mock"
	"location-attendance/internal/service"
)

func setupLeaveService(t *testing.T) (service.LeaveService, *mock.MockLeaveRepo, uuid.UUID, uuid.UUID, uuid.UUID, uuid.UUID) {
	mockLeaveRepo := mock.NewMockLeaveRepo()
	mockEmpRepo := mock.NewMockEmployeeRepo()

	now := time.Date(2026, 10, 15, 9, 0, 0, 0, time.UTC)
	clock := func() time.Time { return now }

	empID := uuid.New()
	mockEmpRepo.Seed(&domain.Employee{
		ID:           empID,
		EmployeeCode: "EMP1001",
		FullName:     "John Doe",
		Role:         domain.RoleEmployee,
		IsActive:     true,
	})

	types, err := mockLeaveRepo.GetLeaveTypes(context.Background())
	require.NoError(t, err)
	require.Len(t, types, 3)

	var clID, slID, plID uuid.UUID
	for _, lt := range types {
		switch lt.Code {
		case "CL":
			clID = lt.ID
		case "SL":
			slID = lt.ID
		case "PL":
			plID = lt.ID
		}
	}

	// Seed initial balances for emp
	mockLeaveRepo.SeedBalance(&domain.EmployeeLeaveBalance{
		ID:            uuid.New(),
		EmployeeID:    empID,
		LeaveTypeID:   clID,
		Year:          2026,
		AllocatedDays: 12,
		UsedDays:      0,
		RemainingDays: 12,
	})
	mockLeaveRepo.SeedBalance(&domain.EmployeeLeaveBalance{
		ID:            uuid.New(),
		EmployeeID:    empID,
		LeaveTypeID:   slID,
		Year:          2026,
		AllocatedDays: 8,
		UsedDays:      0,
		RemainingDays: 8,
	})
	mockLeaveRepo.SeedBalance(&domain.EmployeeLeaveBalance{
		ID:            uuid.New(),
		EmployeeID:    empID,
		LeaveTypeID:   plID,
		Year:          2026,
		AllocatedDays: 15,
		UsedDays:      0,
		RemainingDays: 15,
	})

	leaveSvc := service.NewLeaveService(mockLeaveRepo, mockEmpRepo, clock)
	return leaveSvc, mockLeaveRepo, empID, clID, slID, plID
}

func TestLeaveService_ApplyLeave_Success(t *testing.T) {
	svc, _, empID, _, _, plID := setupLeaveService(t)
	ctx := context.Background()

	// Apply 3 days of Paid Leave
	req := service.ApplyLeaveRequest{
		LeaveTypeID: plID,
		StartDate:   "2026-10-20",
		EndDate:     "2026-10-22",
		IsHalfDay:   false,
		Reason:      "Family trip",
	}

	app, err := svc.ApplyLeave(ctx, empID, req)
	require.NoError(t, err)
	assert.NotNil(t, app)
	assert.Equal(t, float64(3), app.TotalDays)
	assert.Equal(t, domain.LeaveStatusPending, app.Status)
	assert.Equal(t, "Family trip", app.Reason)
}

func TestLeaveService_CasualLeave_Rules(t *testing.T) {
	svc, _, empID, clID, _, _ := setupLeaveService(t)
	ctx := context.Background()

	// Rule 1: CL cannot exceed 1 day per application
	reqMultiDay := service.ApplyLeaveRequest{
		LeaveTypeID: clID,
		StartDate:   "2026-10-20",
		EndDate:     "2026-10-21",
		Reason:      "Multi-day CL should fail",
	}
	_, err := svc.ApplyLeave(ctx, empID, reqMultiDay)
	assert.ErrorIs(t, err, domain.ErrCasualLeaveExceedsOneDay)

	// Single day CL should succeed
	reqSingleDay := service.ApplyLeaveRequest{
		LeaveTypeID: clID,
		StartDate:   "2026-10-20",
		EndDate:     "2026-10-20",
		Reason:      "Single day CL",
	}
	app, err := svc.ApplyLeave(ctx, empID, reqSingleDay)
	require.NoError(t, err)
	assert.Equal(t, float64(1), app.TotalDays)

	// Rule 2: CL can only be applied once per calendar month
	reqSecondInMonth := service.ApplyLeaveRequest{
		LeaveTypeID: clID,
		StartDate:   "2026-10-28",
		EndDate:     "2026-10-28",
		Reason:      "Second CL in same month should fail",
	}
	_, err = svc.ApplyLeave(ctx, empID, reqSecondInMonth)
	assert.ErrorIs(t, err, domain.ErrCasualLeaveMonthlyLimit)

	// CL in a different month (November) should be allowed
	reqNextMonth := service.ApplyLeaveRequest{
		LeaveTypeID: clID,
		StartDate:   "2026-11-05",
		EndDate:     "2026-11-05",
		Reason:      "CL next month is allowed",
	}
	appNov, err := svc.ApplyLeave(ctx, empID, reqNextMonth)
	require.NoError(t, err)
	assert.Equal(t, float64(1), appNov.TotalDays)
}

func TestLeaveService_SickLeave_AttachmentRule(t *testing.T) {
	svc, _, empID, _, slID, _ := setupLeaveService(t)
	ctx := context.Background()

	// SL >= 2 days without attachment should fail
	reqWithoutAttach := service.ApplyLeaveRequest{
		LeaveTypeID: slID,
		StartDate:   "2026-10-20",
		EndDate:     "2026-10-21",
		Reason:      "Fever and flu",
	}
	_, err := svc.ApplyLeave(ctx, empID, reqWithoutAttach)
	assert.ErrorIs(t, err, domain.ErrSickLeaveAttachmentRequired)

	// SL >= 2 days with attachment should succeed
	attachURL := "https://company.storage/medical_cert_123.pdf"
	reqWithAttach := service.ApplyLeaveRequest{
		LeaveTypeID:   slID,
		StartDate:     "2026-10-20",
		EndDate:       "2026-10-21",
		Reason:        "Fever with certificate",
		AttachmentURL: &attachURL,
	}
	app, err := svc.ApplyLeave(ctx, empID, reqWithAttach)
	require.NoError(t, err)
	assert.Equal(t, float64(2), app.TotalDays)
	assert.Equal(t, &attachURL, app.AttachmentURL)

	// SL for 1 day without attachment should succeed
	reqOneDaySL := service.ApplyLeaveRequest{
		LeaveTypeID: slID,
		StartDate:   "2026-11-01",
		EndDate:     "2026-11-01",
		Reason:      "Headache",
	}
	appOneDay, err := svc.ApplyLeave(ctx, empID, reqOneDaySL)
	require.NoError(t, err)
	assert.Equal(t, float64(1), appOneDay.TotalDays)
}

func TestLeaveService_ApplyLeave_InvalidDates(t *testing.T) {
	svc, _, empID, _, _, plID := setupLeaveService(t)
	ctx := context.Background()

	// End date before start date
	req := service.ApplyLeaveRequest{
		LeaveTypeID: plID,
		StartDate:   "2026-10-25",
		EndDate:     "2026-10-20",
		Reason:      "Vacation",
	}

	_, err := svc.ApplyLeave(ctx, empID, req)
	assert.ErrorIs(t, err, domain.ErrInvalidLeaveDates)

	// Half-day across multiple dates
	reqHalfDay := service.ApplyLeaveRequest{
		LeaveTypeID: plID,
		StartDate:   "2026-10-20",
		EndDate:     "2026-10-21",
		IsHalfDay:   true,
		Reason:      "Doctor appointment",
	}

	_, err = svc.ApplyLeave(ctx, empID, reqHalfDay)
	assert.ErrorIs(t, err, domain.ErrInvalidLeaveDates)
}

func TestLeaveService_ApplyLeave_InsufficientBalance(t *testing.T) {
	svc, _, empID, _, _, plID := setupLeaveService(t)
	ctx := context.Background()

	// Requesting 16 days when only 15 PL are available
	req := service.ApplyLeaveRequest{
		LeaveTypeID: plID,
		StartDate:   "2026-11-01",
		EndDate:     "2026-11-16",
		Reason:      "Extended vacation",
	}

	_, err := svc.ApplyLeave(ctx, empID, req)
	assert.ErrorIs(t, err, domain.ErrInsufficientLeaveBalance)
}

func TestLeaveService_ApplyLeave_DateOverlap(t *testing.T) {
	svc, _, empID, _, _, plID := setupLeaveService(t)
	ctx := context.Background()

	req1 := service.ApplyLeaveRequest{
		LeaveTypeID: plID,
		StartDate:   "2026-10-20",
		EndDate:     "2026-10-22",
		Reason:      "First leave",
	}
	_, err := svc.ApplyLeave(ctx, empID, req1)
	require.NoError(t, err)

	// Overlapping request
	req2 := service.ApplyLeaveRequest{
		LeaveTypeID: plID,
		StartDate:   "2026-10-21",
		EndDate:     "2026-10-23",
		Reason:      "Overlapping leave",
	}
	_, err = svc.ApplyLeave(ctx, empID, req2)
	assert.ErrorIs(t, err, domain.ErrLeaveDateOverlap)
}

func TestLeaveService_TwoStageCancellation_Workflow(t *testing.T) {
	svc, _, empID, _, _, plID := setupLeaveService(t)
	ctx := context.Background()
	managerID := uuid.New()

	// 1. Employee applies for leave
	req := service.ApplyLeaveRequest{
		LeaveTypeID: plID,
		StartDate:   "2026-10-20",
		EndDate:     "2026-10-21",
		Reason:      "Personal Work",
	}
	app, err := svc.ApplyLeave(ctx, empID, req)
	require.NoError(t, err)

	// Case A: Pending application cancellation -> status becomes WITHDRAWN
	err = svc.CancelApplication(ctx, empID, app.ID)
	require.NoError(t, err)

	myApps, err := svc.GetMyApplications(ctx, empID, nil)
	require.NoError(t, err)
	assert.Equal(t, domain.LeaveStatusWithdrawn, myApps[0].Status)

	// Case B: Approved application cancellation -> status becomes CANCELLATION_PENDING
	req2 := service.ApplyLeaveRequest{
		LeaveTypeID: plID,
		StartDate:   "2026-11-10",
		EndDate:     "2026-11-11",
		Reason:      "Trip",
	}
	app2, err := svc.ApplyLeave(ctx, empID, req2)
	require.NoError(t, err)

	// Approve it
	remarks := "Approved"
	approvedApp, err := svc.ApproveApplication(ctx, app2.ID, managerID, &remarks)
	require.NoError(t, err)
	assert.Equal(t, domain.LeaveStatusApproved, approvedApp.Status)

	// Employee requests cancellation on approved leave
	err = svc.CancelApplication(ctx, empID, app2.ID)
	require.NoError(t, err)

	myApps2, err := svc.GetMyApplications(ctx, empID, nil)
	require.NoError(t, err)
	var cancelPendingApp *domain.LeaveApplication
	for _, a := range myApps2 {
		if a.ID == app2.ID {
			cancelPendingApp = a
		}
	}
	require.NotNil(t, cancelPendingApp)
	assert.Equal(t, domain.LeaveStatusCancellationPending, cancelPendingApp.Status)

	// Manager approves cancellation -> status becomes CANCELLED & balance is refunded
	cancelRemarks := "Cancellation approved"
	finalApp, err := svc.ApproveApplication(ctx, app2.ID, managerID, &cancelRemarks)
	require.NoError(t, err)
	assert.Equal(t, domain.LeaveStatusCancelled, finalApp.Status)

	// Check balance: 15 allocated, 2 days were used then refunded -> 15 remaining
	balances, err := svc.GetLeaveBalances(ctx, empID, 2026)
	require.NoError(t, err)
	for _, b := range balances {
		if b.LeaveTypeID == plID {
			assert.Equal(t, float64(15), b.RemainingDays)
			assert.Equal(t, float64(0), b.UsedDays)
		}
	}
}
