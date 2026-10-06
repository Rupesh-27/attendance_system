package domain_test

import (
	"math"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"location-attendance/internal/domain"
)

func TestHaversine_IdenticalCoordinates(t *testing.T) {
	dist := domain.CalculateHaversineDistance(13.0827, 80.2707, 13.0827, 80.2707)
	assert.Equal(t, 0.0, dist)
}

func TestHaversine_KnownDistance(t *testing.T) {

	dist := domain.CalculateHaversineDistance(51.5074, -0.1278, 48.8566, 2.3522)
	expectedKm := 343.5
	actualKm := dist / 1000.0
	assert.True(t, math.Abs(actualKm-expectedKm) < 3.0, "Expected ~343.5km, got %f", actualKm)
}

func TestOffice_RadiusBoundaries(t *testing.T) {
	office := domain.Office{
		ID:           uuid.New(),
		Name:         "Headquarters",
		Latitude:     13.000000,
		Longitude:    80.000000,
		RadiusMeters: 10.0,
		IsActive:     true,
	}

	assert.True(t, office.IsWithinRadius(9.99))

	assert.True(t, office.IsWithinRadius(10.00))

	assert.False(t, office.IsWithinRadius(10.01))
}

func TestGPSValidation_Latitude(t *testing.T) {
	now := time.Now().UTC()

	tests := []struct {
		name    string
		lat     float64
		wantErr error
	}{
		{"Valid positive latitude", 13.0827, nil},
		{"Valid negative latitude", -33.8688, nil},
		{"Valid boundary -90", -90.0, nil},
		{"Valid boundary +90", 90.0, nil},
		{"Invalid latitude below -90", -90.01, domain.ErrInvalidLatitude},
		{"Invalid latitude above +90", 90.01, domain.ErrInvalidLatitude},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gps := domain.GPSLocation{
				Latitude:       tt.lat,
				Longitude:      80.0,
				AccuracyMeters: 5.0,
				CapturedAt:     now,
			}
			err := gps.Validate(now)
			if tt.wantErr != nil {
				assert.ErrorIs(t, err, tt.wantErr)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestGPSValidation_Longitude(t *testing.T) {
	now := time.Now().UTC()

	tests := []struct {
		name    string
		lon     float64
		wantErr error
	}{
		{"Valid positive longitude", 80.2707, nil},
		{"Valid negative longitude", -122.4194, nil},
		{"Valid boundary -180", -180.0, nil},
		{"Valid boundary +180", 180.0, nil},
		{"Invalid longitude below -180", -180.01, domain.ErrInvalidLongitude},
		{"Invalid longitude above +180", 180.01, domain.ErrInvalidLongitude},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gps := domain.GPSLocation{
				Latitude:       13.0,
				Longitude:      tt.lon,
				AccuracyMeters: 5.0,
				CapturedAt:     now,
			}
			err := gps.Validate(now)
			if tt.wantErr != nil {
				assert.ErrorIs(t, err, tt.wantErr)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestGPSValidation_Accuracy(t *testing.T) {
	now := time.Now().UTC()

	tests := []struct {
		name     string
		accuracy float64
		wantErr  error
	}{
		{"Valid accuracy 5m", 5.0, nil},
		{"Valid accuracy 20m boundary", 20.0, nil},
		{"Accuracy zero rejected", 0.0, domain.ErrInvalidAccuracy},
		{"Negative accuracy rejected", -1.0, domain.ErrInvalidAccuracy},
		{"Accuracy 20.01m rejected", 20.01, domain.ErrAccuracyTooLow},
		{"Accuracy 50m rejected", 50.0, domain.ErrAccuracyTooLow},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gps := domain.GPSLocation{
				Latitude:       13.0,
				Longitude:      80.0,
				AccuracyMeters: tt.accuracy,
				CapturedAt:     now,
			}
			err := gps.Validate(now)
			if tt.wantErr != nil {
				assert.ErrorIs(t, err, tt.wantErr)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestGPSValidation_Freshness(t *testing.T) {
	serverTime := time.Date(2026, 9, 23, 12, 0, 30, 0, time.UTC)

	tests := []struct {
		name       string
		capturedAt time.Time
		wantErr    error
	}{
		{
			name:       "capturedAt 29s ago -> valid",
			capturedAt: serverTime.Add(-29 * time.Second),
			wantErr:    nil,
		},
		{
			name:       "capturedAt 30s ago -> valid boundary",
			capturedAt: serverTime.Add(-30 * time.Second),
			wantErr:    nil,
		},
		{
			name:       "capturedAt 31s ago -> rejected as stale",
			capturedAt: serverTime.Add(-31 * time.Second),
			wantErr:    domain.ErrCaptureTimeStale,
		},
		{
			name:       "capturedAt exactly server time -> valid",
			capturedAt: serverTime,
			wantErr:    nil,
		},
		{
			name:       "capturedAt within 15s future tolerance -> valid",
			capturedAt: serverTime.Add(5 * time.Second),
			wantErr:    nil,
		},
		{
			name:       "capturedAt 16s in the future -> rejected",
			capturedAt: serverTime.Add(16 * time.Second),
			wantErr:    domain.ErrCaptureTimeInFuture,
		},
		{
			name:       "capturedAt 60s in the future -> rejected",
			capturedAt: serverTime.Add(60 * time.Second),
			wantErr:    domain.ErrCaptureTimeInFuture,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			gps := domain.GPSLocation{
				Latitude:       13.0,
				Longitude:      80.0,
				AccuracyMeters: 5.0,
				CapturedAt:     tt.capturedAt,
			}
			err := gps.Validate(serverTime)
			if tt.wantErr != nil {
				assert.ErrorIs(t, err, tt.wantErr)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

func TestAttendanceSession_CheckoutTransition(t *testing.T) {
	checkInTime := time.Date(2026, 9, 23, 9, 0, 0, 0, time.UTC)
	session := domain.AttendanceSession{
		ID:          uuid.New(),
		EmployeeID:  uuid.New(),
		OfficeID:    uuid.New(),
		CheckInTime: checkInTime,
		Status:      domain.StatusCheckedIn,
	}

	checkOutTime := checkInTime.Add(2 * time.Hour)
	gps := domain.GPSLocation{
		Latitude:       13.0,
		Longitude:      80.0,
		AccuracyMeters: 5.0,
		CapturedAt:     checkOutTime,
	}

	err := session.CompleteCheckout(checkOutTime, gps, 4.5)
	require.NoError(t, err)

	assert.Equal(t, domain.StatusCompleted, session.Status)
	assert.NotNil(t, session.CheckOutTime)
	assert.Equal(t, checkOutTime, *session.CheckOutTime)
	assert.NotNil(t, session.DurationSeconds)
	assert.Equal(t, int64(7200), *session.DurationSeconds)

	errAgain := session.CompleteCheckout(checkOutTime.Add(1*time.Minute), gps, 4.5)
	assert.ErrorIs(t, errAgain, domain.ErrSessionAlreadyEnded)
}
