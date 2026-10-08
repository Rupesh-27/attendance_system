package service

import (
	"context"
	"errors"
	"log"
	"time"

	"github.com/google/uuid"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type Clock func() time.Time

type attendanceService struct {
	employeeRepo    repository.EmployeeRepository
	officeRepo      repository.OfficeRepository
	attendanceRepo  repository.AttendanceRepository
	telegramService TelegramService
	settingsRepo    repository.SettingsRepository
	clock           Clock
}

func NewAttendanceService(
	employeeRepo repository.EmployeeRepository,
	officeRepo repository.OfficeRepository,
	attendanceRepo repository.AttendanceRepository,
	clock Clock,
	extra ...any,
) AttendanceService {
	if clock == nil {
		clock = func() time.Time { return time.Now().UTC() }
	}
	var tg TelegramService
	var settings repository.SettingsRepository
	for _, e := range extra {
		if t, ok := e.(TelegramService); ok {
			tg = t
		} else if s, ok := e.(repository.SettingsRepository); ok {
			settings = s
		}
	}
	return &attendanceService{
		employeeRepo:    employeeRepo,
		officeRepo:      officeRepo,
		attendanceRepo:  attendanceRepo,
		telegramService: tg,
		settingsRepo:    settings,
		clock:           clock,
	}
}

func (s *attendanceService) CheckIn(
	ctx context.Context,
	employeeID uuid.UUID,
	gps domain.GPSLocation,
) (*domain.AttendanceSession, error) {
	serverTime := s.clock()

	if err := gps.Validate(serverTime); err != nil {
		return nil, err
	}

	existingSession, err := s.attendanceRepo.GetActiveSession(ctx, employeeID)
	if err == nil && existingSession != nil {
		return nil, domain.ErrActiveSessionExists
	}
	if err != nil && !errors.Is(err, domain.ErrNoActiveSession) {
		return nil, err
	}

	emp, err := s.employeeRepo.GetByID(ctx, employeeID)
	if err != nil {
		return nil, err
	}
	if !emp.IsActive {
		return nil, domain.ErrEmployeeInactive
	}

	office, err := s.officeRepo.GetByID(ctx, emp.OfficeID)
	if err != nil {
		return nil, err
	}
	if !office.IsActive {
		return nil, domain.ErrOfficeInactive
	}

	distance := domain.CalculateHaversineDistance(
		office.Latitude,
		office.Longitude,
		gps.Latitude,
		gps.Longitude,
	)

	if !office.IsWithinRadius(distance) {
		return nil, domain.ErrOutsideOfficeRadius
	}

	loc, err := time.LoadLocation("Asia/Kolkata")
	if err != nil {
		loc = time.UTC
	}
	attendanceDay := serverTime.In(loc).Format("2006-01-02")

	session := &domain.AttendanceSession{
		ID:                    uuid.New(),
		EmployeeID:            emp.ID,
		OfficeID:              office.ID,
		OfficeSnapshotName:    office.Name,
		OfficeSnapshotLat:     office.Latitude,
		OfficeSnapshotLon:     office.Longitude,
		OfficeSnapshotRadius:  office.RadiusMeters,
		CheckInTime:           serverTime,
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

	if err := gps.Validate(serverTime); err != nil {
		return nil, err
	}

	session, err := s.attendanceRepo.GetActiveSession(ctx, employeeID)
	if err != nil {
		if errors.Is(err, domain.ErrNoActiveSession) {
			return nil, domain.ErrNoActiveSession
		}
		return nil, err
	}

	office, err := s.officeRepo.GetByID(ctx, session.OfficeID)
	if err != nil {
		return nil, err
	}
	if !office.IsActive {
		return nil, domain.ErrOfficeInactive
	}

	distance := domain.CalculateHaversineDistance(
		office.Latitude,
		office.Longitude,
		gps.Latitude,
		gps.Longitude,
	)

	if !office.IsWithinRadius(distance) {
		return nil, domain.ErrOutsideOfficeRadius
	}

	if err := session.CompleteCheckout(serverTime, gps, distance); err != nil {
		return nil, err
	}

	if err := s.attendanceRepo.UpdateSession(ctx, session); err != nil {
		return nil, err
	}

	return session, nil
}

func (s *attendanceService) ForceCheckOut(
	ctx context.Context,
	employeeID uuid.UUID,
	gps domain.GPSLocation,
	reason domain.CheckoutReason,
	breachedAt *time.Time,
) (*domain.AttendanceSession, error) {
	serverTime := s.clock()

	if err := gps.ValidateForForceCheckout(serverTime); err != nil {
		return nil, err
	}

	session, err := s.attendanceRepo.GetActiveSession(ctx, employeeID)
	if err != nil {
		if errors.Is(err, domain.ErrNoActiveSession) {
			return nil, domain.ErrNoActiveSession
		}
		return nil, err
	}

	emp, err := s.employeeRepo.GetByID(ctx, employeeID)
	if err != nil {
		return nil, err
	}

	office, err := s.officeRepo.GetByID(ctx, session.OfficeID)
	if err != nil {
		return nil, err
	}

	distance := domain.CalculateHaversineDistance(
		office.Latitude,
		office.Longitude,
		gps.Latitude,
		gps.Longitude,
	)

	if reason == "" {
		reason = domain.CheckoutReasonForceOutOfRadius
	}

	if breachedAt != nil {
		session.InitialOutOfRadiusAt = breachedAt
	}

	if err := session.CompleteCheckoutWithReason(serverTime, gps, distance, reason); err != nil {
		return nil, err
	}

	if err := s.attendanceRepo.UpdateSession(ctx, session); err != nil {
		return nil, err
	}

	// Asynchronously notify HR on Telegram
	if s.telegramService != nil {
		go func(e *domain.Employee, off *domain.Office, sess *domain.AttendanceSession, dist float64) {
			bgCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			if err := s.telegramService.SendForceCheckoutAlert(bgCtx, e, off, sess, dist); err != nil {
				log.Printf("[Telegram] Failed to send alert: %v", err)
			}
		}(emp, office, session, distance)
	}

	return session, nil
}

func (s *attendanceService) RecordOutOfRadiusBreach(
	ctx context.Context,
	employeeID uuid.UUID,
	breachTime *time.Time,
) error {
	session, err := s.attendanceRepo.GetActiveSession(ctx, employeeID)
	if err != nil {
		return err
	}
	return s.attendanceRepo.UpdateInitialOutOfRadiusAt(ctx, session.ID, breachTime)
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

	activeSession, err := s.attendanceRepo.GetActiveSession(ctx, employeeID)
	if err != nil && !errors.Is(err, domain.ErrNoActiveSession) {
		return nil, err
	}

	var targetAttendanceDay string
	isCarriedOver := false

	if activeSession != nil {

		if activeSession.AttendanceDay < currentDate {

			isCarriedOver = true
			if activeSession.Status != domain.StatusCarriedOver {
				activeSession.Status = domain.StatusCarriedOver

				_ = s.attendanceRepo.UpdateSessionStatus(ctx, activeSession.ID, domain.StatusCarriedOver)
			}
		}
		targetAttendanceDay = activeSession.AttendanceDay
	} else {
		targetAttendanceDay = currentDate
	}

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
