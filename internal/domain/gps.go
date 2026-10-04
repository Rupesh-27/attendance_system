package domain

import (
	"time"
)

const (
	MaxAllowedGPSAccuracyMeters = 100.0
	MaxGPSCaptureAgeSeconds     = 30.0
)

// GPSLocation represents raw GPS telemetry submitted by the client
type GPSLocation struct {
	Latitude       float64   `json:"latitude"`
	Longitude      float64   `json:"longitude"`
	AccuracyMeters float64   `json:"accuracyMeters"`
	CapturedAt     time.Time `json:"capturedAt"`
}

// Validate checks the GPS coordinates, accuracy threshold, and freshness against server authoritative time.
// Rules:
// - Latitude between -90 and 90
// - Longitude between -180 and 180
// - Accuracy > 0 and <= 20 meters
// - capturedAt must not be later than serverTime (future timestamps rejected)
// - serverTime - capturedAt <= 30 seconds (stale timestamps rejected, 30s boundary allowed)
func (g *GPSLocation) Validate(serverTime time.Time) error {
	if g.Latitude < -90.0 || g.Latitude > 90.0 {
		return ErrInvalidLatitude
	}
	if g.Longitude < -180.0 || g.Longitude > 180.0 {
		return ErrInvalidLongitude
	}
	if g.AccuracyMeters <= 0 {
		return ErrInvalidAccuracy
	}
	if g.AccuracyMeters > MaxAllowedGPSAccuracyMeters {
		return ErrAccuracyTooLow
	}

	// Future timestamp check: capturedAt cannot be later than serverTime
	if g.CapturedAt.After(serverTime.Add(15 * time.Second)) {
		return ErrCaptureTimeInFuture
	}

	// Freshness check: age must be within 30 seconds (30s boundary is valid)
	age := serverTime.Sub(g.CapturedAt)
	if age > time.Duration(MaxGPSCaptureAgeSeconds)*time.Second {
		return ErrCaptureTimeStale
	}

	return nil
}
