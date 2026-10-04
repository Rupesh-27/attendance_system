package domain

import (
	"time"

	"github.com/google/uuid"
)

type AttendanceStatus string

const (
	StatusCheckedIn AttendanceStatus = "CHECKED_IN"
	StatusCompleted AttendanceStatus = "COMPLETED"
)

type AttendanceSource string

const (
	SourceBiometric AttendanceSource = "BIOMETRIC"
	SourceWeb       AttendanceSource = "WEB"
	SourceGPSMobile AttendanceSource = "GPS_MOBILE"
)

// AttendanceSession represents a single mobile check-in to check-out session
type AttendanceSession struct {
	ID         uuid.UUID        `json:"id"`
	EmployeeID uuid.UUID        `json:"employeeId"`
	OfficeID   uuid.UUID        `json:"officeId"`
	Source     AttendanceSource `json:"source"`


	// Decision Snapshot of Assigned Office at Check-In
	OfficeSnapshotName   string  `json:"officeSnapshotName"`
	OfficeSnapshotLat    float64 `json:"officeSnapshotLat"`
	OfficeSnapshotLon    float64 `json:"officeSnapshotLon"`
	OfficeSnapshotRadius float64 `json:"officeSnapshotRadius"`

	// Check-In Telemetry & Decision
	CheckInTime           time.Time `json:"checkInTime"` // Server authoritative
	CheckInLatitude       float64   `json:"checkInLatitude"`
	CheckInLongitude      float64   `json:"checkInLongitude"`
	CheckInAccuracyMeters float64   `json:"checkInAccuracyMeters"`
	CheckInCapturedAt     time.Time `json:"checkInCapturedAt"`
	CheckInDistanceMeters float64   `json:"checkInDistanceMeters"`

	// Check-Out Telemetry & Decision (populated upon completion)
	CheckOutTime           *time.Time `json:"checkOutTime,omitempty"` // Server authoritative
	CheckOutLatitude       *float64   `json:"checkOutLatitude,omitempty"`
	CheckOutLongitude      *float64   `json:"checkOutLongitude,omitempty"`
	CheckOutAccuracyMeters *float64   `json:"checkOutAccuracyMeters,omitempty"`
	CheckOutCapturedAt     *time.Time `json:"checkOutCapturedAt,omitempty"`
	CheckOutDistanceMeters *float64   `json:"checkOutDistanceMeters,omitempty"`

	// Calculated Duration in seconds
	DurationSeconds *int64           `json:"durationSeconds,omitempty"`
	Status          AttendanceStatus `json:"status"`

	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// CompleteCheckout transitions the session from CHECKED_IN to COMPLETED
func (s *AttendanceSession) CompleteCheckout(
	serverTime time.Time,
	gps GPSLocation,
	distanceMeters float64,
) error {
	if s.Status != StatusCheckedIn {
		return ErrSessionAlreadyEnded
	}

	duration := int64(serverTime.Sub(s.CheckInTime).Seconds())
	if duration < 0 {
		duration = 0
	}

	s.CheckOutTime = &serverTime
	s.CheckOutLatitude = &gps.Latitude
	s.CheckOutLongitude = &gps.Longitude
	s.CheckOutAccuracyMeters = &gps.AccuracyMeters
	s.CheckOutCapturedAt = &gps.CapturedAt
	s.CheckOutDistanceMeters = &distanceMeters
	s.DurationSeconds = &duration
	s.Status = StatusCompleted
	s.UpdatedAt = serverTime

	return nil
}
