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

	// 7. Determine attendance day in IST (Asia/Kolkata)
	loc, err := time.LoadLocation("Asia/Kolkata")
	if err != nil {
		loc = time.UTC
	}
	attendanceDay := serverTime.In(loc).Format("2006-01-02")

	// 8. Construct new session with immutable decision snapshots
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
		AttendanceDay:         attendanceDay,
		Source:                domain.SourceGPSMobile,
		Status:                domain.StatusCheckedIn,
		CreatedAt:             serverTime,
		UpdatedAt:             serverTime,
	}

	// 9. Persist session (protected by DB partial unique index against race conditions)
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

	// 2. Active Session check: must have an open session (CHECKED_IN or CARRIED_OVER) to check out
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

	// 6. Complete transition and calculate working duration (handles overnight shifts)
	if err := session.CompleteCheckout(serverTime, gps, distance); err != nil {
		return nil, err
	}

	// 7. Persist update
	if err := s.attendanceRepo.UpdateSession(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (s *attendanceService) GetTodayStatus(
	ctx context.Context,
	employeeID uuid.UUID,
) (*TodayAttendanceStatus, error) {
	serverTime := s.clock()
	loc, err := time.LoadLocation("Asia/Kolkata")
	if err != nil {
		loc = time.UTC
	}
	currentDate := serverTime.In(loc).Format("2006-01-02")

	// 1. Check for active session (CHECKED_IN or CARRIED_OVER)
	activeSession, err := s.attendanceRepo.GetActiveSession(ctx, employeeID)
	if err != nil && !errors.Is(err, domain.ErrNoActiveSession) {
		return nil, err
	}

	var targetAttendanceDay string
	isCarriedOver := false

	if activeSession != nil {
		// Active session found! Check if its attendanceDay is prior to currentDate
		if activeSession.AttendanceDay < currentDate {
			// Midnight rollover condition: Employee remained checked in past midnight!
			isCarriedOver = true
			if activeSession.Status != domain.StatusCarriedOver {
				activeSession.Status = domain.StatusCarriedOver
				// Persist status transition to database
				_ = s.attendanceRepo.UpdateSessionStatus(ctx, activeSession.ID, domain.StatusCarriedOver)
			}
		}
		targetAttendanceDay = activeSession.AttendanceDay
	} else {
		targetAttendanceDay = currentDate
	}

	// 2. Load all sessions for targetAttendanceDay
	sessions, err := s.attendanceRepo.GetSessionsByAttendanceDay(ctx, employeeID, targetAttendanceDay)
	if err != nil {
		return nil, err
	}

	// 3. Compute total accumulated work seconds for this attendance day
	var totalWorkSeconds int64
	for _, sess := range sessions {
		if sess.DurationSeconds != nil && *sess.DurationSeconds > 0 {
			totalWorkSeconds += *sess.DurationSeconds
		} else if sess.IsActive() {
			elapsed := int64(serverTime.Sub(sess.CheckInTime).Seconds())
			if elapsed > 0 {
				totalWorkSeconds += elapsed
			}
		}
	}

	return &TodayAttendanceStatus{
		AttendanceDay:    targetAttendanceDay,
		IsCarriedOver:    isCarriedOver,
		ActiveSession:    activeSession,
		TodaySessions:    sessions,
		TotalWorkSeconds: totalWorkSeconds,
	}, nil
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
