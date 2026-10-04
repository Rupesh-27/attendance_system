package mock

import (
	"context"
	"sort"
	"sync"
	"time"

	"github.com/google/uuid"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

// MockEmployeeRepo is an in-memory thread-safe implementation of repository.EmployeeRepository
type MockEmployeeRepo struct {
	sync.RWMutex
	employeesByID   map[uuid.UUID]*domain.Employee
	employeesByCode map[string]*domain.Employee
}

func NewMockEmployeeRepo() *MockEmployeeRepo {
	return &MockEmployeeRepo{
		employeesByID:   make(map[uuid.UUID]*domain.Employee),
		employeesByCode: make(map[string]*domain.Employee),
	}
}

func (m *MockEmployeeRepo) Seed(emp *domain.Employee) {
	m.Lock()
	defer m.Unlock()
	cp := *emp
	m.employeesByID[emp.ID] = &cp
	m.employeesByCode[emp.EmployeeCode] = &cp
}

func (m *MockEmployeeRepo) GetByID(ctx context.Context, id uuid.UUID) (*domain.Employee, error) {
	m.RLock()
	defer m.RUnlock()
	emp, ok := m.employeesByID[id]
	if !ok {
		return nil, domain.ErrEmployeeNotFound
	}
	cp := *emp
	return &cp, nil
}

func (m *MockEmployeeRepo) GetByCode(ctx context.Context, codeOrEmail string) (*domain.Employee, error) {
	m.RLock()
	defer m.RUnlock()
	emp, ok := m.employeesByCode[codeOrEmail]
	if ok {
		cp := *emp
		return &cp, nil
	}
	for _, e := range m.employeesByID {
		if e.Email != "" && e.Email == codeOrEmail {
			cp := *e
			return &cp, nil
		}
	}
	return nil, domain.ErrEmployeeNotFound
}

var _ repository.EmployeeRepository = (*MockEmployeeRepo)(nil)

// MockOfficeRepo is an in-memory thread-safe implementation of repository.OfficeRepository
type MockOfficeRepo struct {
	sync.RWMutex
	offices map[uuid.UUID]*domain.Office
}

func NewMockOfficeRepo() *MockOfficeRepo {
	return &MockOfficeRepo{
		offices: make(map[uuid.UUID]*domain.Office),
	}
}

func (m *MockOfficeRepo) Seed(office *domain.Office) {
	m.Lock()
	defer m.Unlock()
	cp := *office
	m.offices[office.ID] = &cp
}

func (m *MockOfficeRepo) GetByID(ctx context.Context, id uuid.UUID) (*domain.Office, error) {
	m.RLock()
	defer m.RUnlock()
	office, ok := m.offices[id]
	if !ok {
		return nil, domain.ErrOfficeNotFound
	}
	cp := *office
	return &cp, nil
}

var _ repository.OfficeRepository = (*MockOfficeRepo)(nil)

// MockAttendanceRepo is an in-memory thread-safe implementation of repository.AttendanceRepository
// It enforces the partial unique index rule: only one CHECKED_IN session per employee.
type MockAttendanceRepo struct {
	sync.RWMutex
	sessions map[uuid.UUID]*domain.AttendanceSession
}

func NewMockAttendanceRepo() *MockAttendanceRepo {
	return &MockAttendanceRepo{
		sessions: make(map[uuid.UUID]*domain.AttendanceSession),
	}
}

func (m *MockAttendanceRepo) GetActiveSession(ctx context.Context, employeeID uuid.UUID) (*domain.AttendanceSession, error) {
	m.RLock()
	defer m.RUnlock()

	for _, s := range m.sessions {
		if s.EmployeeID == employeeID && s.Status == domain.StatusCheckedIn {
			cp := *s
			return &cp, nil
		}
	}
	return nil, domain.ErrNoActiveSession
}

func (m *MockAttendanceRepo) CreateSession(ctx context.Context, session *domain.AttendanceSession) error {
	m.Lock()
	defer m.Unlock()

	// Enforce DB partial unique index constraint: WHERE status = 'CHECKED_IN'
	if session.Status == domain.StatusCheckedIn {
		for _, s := range m.sessions {
			if s.EmployeeID == session.EmployeeID && s.Status == domain.StatusCheckedIn {
				return domain.ErrActiveSessionExists
			}
		}
	}

	cp := *session
	m.sessions[session.ID] = &cp
	return nil
}

func (m *MockAttendanceRepo) UpdateSession(ctx context.Context, session *domain.AttendanceSession) error {
	m.Lock()
	defer m.Unlock()

	if _, ok := m.sessions[session.ID]; !ok {
		return domain.ErrNoActiveSession
	}

	cp := *session
	m.sessions[session.ID] = &cp
	return nil
}

func (m *MockAttendanceRepo) GetHistoryByEmployeeID(
	ctx context.Context,
	employeeID uuid.UUID,
	from, to *time.Time,
	limit, offset int,
) ([]*domain.AttendanceSession, int64, error) {
	m.RLock()
	defer m.RUnlock()

	var employeeSessions []*domain.AttendanceSession
	for _, s := range m.sessions {
		if s.EmployeeID == employeeID {
			if from != nil && s.CheckInTime.Before(*from) {
				continue
			}
			if to != nil && s.CheckInTime.After(*to) {
				continue
			}
			cp := *s
			employeeSessions = append(employeeSessions, &cp)
		}
	}

	// Sort descending by CheckInTime
	sort.Slice(employeeSessions, func(i, j int) bool {
		return employeeSessions[i].CheckInTime.After(employeeSessions[j].CheckInTime)
	})

	total := int64(len(employeeSessions))
	if offset >= len(employeeSessions) {
		return []*domain.AttendanceSession{}, total, nil
	}

	end := offset + limit
	if end > len(employeeSessions) {
		end = len(employeeSessions)
	}

	return employeeSessions[offset:end], total, nil
}

var _ repository.AttendanceRepository = (*MockAttendanceRepo)(nil)
