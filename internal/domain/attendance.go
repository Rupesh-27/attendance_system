package domain

import (
	"time"

	"github.com/google/uuid"
)

type AttendanceStatus string

const (
	StatusCheckedIn   AttendanceStatus = "CHECKED_IN"
	StatusCarriedOver AttendanceStatus = "CARRIED_OVER"
	StatusCompleted   AttendanceStatus = "COMPLETED"
)

type AttendanceSource string

const (
	SourceBiometric AttendanceSource = "BIOMETRIC"
	SourceWeb       AttendanceSource = "WEB"
	SourceGPSMobile AttendanceSource = "GPS_MOBILE"
)

type CheckoutReason string

const (
	CheckoutReasonManual            CheckoutReason = "MANUAL"
	CheckoutReasonForceOutOfRadius CheckoutReason = "FORCE_CHECKOUT_OUT_OF_RADIUS"
)

// AttendanceSession represents a single mobile check-in to check-out session
type AttendanceSession struct {
	ID            uuid.UUID        `json:"id"`
	EmployeeID    uuid.UUID        `json:"employeeId"`
	OfficeID      uuid.UUID        `json:"officeId"`
	Source        AttendanceSource `json:"source"`
	AttendanceDay string           `json:"attendanceDay"` // Format: YYYY-MM-DD (shifts across midnight anchor to this day)

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
	DurationSeconds      *int64           `json:"durationSeconds,omitempty"`
	CheckoutReason       CheckoutReason   `json:"checkoutReason,omitempty"`
	InitialOutOfRadiusAt *time.Time       `json:"initialOutOfRadiusAt,omitempty"`
	Status               AttendanceStatus `json:"status"`

	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// IsActive returns true if the session is currently ongoing (either fresh checked-in or carried over across midnight)
func (s *AttendanceSession) IsActive() bool {
	return s.Status == StatusCheckedIn || s.Status == StatusCarriedOver
}

// CompleteCheckout transitions the session from CHECKED_IN or CARRIED_OVER to COMPLETED with MANUAL reason
func (s *AttendanceSession) CompleteCheckout(
	serverTime time.Time,
	gps GPSLocation,
	distanceMeters float64,
) error {
	return s.CompleteCheckoutWithReason(serverTime, gps, distanceMeters, CheckoutReasonManual)
}

// CompleteCheckoutWithReason transitions the session to COMPLETED with a specific checkout reason
func (s *AttendanceSession) CompleteCheckoutWithReason(
	serverTime time.Time,
	gps GPSLocation,
	distanceMeters float64,
	reason CheckoutReason,
) error {
	if !s.IsActive() {
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
	if reason == "" {
		s.CheckoutReason = CheckoutReasonManual
	} else {
		s.CheckoutReason = reason
	}
	s.Status = StatusCompleted
	s.UpdatedAt = serverTime

	return nil
}
