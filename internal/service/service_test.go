package service_test

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/bcrypt"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository/mock"
	"location-attendance/internal/service"
)

func setupTestEnvironment() (
	*mock.MockEmployeeRepo,
	*mock.MockOfficeRepo,
	*mock.MockAttendanceRepo,
	*domain.Employee,
	*domain.Office,
) {
	empRepo := mock.NewMockEmployeeRepo()
	officeRepo := mock.NewMockOfficeRepo()
	attendanceRepo := mock.NewMockAttendanceRepo()

	office := &domain.Office{
		ID:           uuid.New(),
		Name:         "Chennai Tech Hub",
		Latitude:     13.000000,
		Longitude:    80.000000,
		RadiusMeters: 10.0,
		IsActive:     true,
	}
	officeRepo.Seed(office)

	hash, _ := bcrypt.GenerateFromPassword([]byte("Password123!"), bcrypt.DefaultCost)
	emp := &domain.Employee{
		ID:           uuid.New(),
		EmployeeCode: "EMP001",
		PasswordHash: string(hash),
		FullName:     "John Doe",
		Role:         domain.RoleEmployee,
		OfficeID:     office.ID,
		IsActive:     true,
	}
	empRepo.Seed(emp)

	return empRepo, officeRepo, attendanceRepo, emp, office
}

func TestAuth_Login_Success(t *testing.T) {
	empRepo, _, _, _, _ := setupTestEnvironment()
	authSvc := service.NewAuthService(empRepo, "test-secret", 24*time.Hour)

	res, err := authSvc.Login(context.Background(), "EMP001", "Password123!")
	require.NoError(t, err)
	assert.NotEmpty(t, res.AccessToken)
	assert.Equal(t, "EMP001", res.Employee.EmployeeCode)
}

func TestAuth_Login_InvalidPassword(t *testing.T) {
	empRepo, _, _, _, _ := setupTestEnvironment()
	authSvc := service.NewAuthService(empRepo, "test-secret", 24*time.Hour)

	_, err := authSvc.Login(context.Background(), "EMP001", "WrongPassword")
	assert.ErrorIs(t, err, domain.ErrInvalidCredentials)
}

func TestAuth_Login_EmployeeNotFound(t *testing.T) {
	empRepo, _, _, _, _ := setupTestEnvironment()
	authSvc := service.NewAuthService(empRepo, "test-secret", 24*time.Hour)

	_, err := authSvc.Login(context.Background(), "UNKNOWN", "Password123!")
	assert.ErrorIs(t, err, domain.ErrInvalidCredentials)
}

func TestAuth_Login_EmployeeInactive(t *testing.T) {
	empRepo, _, _, emp, _ := setupTestEnvironment()
	emp.IsActive = false
	empRepo.Seed(emp)

	authSvc := service.NewAuthService(empRepo, "test-secret", 24*time.Hour)

	_, err := authSvc.Login(context.Background(), "EMP001", "Password123!")
	assert.ErrorIs(t, err, domain.ErrEmployeeInactive)
}

func TestAttendance_CheckIn_Success_InsideRadius(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	fixedTime := time.Date(2026, 9, 23, 10, 0, 0, 0, time.UTC)
	clock := func() time.Time { return fixedTime }

	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	gps := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     fixedTime,
	}

	session, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	require.NoError(t, err)
	assert.Equal(t, domain.StatusCheckedIn, session.Status)
	assert.Equal(t, 0.0, session.CheckInDistanceMeters)
	assert.Equal(t, office.Name, session.OfficeSnapshotName)
	assert.Equal(t, 10.0, session.OfficeSnapshotRadius)
	assert.Equal(t, fixedTime, session.CheckInTime)
}

func TestAttendance_CheckIn_ExactRadiusBoundary(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	fixedTime := time.Date(2026, 9, 23, 10, 0, 0, 0, time.UTC)
	clock := func() time.Time { return fixedTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	boundaryLat := office.Latitude + 0.000089

	gps := domain.GPSLocation{
		Latitude:       boundaryLat,
		Longitude:      office.Longitude,
		AccuracyMeters: 10.0,
		CapturedAt:     fixedTime,
	}

	session, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	require.NoError(t, err)
	assert.True(t, session.CheckInDistanceMeters <= 10.0)
	assert.Equal(t, domain.StatusCheckedIn, session.Status)
}

func TestAttendance_CheckIn_Failure_OutsideRadius(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	fixedTime := time.Date(2026, 9, 23, 10, 0, 0, 0, time.UTC)
	clock := func() time.Time { return fixedTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	outsideLat := office.Latitude + 0.0005

	gps := domain.GPSLocation{
		Latitude:       outsideLat,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     fixedTime,
	}

	_, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	assert.ErrorIs(t, err, domain.ErrOutsideOfficeRadius)
}

func TestAttendance_CheckIn_Failure_AccuracyGreaterThan20m(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	fixedTime := time.Date(2026, 9, 23, 10, 0, 0, 0, time.UTC)
	clock := func() time.Time { return fixedTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	gps := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 20.1,
		CapturedAt:     fixedTime,
	}

	_, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	assert.ErrorIs(t, err, domain.ErrAccuracyTooLow)
}

func TestAttendance_CheckIn_Failure_StaleCaptureTime(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	fixedTime := time.Date(2026, 9, 23, 10, 0, 0, 0, time.UTC)
	clock := func() time.Time { return fixedTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	gps := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     fixedTime.Add(-31 * time.Second),
	}

	_, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	assert.ErrorIs(t, err, domain.ErrCaptureTimeStale)
}

func TestAttendance_CheckIn_Failure_FutureCaptureTime(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	fixedTime := time.Date(2026, 9, 23, 10, 0, 0, 0, time.UTC)
	clock := func() time.Time { return fixedTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	gps := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     fixedTime.Add(20 * time.Second),
	}

	_, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	assert.ErrorIs(t, err, domain.ErrCaptureTimeInFuture)
}

func TestAttendance_CheckIn_Failure_DuplicateActiveSession(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	fixedTime := time.Date(2026, 9, 23, 10, 0, 0, 0, time.UTC)
	clock := func() time.Time { return fixedTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	gps := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     fixedTime,
	}

	_, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	require.NoError(t, err)

	_, errSecond := attSvc.CheckIn(context.Background(), emp.ID, gps)
	assert.ErrorIs(t, errSecond, domain.ErrActiveSessionExists)
}

func TestAttendance_CheckOut_Success_And_MultipleSessionsAllowed(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	currentTime := time.Date(2026, 9, 23, 9, 0, 0, 0, time.UTC)
	clock := func() time.Time { return currentTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	gps := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     currentTime,
	}

	session1, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	require.NoError(t, err)
	assert.Equal(t, domain.StatusCheckedIn, session1.Status)

	currentTime = currentTime.Add(3 * time.Hour)
	gps.CapturedAt = currentTime

	completedSession, err := attSvc.CheckOut(context.Background(), emp.ID, gps)
	require.NoError(t, err)
	assert.Equal(t, domain.StatusCompleted, completedSession.Status)
	require.NotNil(t, completedSession.DurationSeconds)
	assert.Equal(t, int64(10800), *completedSession.DurationSeconds)

	currentTime = currentTime.Add(1 * time.Hour)
	gps.CapturedAt = currentTime

	session2, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	require.NoError(t, err)
	assert.Equal(t, domain.StatusCheckedIn, session2.Status)
	assert.NotEqual(t, session1.ID, session2.ID)
}

func TestAttendance_CheckOut_Failure_NoActiveSession(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	fixedTime := time.Date(2026, 9, 23, 10, 0, 0, 0, time.UTC)
	clock := func() time.Time { return fixedTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	gps := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     fixedTime,
	}

	_, err := attSvc.CheckOut(context.Background(), emp.ID, gps)
	assert.ErrorIs(t, err, domain.ErrNoActiveSession)
}

func TestAttendance_CheckOut_Failure_OutsideOfficeRadius(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	currentTime := time.Date(2026, 9, 23, 9, 0, 0, 0, time.UTC)
	clock := func() time.Time { return currentTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	validGPS := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     currentTime,
	}

	_, err := attSvc.CheckIn(context.Background(), emp.ID, validGPS)
	require.NoError(t, err)

	currentTime = currentTime.Add(1 * time.Hour)
	outsideGPS := domain.GPSLocation{
		Latitude:       office.Latitude + 0.005,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     currentTime,
	}

	_, err = attSvc.CheckOut(context.Background(), emp.ID, outsideGPS)
	assert.ErrorIs(t, err, domain.ErrOutsideOfficeRadius)
}

func TestAttendance_ConcurrentCheckIn(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	fixedTime := time.Date(2026, 9, 23, 10, 0, 0, 0, time.UTC)
	clock := func() time.Time { return fixedTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	gps := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     fixedTime,
	}

	concurrency := 10
	var wg sync.WaitGroup
	successCount := 0
	conflictCount := 0
	var mu sync.Mutex

	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
			mu.Lock()
			defer mu.Unlock()
			if err == nil {
				successCount++
			} else if assert.ErrorIs(t, err, domain.ErrActiveSessionExists) {
				conflictCount++
			}
		}()
	}

	wg.Wait()

	assert.Equal(t, 1, successCount)
	assert.Equal(t, concurrency-1, conflictCount)
}

func TestAttendance_History_BelongsOnlyToAuthenticatedEmployee(t *testing.T) {
	empRepo, officeRepo, attRepo, emp1, office := setupTestEnvironment()

	emp2 := &domain.Employee{
		ID:           uuid.New(),
		EmployeeCode: "EMP002",
		FullName:     "Bob Smith",
		Role:         domain.RoleEmployee,
		OfficeID:     office.ID,
		IsActive:     true,
	}
	empRepo.Seed(emp2)

	currentTime := time.Date(2026, 9, 23, 8, 0, 0, 0, time.UTC)
	clock := func() time.Time { return currentTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	gps := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     currentTime,
	}

	_, err := attSvc.CheckIn(context.Background(), emp1.ID, gps)
	require.NoError(t, err)

	_, err = attSvc.CheckIn(context.Background(), emp2.ID, gps)
	require.NoError(t, err)

	hist1, err := attSvc.GetMyHistory(context.Background(), emp1.ID, nil, nil, 1, 10)
	require.NoError(t, err)
	assert.Equal(t, int64(1), hist1.Total)
	require.Len(t, hist1.Sessions, 1)
	assert.Equal(t, emp1.ID, hist1.Sessions[0].EmployeeID)

	hist2, err := attSvc.GetMyHistory(context.Background(), emp2.ID, nil, nil, 1, 10)
	require.NoError(t, err)
	assert.Equal(t, int64(1), hist2.Total)
	require.Len(t, hist2.Sessions, 1)
	assert.Equal(t, emp2.ID, hist2.Sessions[0].EmployeeID)

	pastFrom := time.Date(2026, 8, 1, 0, 0, 0, 0, time.UTC)
	pastTo := time.Date(2026, 8, 31, 23, 59, 59, 0, time.UTC)
	histPast, err := attSvc.GetMyHistory(context.Background(), emp1.ID, &pastFrom, &pastTo, 1, 10)
	require.NoError(t, err)
	assert.Equal(t, int64(0), histPast.Total)
	assert.Empty(t, histPast.Sessions)

	validFrom := time.Date(2026, 9, 23, 0, 0, 0, 0, time.UTC)
	validTo := time.Date(2026, 9, 23, 23, 59, 59, 0, time.UTC)
	histToday, err := attSvc.GetMyHistory(context.Background(), emp1.ID, &validFrom, &validTo, 1, 10)
	require.NoError(t, err)
	assert.Equal(t, int64(1), histToday.Total)
	require.Len(t, histToday.Sessions, 1)
}

func TestAttendanceService_GetTodayStatus_MidnightRollover(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, _ := setupTestEnvironment()

	loc, err := time.LoadLocation("Asia/Kolkata")
	require.NoError(t, err)

	checkInTime := time.Date(2026, 10, 5, 22, 0, 0, 0, loc).UTC()
	currentTime := checkInTime
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, func() time.Time { return currentTime })

	gps := domain.GPSLocation{
		Latitude:       13.000000,
		Longitude:      80.000000,
		AccuracyMeters: 5.0,
		CapturedAt:     checkInTime,
	}

	session, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	require.NoError(t, err)
	assert.Equal(t, domain.StatusCheckedIn, session.Status)
	assert.Equal(t, "2026-10-05", session.AttendanceDay)

	currentTime = time.Date(2026, 10, 6, 0, 30, 0, 0, loc).UTC()

	status, err := attSvc.GetTodayStatus(context.Background(), emp.ID)
	require.NoError(t, err)
	assert.True(t, status.IsCarriedOver, "Session should be identified as CARRIED_OVER across midnight")
	assert.Equal(t, "2026-10-05", status.AttendanceDay, "AttendanceDay should anchor to the original shift day")
	require.NotNil(t, status.ActiveSession)
	assert.Equal(t, domain.StatusCarriedOver, status.ActiveSession.Status)

	assert.Equal(t, int64(9000), status.TotalWorkSeconds)

	currentTime = time.Date(2026, 10, 6, 1, 30, 0, 0, loc).UTC()
	outGps := domain.GPSLocation{
		Latitude:       13.000000,
		Longitude:      80.000000,
		AccuracyMeters: 5.0,
		CapturedAt:     currentTime,
	}

	completedSession, err := attSvc.CheckOut(context.Background(), emp.ID, outGps)
	require.NoError(t, err)
	assert.Equal(t, domain.StatusCompleted, completedSession.Status)
	assert.Equal(t, "2026-10-05", completedSession.AttendanceDay)

	require.NotNil(t, completedSession.DurationSeconds)
	assert.Equal(t, int64(12600), *completedSession.DurationSeconds)

	statusAfterOut, err := attSvc.GetTodayStatus(context.Background(), emp.ID)
	require.NoError(t, err)
	assert.False(t, statusAfterOut.IsCarriedOver)
	assert.Nil(t, statusAfterOut.ActiveSession, "Active session should be nil after checkout")
	assert.Equal(t, "2026-10-06", statusAfterOut.AttendanceDay, "TodayStatus should now point to current date")
	assert.Empty(t, statusAfterOut.TodaySessions, "Today's sessions should be fresh/empty for the new day")
}

func TestAttendance_ForceCheckOut_Success(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, _ := setupTestEnvironment()
	mockSettings := mock.NewMockSettingsRepo()

	now := time.Now().UTC()
	clock := func() time.Time { return now }
	tgSvc := service.NewTelegramService(mockSettings, "", "")
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock, tgSvc, mockSettings)

	inGps := domain.GPSLocation{
		Latitude:       13.000000,
		Longitude:      80.000000,
		AccuracyMeters: 5.0,
		CapturedAt:     now,
	}

	session, err := attSvc.CheckIn(context.Background(), emp.ID, inGps)
	require.NoError(t, err)
	assert.Equal(t, domain.StatusCheckedIn, session.Status)

	// Breach recorded 2 minutes later
	breachTime := now.Add(2 * time.Minute)
	err = attSvc.RecordOutOfRadiusBreach(context.Background(), emp.ID, &breachTime)
	require.NoError(t, err)

	// Out of radius GPS coordinates (1000m away)
	now = now.Add(4 * time.Minute)
	outGps := domain.GPSLocation{
		Latitude:       13.010000,
		Longitude:      80.010000,
		AccuracyMeters: 10.0,
		CapturedAt:     now,
	}

	forceOutSession, err := attSvc.ForceCheckOut(context.Background(), emp.ID, outGps, domain.CheckoutReasonForceOutOfRadius, &breachTime)
	require.NoError(t, err)
	assert.Equal(t, domain.StatusCompleted, forceOutSession.Status)
	assert.Equal(t, domain.CheckoutReasonForceOutOfRadius, forceOutSession.CheckoutReason)
	require.NotNil(t, forceOutSession.InitialOutOfRadiusAt)
	assert.Equal(t, breachTime, *forceOutSession.InitialOutOfRadiusAt)
	require.NotNil(t, forceOutSession.DurationSeconds)
	assert.Equal(t, int64(240), *forceOutSession.DurationSeconds)
}

