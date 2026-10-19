package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type leaveService struct {
	leaveRepo    repository.LeaveRepository
	employeeRepo repository.EmployeeRepository
	clock        Clock
}

func NewLeaveService(
	leaveRepo repository.LeaveRepository,
	employeeRepo repository.EmployeeRepository,
	clock Clock,
) LeaveService {
	if clock == nil {
		clock = func() time.Time { return time.Now().UTC() }
	}
	return &leaveService{
		leaveRepo:    leaveRepo,
		employeeRepo: employeeRepo,
		clock:        clock,
	}
}

func (s *leaveService) GetLeaveTypes(ctx context.Context) ([]*domain.LeaveType, error) {
	return s.leaveRepo.GetLeaveTypes(ctx)
}

func (s *leaveService) GetLeaveBalances(ctx context.Context, employeeID uuid.UUID, year int) ([]*domain.EmployeeLeaveBalance, error) {
	if year <= 0 {
		year = s.clock().Year()
	}
	return s.leaveRepo.GetLeaveBalances(ctx, employeeID, year)
}

func (s *leaveService) ApplyLeave(ctx context.Context, employeeID uuid.UUID, req ApplyLeaveRequest) (*domain.LeaveApplication, error) {
	startDate, err := time.Parse("2006-01-02", req.StartDate)
	if err != nil {
		return nil, domain.ErrInvalidLeaveDates
	}

	endDate, err := time.Parse("2006-01-02", req.EndDate)
	if err != nil {
		return nil, domain.ErrInvalidLeaveDates
	}

	if endDate.Before(startDate) {
		return nil, domain.ErrInvalidLeaveDates
	}

	var totalDays float64
	if req.IsHalfDay {
		if !startDate.Equal(endDate) {
			return nil, domain.ErrInvalidLeaveDates
		}
		totalDays = 0.5
		if req.HalfDaySession == nil {
			firstHalf := domain.HalfDayFirstHalf
			req.HalfDaySession = &firstHalf
		}
	} else {
		days := int(endDate.Sub(startDate).Hours()/24) + 1
		if days <= 0 {
			return nil, domain.ErrInvalidLeaveDates
		}
		totalDays = float64(days)
	}

	// 1. Fetch leave type & check policy rules
	lt, err := s.leaveRepo.GetLeaveTypeByID(ctx, req.LeaveTypeID)
	if err != nil {
		return nil, err
	}
	if lt == nil {
		return nil, domain.ErrLeaveTypeNotFound
	}

	// 1a. Casual Leave (CL) Policy: Max 1 day per application & 1 application per calendar month
	if lt.Code == "CL" {
		if totalDays > 1.0 {
			return nil, domain.ErrCasualLeaveExceedsOneDay
		}
		hasCL, err := s.leaveRepo.HasCasualLeaveInMonth(ctx, employeeID, startDate.Year(), startDate.Month())
		if err != nil {
			return nil, err
		}
		if hasCL {
			return nil, domain.ErrCasualLeaveMonthlyLimit
		}
	}

	// 1b. Sick Leave (SL) Policy: Medical certificate required if >= 2.0 days
	if lt.Code == "SL" && totalDays >= 2.0 {
		if req.AttachmentURL == nil || *req.AttachmentURL == "" {
			return nil, domain.ErrSickLeaveAttachmentRequired
		}
	}

	// 2. Check for overlapping approved/pending leaves
	overlap, err := s.leaveRepo.HasOverlappingLeave(ctx, employeeID, startDate, endDate)
	if err != nil {
		return nil, err
	}
	if overlap {
		return nil, domain.ErrLeaveDateOverlap
	}

	// 3. Check remaining balance for the requested year
	year := startDate.Year()
	balance, err := s.leaveRepo.GetLeaveBalance(ctx, employeeID, req.LeaveTypeID, year)
	if err != nil {
		return nil, err
	}
	if balance == nil || balance.RemainingDays < totalDays {
		return nil, domain.ErrInsufficientLeaveBalance
	}

	// 4. Create application in PENDING status
	now := s.clock()
	applyingTo := "Mathumitha"
	if req.ApplyingTo != nil && *req.ApplyingTo != "" {
		applyingTo = *req.ApplyingTo
	}

	app := &domain.LeaveApplication{
		ID:             uuid.New(),
		EmployeeID:     employeeID,
		LeaveTypeID:    req.LeaveTypeID,
		StartDate:      startDate,
		EndDate:        endDate,
		TotalDays:      totalDays,
		IsHalfDay:      req.IsHalfDay,
		HalfDaySession: req.HalfDaySession,
		Reason:         req.Reason,
		AttachmentURL:  req.AttachmentURL,
		ApplyingTo:     &applyingTo,
		CC:             req.CC,
		Status:         domain.LeaveStatusPending,
		CreatedAt:      now,
		UpdatedAt:      now,
	}

	if err := s.leaveRepo.CreateApplication(ctx, app); err != nil {
		return nil, err
	}

	return app, nil
}

func (s *leaveService) GetMyApplications(ctx context.Context, employeeID uuid.UUID, status *domain.LeaveStatus) ([]*domain.LeaveApplication, error) {
	return s.leaveRepo.GetApplicationsByEmployee(ctx, employeeID, status)
}

func (s *leaveService) CancelApplication(ctx context.Context, employeeID, applicationID uuid.UUID) error {
	app, err := s.leaveRepo.GetApplicationByID(ctx, applicationID)
	if err != nil {
		return err
	}

	if app.EmployeeID != employeeID {
		return domain.ErrUnauthorized
	}

	now := s.clock()

	switch app.Status {
	case domain.LeaveStatusPending:
		// Pending leave can be withdrawn directly by employee
		remarks := "Withdrawn by employee"
		return s.leaveRepo.UpdateApplicationStatus(ctx, applicationID, domain.LeaveStatusWithdrawn, nil, &now, &remarks)

	case domain.LeaveStatusApproved:
		// Approved leave enters CANCELLATION_PENDING awaiting manager approval
		remarks := "Cancellation requested by employee"
		return s.leaveRepo.UpdateApplicationStatus(ctx, applicationID, domain.LeaveStatusCancellationPending, nil, &now, &remarks)

	default:
		return errors.New("application cannot be cancelled in its current status")
	}
}

func (s *leaveService) GetPendingApprovals(ctx context.Context) ([]*domain.LeaveApplication, error) {
	return s.leaveRepo.GetPendingApplications(ctx)
}

func (s *leaveService) ApproveApplication(ctx context.Context, applicationID, reviewerID uuid.UUID, remarks *string) (*domain.LeaveApplication, error) {
	app, err := s.leaveRepo.GetApplicationByID(ctx, applicationID)
	if err != nil {
		return nil, err
	}

	now := s.clock()

	switch app.Status {
	case domain.LeaveStatusPending:
		// Normal approval: deduct balance and mark APPROVED
		year := app.StartDate.Year()
		if err := s.leaveRepo.DeductLeaveBalance(ctx, app.EmployeeID, app.LeaveTypeID, year, app.TotalDays); err != nil {
			return nil, err
		}

		if err := s.leaveRepo.UpdateApplicationStatus(ctx, applicationID, domain.LeaveStatusApproved, &reviewerID, &now, remarks); err != nil {
			return nil, err
		}
		app.Status = domain.LeaveStatusApproved
		app.ReviewedBy = &reviewerID
		app.ReviewedAt = &now
		app.ManagerRemarks = remarks
		app.UpdatedAt = now
		return app, nil

	case domain.LeaveStatusCancellationPending:
		// Cancellation approval: refund balance and mark CANCELLED
		year := app.StartDate.Year()
		if err := s.leaveRepo.RefundLeaveBalance(ctx, app.EmployeeID, app.LeaveTypeID, year, app.TotalDays); err != nil {
			return nil, err
		}

		if err := s.leaveRepo.UpdateApplicationStatus(ctx, applicationID, domain.LeaveStatusCancelled, &reviewerID, &now, remarks); err != nil {
			return nil, err
		}
		app.Status = domain.LeaveStatusCancelled
		app.ReviewedBy = &reviewerID
		app.ReviewedAt = &now
		app.ManagerRemarks = remarks
		app.UpdatedAt = now
		return app, nil

	default:
		return nil, domain.ErrLeaveNotPending
	}
}

func (s *leaveService) RejectApplication(ctx context.Context, applicationID, reviewerID uuid.UUID, remarks *string) (*domain.LeaveApplication, error) {
	app, err := s.leaveRepo.GetApplicationByID(ctx, applicationID)
	if err != nil {
		return nil, err
	}

	now := s.clock()

	switch app.Status {
	case domain.LeaveStatusPending:
		// Reject pending leave
		if err := s.leaveRepo.UpdateApplicationStatus(ctx, applicationID, domain.LeaveStatusRejected, &reviewerID, &now, remarks); err != nil {
			return nil, err
		}
		app.Status = domain.LeaveStatusRejected
		app.ReviewedBy = &reviewerID
		app.ReviewedAt = &now
		app.ManagerRemarks = remarks
		app.UpdatedAt = now
		return app, nil

	case domain.LeaveStatusCancellationPending:
		// Rejection of cancellation request reverts status back to APPROVED
		revertRemarks := "Cancellation request rejected; leave remains approved"
		if remarks != nil && *remarks != "" {
			revertRemarks = *remarks
		}
		if err := s.leaveRepo.UpdateApplicationStatus(ctx, applicationID, domain.LeaveStatusApproved, &reviewerID, &now, &revertRemarks); err != nil {
			return nil, err
		}
		app.Status = domain.LeaveStatusApproved
		app.ReviewedBy = &reviewerID
		app.ReviewedAt = &now
		app.ManagerRemarks = &revertRemarks
		app.UpdatedAt = now
		return app, nil

	default:
		return nil, domain.ErrLeaveNotPending
	}
}
