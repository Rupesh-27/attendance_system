package domain

import (
	"time"

	"github.com/google/uuid"
)

const (
	DefaultOfficeRadiusMeters = 10.0
)

// Office represents a physical work location with geofencing parameters
type Office struct {
	ID           uuid.UUID `json:"id"`
	Name         string    `json:"name"`
	Latitude     float64   `json:"latitude"`
	Longitude    float64   `json:"longitude"`
	RadiusMeters float64   `json:"radiusMeters"`
	Timezone     string    `json:"timezone,omitempty"`
	IsActive     bool      `json:"isActive"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// GetLocation resolves the IANA time.Location for this office (e.g. Europe/Berlin, Asia/Kolkata).
// Defaults safely to Asia/Kolkata or UTC if unspecified or invalid.
func (o *Office) GetLocation() *time.Location {
	if o != nil && o.Timezone != "" {
		if loc, err := time.LoadLocation(o.Timezone); err == nil {
			return loc
		}
	}
	if loc, err := time.LoadLocation("Asia/Kolkata"); err == nil {
		return loc
	}
	return time.UTC
}

// IsWithinRadius checks if a given distance in meters falls within the office boundary
func (o *Office) IsWithinRadius(distanceMeters float64) bool {
	radius := o.RadiusMeters
	if radius <= 0 {
		radius = DefaultOfficeRadiusMeters
	}
	return distanceMeters <= radius
}
