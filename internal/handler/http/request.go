package http

import "time"

type LoginRequest struct {
	EmployeeCode string `json:"employeeCode" binding:"required"`
	Password     string `json:"password" binding:"required"`
	Force        bool   `json:"force,omitempty"`
}

type GPSRequest struct {
	Latitude       float64   `json:"latitude" binding:"required"`
	Longitude      float64   `json:"longitude" binding:"required"`
	AccuracyMeters float64   `json:"accuracyMeters" binding:"required"`
	CapturedAt     time.Time `json:"capturedAt" binding:"required"`
	Address        *string   `json:"address,omitempty"`
}

type ForceCheckoutRequest struct {
	Latitude       float64    `json:"latitude" binding:"required"`
	Longitude      float64    `json:"longitude" binding:"required"`
	AccuracyMeters float64    `json:"accuracyMeters" binding:"required"`
	CapturedAt     time.Time  `json:"capturedAt" binding:"required"`
	Address        *string    `json:"address,omitempty"`
	BreachedAt     *time.Time `json:"breachedAt,omitempty"`
	Reason         string     `json:"reason,omitempty"`
}

type RecordBreachRequest struct {
	BreachedAt *time.Time `json:"breachedAt,omitempty"`
}

