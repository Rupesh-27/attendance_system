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
		OfficeID:                  office.ID,
		LocationAttendanceEnabled: true,
		IsActive:                  true,
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

func TestAuth_SingleDevice_BlockSecondLogin(t *testing.T) {
	empRepo, _, _, _, _ := setupTestEnvironment()
	authSvc := service.NewAuthService(empRepo, "test-secret", 24*time.Hour)

	// First login on Device A: must succeed
	res1, err := authSvc.Login(context.Background(), "EMP001", "Password123!")
	require.NoError(t, err)
	assert.NotEmpty(t, res1.AccessToken)

	// Second login attempt on Device B: must be blocked!
	_, err2 := authSvc.Login(context.Background(), "EMP001", "Password123!")
	assert.ErrorIs(t, err2, domain.ErrDeviceAlreadyLoggedIn)

	// Third login attempt with force=true: succeeds and takes over session!
	res3, err3 := authSvc.Login(context.Background(), "EMP001", "Password123!", true)
	require.NoError(t, err3)
	assert.NotEmpty(t, res3.AccessToken)
}

func TestAuth_Logout_AllowsNextLogin(t *testing.T) {
	empRepo, _, _, emp, _ := setupTestEnvironment()
	authSvc := service.NewAuthService(empRepo, "test-secret", 24*time.Hour)

	// First login on Device A: succeeds
	res1, err := authSvc.Login(context.Background(), "EMP001", "Password123!")
	require.NoError(t, err)
	assert.NotEmpty(t, res1.AccessToken)

	// Device A logs out:
	err = authSvc.Logout(context.Background(), emp.ID)
	require.NoError(t, err)

	// Next login on Device B: now succeeds!
	res2, err := authSvc.Login(context.Background(), "EMP001", "Password123!")
	require.NoError(t, err)
	assert.NotEmpty(t, res2.AccessToken)
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
		OfficeID:                  office.ID,
		LocationAttendanceEnabled: true,
		IsActive:                  true,
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

func TestAttendance_ProcessAutoForceCheckouts(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, _ := setupTestEnvironment()
	mockSettings := mock.NewMockSettingsRepo()

	now := time.Now().UTC()
	clock := func() time.Time { return now }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock, mockSettings)

	inGps := domain.GPSLocation{
		Latitude:       13.000000,
		Longitude:      80.000000,
		AccuracyMeters: 5.0,
		CapturedAt:     now,
	}

	session, err := attSvc.CheckIn(context.Background(), emp.ID, inGps)
	require.NoError(t, err)
	assert.Equal(t, domain.StatusCheckedIn, session.Status)

	// Case 1: Breach recorded 1 minute ago (within 2-minute threshold) -> Should NOT checkout
	breachTime := now.Add(-1 * time.Minute)
	err = attSvc.RecordOutOfRadiusBreach(context.Background(), emp.ID, &breachTime)
	require.NoError(t, err)

	count, err := attSvc.ProcessAutoForceCheckouts(context.Background())
	require.NoError(t, err)
	assert.Equal(t, 0, count)

	active, err := attRepo.GetActiveSession(context.Background(), emp.ID)
	require.NoError(t, err)
	assert.Equal(t, domain.StatusCheckedIn, active.Status)

	// Case 2: Employee walks back inside -> Clear breach -> Should NOT checkout
	err = attSvc.ClearOutOfRadiusBreach(context.Background(), emp.ID)
	require.NoError(t, err)

	active, err = attRepo.GetActiveSession(context.Background(), emp.ID)
	require.NoError(t, err)
	assert.Nil(t, active.InitialOutOfRadiusAt)

	// Case 3: New breach recorded 2m 10s ago (exceeded threshold) -> Should AUTO FORCE CHECKOUT!
	oldBreach := now.Add(-130 * time.Second)
	err = attSvc.RecordOutOfRadiusBreach(context.Background(), emp.ID, &oldBreach)
	require.NoError(t, err)

	count, err = attSvc.ProcessAutoForceCheckouts(context.Background())
	require.NoError(t, err)
	assert.Equal(t, 1, count)

	// Verify session is now COMPLETED with FORCE_CHECKOUT_OUT_OF_RADIUS
	_, err = attRepo.GetActiveSession(context.Background(), emp.ID)
	assert.ErrorIs(t, err, domain.ErrNoActiveSession)
}

func TestAttendance_CheckIn_WhenLocationAttendanceDisabled_AllowedOutsideRadius(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	// Disable location restriction for this employee (e.g. Remote / Field staff)
	emp.LocationAttendanceEnabled = false
	empRepo.Seed(emp)

	currentTime := time.Date(2026, 9, 23, 9, 0, 0, 0, time.UTC)
	clock := func() time.Time { return currentTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	// GPS is 500 meters away from the office
	gps := domain.GPSLocation{
		Latitude:       office.Latitude + 0.005,
		Longitude:      office.Longitude + 0.005,
		AccuracyMeters: 10.0,
		CapturedAt:     currentTime,
	}

	session, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	require.NoError(t, err)
	require.NotNil(t, session)

	// Verify check-in succeeded and coordinates were accurately captured in session
	assert.Equal(t, domain.StatusCheckedIn, session.Status)
	assert.Equal(t, gps.Latitude, session.CheckInLatitude)
	assert.Equal(t, gps.Longitude, session.CheckInLongitude)
	assert.Equal(t, gps.AccuracyMeters, session.CheckInAccuracyMeters)
	assert.True(t, session.CheckInDistanceMeters > 50.0)
}

func TestAttendance_WhenLocationAttendanceDisabled_RelaxedAccuracyAccepted(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	// Disable location restriction for this employee
	emp.LocationAttendanceEnabled = false
	empRepo.Seed(emp)

	currentTime := time.Date(2026, 9, 23, 9, 0, 0, 0, time.UTC)
	clock := func() time.Time { return currentTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	// GPS is outside office AND has indoor accuracy of 50 meters (which would be rejected in strict mode)
	inGps := domain.GPSLocation{
		Latitude:       office.Latitude + 0.005,
		Longitude:      office.Longitude + 0.005,
		AccuracyMeters: 50.0,
		CapturedAt:     currentTime,
	}

	session, err := attSvc.CheckIn(context.Background(), emp.ID, inGps)
	require.NoError(t, err)
	require.NotNil(t, session)
	assert.Equal(t, domain.StatusCheckedIn, session.Status)
	assert.Equal(t, 50.0, session.CheckInAccuracyMeters)

	// Now check out with indoor accuracy of 65 meters
	outTime := currentTime.Add(2 * time.Hour)
	outClock := func() time.Time { return outTime }
	attSvcOut := service.NewAttendanceService(empRepo, officeRepo, attRepo, outClock)

	outGps := domain.GPSLocation{
		Latitude:       office.Latitude + 0.005,
		Longitude:      office.Longitude + 0.005,
		AccuracyMeters: 65.0,
		CapturedAt:     outTime,
	}

	completedSession, err := attSvcOut.CheckOut(context.Background(), emp.ID, outGps)
	require.NoError(t, err)
	require.NotNil(t, completedSession)
	assert.Equal(t, domain.StatusCompleted, completedSession.Status)
	assert.Equal(t, 65.0, *completedSession.CheckOutAccuracyMeters)
}

func TestAttendance_WhenLocationAttendanceEnabled_StrictAccuracyEnforced(t *testing.T) {
	empRepo, officeRepo, attRepo, emp, office := setupTestEnvironment()

	// Strict location restriction enabled
	emp.LocationAttendanceEnabled = true
	empRepo.Seed(emp)

	currentTime := time.Date(2026, 9, 23, 9, 0, 0, 0, time.UTC)
	clock := func() time.Time { return currentTime }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	// GPS inside office but weak accuracy of 35 meters
	gps := domain.GPSLocation{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 35.0,
		CapturedAt:     currentTime,
	}

	_, err := attSvc.CheckIn(context.Background(), emp.ID, gps)
	assert.ErrorIs(t, err, domain.ErrAccuracyTooLow)
}

func TestAttendance_CheckIn_OfficeTimezone_Germany(t *testing.T) {
	empRepo, officeRepo, attRepo, _, _ := setupTestEnvironment()

	// Office in Berlin with Europe/Berlin timezone
	berlinOffice := &domain.Office{
		ID:           uuid.New(),
		Name:         "Berlin Innovation Center",
		Latitude:     52.520008,
		Longitude:    13.404954,
		RadiusMeters: 10.0,
		Timezone:     "Europe/Berlin",
		IsActive:     true,
	}
	officeRepo.Seed(berlinOffice)

	berlinEmp := &domain.Employee{
		ID:                        uuid.New(),
		EmployeeCode:              "EMP_BERLIN",
		FullName:                  "Hans Weber",
		OfficeID:                  berlinOffice.ID,
		LocationAttendanceEnabled: true,
		IsActive:                  true,
	}
	empRepo.Seed(berlinEmp)

	// Time: Oct 23, 2026 at 21:00:00 UTC
	// In Germany (CEST = UTC+2), this is 23:00 on Oct 23 (Friday night).
	// In India (IST = UTC+5:30), this is 02:30 on Oct 24 (Saturday morning).
	checkInUTC := time.Date(2026, 10, 23, 21, 0, 0, 0, time.UTC)
	clock := func() time.Time { return checkInUTC }
	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	gps := domain.GPSLocation{
		Latitude:       berlinOffice.Latitude,
		Longitude:      berlinOffice.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     checkInUTC,
	}

	session, err := attSvc.CheckIn(context.Background(), berlinEmp.ID, gps)
	require.NoError(t, err)
	// Must anchor to Germany's local calendar day (2026-10-23), NOT India's (2026-10-24)
	assert.Equal(t, "2026-10-23", session.AttendanceDay)

	// Verify GetTodayStatus also reflects Germany's local date
	todayStatus, err := attSvc.GetTodayStatus(context.Background(), berlinEmp.ID)
	require.NoError(t, err)
	assert.Equal(t, "2026-10-23", todayStatus.AttendanceDay)
}



