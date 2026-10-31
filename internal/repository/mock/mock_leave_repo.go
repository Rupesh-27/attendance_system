package mock

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type MockLeaveRepo struct {
	sync.RWMutex
	leaveTypes   map[uuid.UUID]*domain.LeaveType
	balances     map[string]*domain.EmployeeLeaveBalance // key: empID_leaveTypeID_year
	applications map[uuid.UUID]*domain.LeaveApplication
}

func NewMockLeaveRepo() *MockLeaveRepo {
	repo := &MockLeaveRepo{
		leaveTypes:   make(map[uuid.UUID]*domain.LeaveType),
		balances:     make(map[string]*domain.EmployeeLeaveBalance),
		applications: make(map[uuid.UUID]*domain.LeaveApplication),
	}

	// Seed default leave types
	clID := uuid.MustParse("c0000000-0000-0000-0000-000000000001")
	slID := uuid.MustParse("c0000000-0000-0000-0000-000000000002")
	plID := uuid.MustParse("c0000000-0000-0000-0000-000000000003")

	repo.leaveTypes[clID] = &domain.LeaveType{
		ID:              clID,
		Name:            "Casual Leave",
		Code:            "CL",
		AnnualAllowance: 12,
		IsPaid:          true,
		IsActive:        true,
	}
	repo.leaveTypes[slID] = &domain.LeaveType{
		ID:              slID,
		Name:            "Sick Leave",
		Code:            "SL",
		AnnualAllowance: 8,
		IsPaid:          true,
		IsActive:        true,
	}
	repo.leaveTypes[plID] = &domain.LeaveType{
		ID:              plID,
		Name:            "Paid Leave",
		Code:            "PL",
		AnnualAllowance: 15,
		IsPaid:          true,
		IsActive:        true,
	}

	return repo
}

var _ repository.LeaveRepository = (*MockLeaveRepo)(nil)

func (m *MockLeaveRepo) balanceKey(empID, ltID uuid.UUID, year int) string {
	return fmt.Sprintf("%s_%s_%d", empID.String(), ltID.String(), year)
}

func (m *MockLeaveRepo) SeedBalance(b *domain.EmployeeLeaveBalance) {
	m.Lock()
	defer m.Unlock()
	cp := *b
	m.balances[m.balanceKey(b.EmployeeID, b.LeaveTypeID, b.Year)] = &cp
}

func (m *MockLeaveRepo) SeedApplication(app *domain.LeaveApplication) {
	m.Lock()
	defer m.Unlock()
	cp := *app
	m.applications[app.ID] = &cp
}

func (m *MockLeaveRepo) GetLeaveTypes(ctx context.Context) ([]*domain.LeaveType, error) {
	m.RLock()
	defer m.RUnlock()
	var list []*domain.LeaveType
	for _, lt := range m.leaveTypes {
		if lt.IsActive {
			cp := *lt
			list = append(list, &cp)
		}
	}
	return list, nil
}

func (m *MockLeaveRepo) GetLeaveTypeByID(ctx context.Context, id uuid.UUID) (*domain.LeaveType, error) {
	m.RLock()
	defer m.RUnlock()
	lt, ok := m.leaveTypes[id]
	if !ok {
		return nil, domain.ErrLeaveTypeNotFound
	}
	cp := *lt
	return &cp, nil
}

func (m *MockLeaveRepo) GetLeaveBalances(ctx context.Context, employeeID uuid.UUID, year int) ([]*domain.EmployeeLeaveBalance, error) {
	m.RLock()
	defer m.RUnlock()
	var list []*domain.EmployeeLeaveBalance
	for _, b := range m.balances {
		if b.EmployeeID == employeeID && b.Year == year {
			cp := *b
			if lt, ok := m.leaveTypes[b.LeaveTypeID]; ok {
				cp.LeaveTypeName = lt.Name
				cp.LeaveTypeCode = lt.Code
			}
			list = append(list, &cp)
		}
	}
	return list, nil
}

func (m *MockLeaveRepo) GetLeaveBalance(ctx context.Context, employeeID, leaveTypeID uuid.UUID, year int) (*domain.EmployeeLeaveBalance, error) {
	m.RLock()
	defer m.RUnlock()
	key := m.balanceKey(employeeID, leaveTypeID, year)
	b, ok := m.balances[key]
	if !ok {
		// Auto-initialize balance if missing
		lt, exists := m.leaveTypes[leaveTypeID]
		if !exists {
			return nil, domain.ErrLeaveTypeNotFound
		}
		newB := &domain.EmployeeLeaveBalance{
			ID:            uuid.New(),
			EmployeeID:    employeeID,
			LeaveTypeID:   leaveTypeID,
			LeaveTypeName: lt.Name,
			LeaveTypeCode: lt.Code,
			Year:          year,
			AllocatedDays: float64(lt.AnnualAllowance),
			UsedDays:      0.0,
			RemainingDays: float64(lt.AnnualAllowance),
		}
		m.RUnlock()
		m.SeedBalance(newB)
		m.RLock()
		cp := *newB
		return &cp, nil
	}
	cp := *b
	return &cp, nil
}

func (m *MockLeaveRepo) CreateApplication(ctx context.Context, app *domain.LeaveApplication) error {
	m.Lock()
	defer m.Unlock()
	cp := *app
	if lt, ok := m.leaveTypes[app.LeaveTypeID]; ok {
		cp.LeaveTypeName = lt.Name
		cp.LeaveTypeCode = lt.Code
	}
	m.applications[app.ID] = &cp
	return nil
}

func (m *MockLeaveRepo) GetApplicationByID(ctx context.Context, id uuid.UUID) (*domain.LeaveApplication, error) {
	m.RLock()
	defer m.RUnlock()
	app, ok := m.applications[id]
	if !ok {
		return nil, domain.ErrLeaveApplicationNotFound
	}
	cp := *app
	return &cp, nil
}

func (m *MockLeaveRepo) GetApplicationsByEmployee(ctx context.Context, employeeID uuid.UUID, status *domain.LeaveStatus) ([]*domain.LeaveApplication, error) {
	m.RLock()
	defer m.RUnlock()
	var list []*domain.LeaveApplication
	for _, app := range m.applications {
		if app.EmployeeID == employeeID {
			if status != nil && app.Status != *status {
				continue
			}
			cp := *app
			list = append(list, &cp)
		}
	}
	return list, nil
}

func (m *MockLeaveRepo) GetPendingApplications(ctx context.Context) ([]*domain.LeaveApplication, error) {
	m.RLock()
	defer m.RUnlock()
	var list []*domain.LeaveApplication
	for _, app := range m.applications {
		if app.Status == domain.LeaveStatusPending {
			cp := *app
			list = append(list, &cp)
		}
	}
	return list, nil
}

func (m *MockLeaveRepo) UpdateApplicationStatus(ctx context.Context, id uuid.UUID, status domain.LeaveStatus, reviewedBy *uuid.UUID, reviewedAt *time.Time, remarks *string) error {
	m.Lock()
	defer m.Unlock()
	app, ok := m.applications[id]
	if !ok {
		return domain.ErrLeaveApplicationNotFound
	}
	app.Status = status
	app.ReviewedBy = reviewedBy
	app.ReviewedAt = reviewedAt
	app.ManagerRemarks = remarks
	app.UpdatedAt = time.Now()
	return nil
}

func (m *MockLeaveRepo) DeductLeaveBalance(ctx context.Context, employeeID, leaveTypeID uuid.UUID, year int, days float64) error {
	m.Lock()
	defer m.Unlock()
	key := m.balanceKey(employeeID, leaveTypeID, year)
	b, ok := m.balances[key]
	if !ok {
		return domain.ErrLeaveTypeNotFound
	}
	b.UsedDays += days
	b.RemainingDays -= days
	b.UpdatedAt = time.Now()
	return nil
}

func (m *MockLeaveRepo) RefundLeaveBalance(ctx context.Context, employeeID, leaveTypeID uuid.UUID, year int, days float64) error {
	m.Lock()
	defer m.Unlock()
	key := m.balanceKey(employeeID, leaveTypeID, year)
	b, ok := m.balances[key]
	if !ok {
		return domain.ErrLeaveTypeNotFound
	}
	b.UsedDays -= days
	if b.UsedDays < 0 {
		b.UsedDays = 0
	}
	b.RemainingDays += days
	b.UpdatedAt = time.Now()
	return nil
}

func (m *MockLeaveRepo) HasOverlappingLeave(ctx context.Context, employeeID uuid.UUID, startDate, endDate time.Time) (bool, error) {
	m.RLock()
	defer m.RUnlock()
	for _, app := range m.applications {
		if app.EmployeeID == employeeID && (app.Status == domain.LeaveStatusPending || app.Status == domain.LeaveStatusApproved) {
			if !startDate.After(app.EndDate) && !endDate.Before(app.StartDate) {
				return true, nil
			}
		}
	}
	return false, nil
}

func (m *MockLeaveRepo) GetApprovedLeaveForDate(ctx context.Context, employeeID uuid.UUID, date time.Time) (*domain.LeaveApplication, error) {
	m.RLock()
	defer m.RUnlock()
	d := date.Truncate(24 * time.Hour)
	for _, app := range m.applications {
		if app.EmployeeID == employeeID && app.Status == domain.LeaveStatusApproved {
			s := app.StartDate.Truncate(24 * time.Hour)
			e := app.EndDate.Truncate(24 * time.Hour)
			if !d.Before(s) && !d.After(e) {
				cp := *app
				return &cp, nil
			}
		}
	}
	return nil, nil
}

func (m *MockLeaveRepo) HasCasualLeaveInMonth(ctx context.Context, employeeID uuid.UUID, year int, month time.Month) (bool, error) {
	m.RLock()
	defer m.RUnlock()
	for _, app := range m.applications {
		if app.EmployeeID == employeeID && (app.Status == domain.LeaveStatusPending || app.Status == domain.LeaveStatusApproved || app.Status == domain.LeaveStatusCancellationPending) {
			if app.StartDate.Year() == year && app.StartDate.Month() == month {
				lt := m.leaveTypes[app.LeaveTypeID]
				if lt != nil && lt.Code == "CL" {
					return true, nil
				}
			}
		}
	}
	return false, nil
}
