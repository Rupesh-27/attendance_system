package domain

import (
	"math"
)

const (
	EarthRadiusMeters = 6371000.0
)

// CalculateHaversineDistance computes the great-circle distance between two geographic coordinates
// using the Haversine formula. The result is returned in meters.
// The backend is authoritative for distance and radius validation.
func CalculateHaversineDistance(lat1, lon1, lat2, lon2 float64) float64 {
	// If coordinates are identical, distance is exactly 0
	if lat1 == lat2 && lon1 == lon2 {
		return 0.0
	}

	// Convert latitude and longitude from degrees to radians
	dLat := (lat2 - lat1) * (math.Pi / 180.0)
	dLon := (lon2 - lon1) * (math.Pi / 180.0)

	radLat1 := lat1 * (math.Pi / 180.0)
	radLat2 := lat2 * (math.Pi / 180.0)

	// Haversine formula
	a := math.Sin(dLat/2.0)*math.Sin(dLat/2.0) +
		math.Cos(radLat1)*math.Cos(radLat2)*
			math.Sin(dLon/2.0)*math.Sin(dLon/2.0)

	c := 2.0 * math.Atan2(math.Sqrt(a), math.Sqrt(1.0-a))

	return EarthRadiusMeters * c
}
