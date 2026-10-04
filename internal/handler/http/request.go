package http

import "time"

type LoginRequest struct {
	EmployeeCode string `json:"employeeCode" binding:"required"`
	Password     string `json:"password" binding:"required"`
}

type GPSRequest struct {
	Latitude       float64   `json:"latitude" binding:"required"`
	Longitude      float64   `json:"longitude" binding:"required"`
	AccuracyMeters float64   `json:"accuracyMeters" binding:"required"`
	CapturedAt     time.Time `json:"capturedAt" binding:"required"`
}
