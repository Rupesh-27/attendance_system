package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type Clock func() time.Time

type attendanceService struct {
	employeeRepo   repository.EmployeeRepository
	officeRepo     repository.OfficeRepository
	attendanceRepo repository.AttendanceRepository
	clock          Clock
}

func NewAttendanceService(
	employeeRepo repository.EmployeeRepository,
	officeRepo repository.OfficeRepository,
	attendanceRepo repository.AttendanceRepository,
	clock Clock,
) AttendanceService {
	if clock == nil {
		clock = func() time.Time { return time.Now().UTC() }
	}
	return &attendanceService{
		employeeRepo:   employeeRepo,
		officeRepo:     officeRepo,
		attendanceRepo: attendanceRepo,
		clock:          clock,
	}
}

func (s *attendanceService) CheckIn(
	ctx context.Context,
	employeeID uuid.UUID,
	gps domain.GPSLocation,
) (*domain.AttendanceSession, error) {
	serverTime := s.clock()

	// 1. Authoritative GPS & Freshness validation
	if err := gps.Validate(serverTime); err != nil {
		return nil, err
	}

	// 2. Concurrency / State Invariant: Verify employee does not already have an open session
	existingSession, err := s.attendanceRepo.GetActiveSession(ctx, employeeID)
	if err == nil && existingSession != nil {
		return nil, domain.ErrActiveSessionExists
	}
	if err != nil && !errors.Is(err, domain.ErrNoActiveSession) {
		return nil, err
	}

	// 3. Load employee to get assigned office
	emp, err := s.employeeRepo.GetByID(ctx, employeeID)
	if err != nil {
		return nil, err
	}
	if !emp.IsActive {
		return nil, domain.ErrEmployeeInactive
	}

	// 4. Load assigned office
	office, err := s.officeRepo.GetByID(ctx, emp.OfficeID)
	if err != nil {
		return nil, err
	}
	if !office.IsActive {
		return nil, domain.ErrOfficeInactive
	}

	// 5. Authoritative Haversine Distance Calculation
	distance := domain.CalculateHaversineDistance(
		office.Latitude,
		office.Longitude,
		gps.Latitude,
		gps.Longitude,
	)

	// 6. Geofence radius check
	if !office.IsWithinRadius(distance) {
		return nil, domain.ErrOutsideOfficeRadius
	}

	// 7. Construct new session with immutable decision snapshots
	session := &domain.AttendanceSession{
		ID:                    uuid.New(),
		EmployeeID:            emp.ID,
		OfficeID:              office.ID,
		OfficeSnapshotName:    office.Name,
		OfficeSnapshotLat:     office.Latitude,
		OfficeSnapshotLon:     office.Longitude,
		OfficeSnapshotRadius:  office.RadiusMeters,
		CheckInTime:           serverTime, // Server authoritative time
		CheckInLatitude:       gps.Latitude,
		CheckInLongitude:      gps.Longitude,
		CheckInAccuracyMeters: gps.AccuracyMeters,
		CheckInCapturedAt:     gps.CapturedAt,
		CheckInDistanceMeters: distance,
		Source:                domain.SourceGPSMobile,
		Status:                domain.StatusCheckedIn,
		CreatedAt:             serverTime,
		UpdatedAt:             serverTime,
	}

	// 8. Persist session (protected by DB partial unique index against race conditions)
	if err := s.attendanceRepo.CreateSession(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (s *attendanceService) CheckOut(
	ctx context.Context,
	employeeID uuid.UUID,
	gps domain.GPSLocation,
) (*domain.AttendanceSession, error) {
	serverTime := s.clock()

	// 1. Authoritative GPS & Freshness validation
	if err := gps.Validate(serverTime); err != nil {
		return nil, err
	}

	// 2. Active Session check: must have an open session to check out
	session, err := s.attendanceRepo.GetActiveSession(ctx, employeeID)
	if err != nil {
		if errors.Is(err, domain.ErrNoActiveSession) {
			return nil, domain.ErrNoActiveSession
		}
		return nil, err
	}

	// 3. Load assigned office
	office, err := s.officeRepo.GetByID(ctx, session.OfficeID)
	if err != nil {
		return nil, err
	}
	if !office.IsActive {
		return nil, domain.ErrOfficeInactive
	}

	// 4. Authoritative Haversine Distance Calculation at checkout
	distance := domain.CalculateHaversineDistance(
		office.Latitude,
		office.Longitude,
		gps.Latitude,
		gps.Longitude,
	)

	// 5. Geofence radius check
	if !office.IsWithinRadius(distance) {
		return nil, domain.ErrOutsideOfficeRadius
	}

	// 6. Complete transition and calculate working duration
	if err := session.CompleteCheckout(serverTime, gps, distance); err != nil {
		return nil, err
	}

	// 7. Persist update
	if err := s.attendanceRepo.UpdateSession(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (s *attendanceService) GetMyHistory(
	ctx context.Context,
	employeeID uuid.UUID,
	from, to *time.Time,
	page, pageSize int,
) (*AttendanceHistoryResult, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 50 {
		pageSize = 10
	}

	offset := (page - 1) * pageSize
	sessions, total, err := s.attendanceRepo.GetHistoryByEmployeeID(ctx, employeeID, from, to, pageSize, offset)
	if err != nil {
		return nil, err
	}

	return &AttendanceHistoryResult{
		Total:    total,
		Page:     page,
		PageSize: pageSize,
		Sessions: sessions,
	}, nil
}
