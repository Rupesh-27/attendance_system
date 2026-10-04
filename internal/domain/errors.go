package domain

import "errors"

// Domain error definitions
var (
	// Authentication & Employee Errors
	ErrInvalidCredentials = errors.New("invalid employee code or password")
	ErrEmployeeNotFound   = errors.New("employee not found")
	ErrEmployeeInactive   = errors.New("employee account is inactive")
	ErrUnauthorized       = errors.New("unauthorized access")
	ErrForbiddenRole      = errors.New("forbidden: employee role required")

	// Office Errors
	ErrOfficeNotFound = errors.New("assigned office not found")
	ErrOfficeInactive = errors.New("assigned office is inactive")

	// GPS Validation Errors
	ErrInvalidLatitude     = errors.New("latitude must be between -90 and 90 degrees")
	ErrInvalidLongitude    = errors.New("longitude must be between -180 and 180 degrees")
	ErrInvalidAccuracy     = errors.New("gps accuracy must be greater than zero")
	ErrAccuracyTooLow      = errors.New("gps accuracy exceeds maximum allowed threshold of 20 meters")
	ErrCaptureTimeStale    = errors.New("gps capture timestamp is older than 30 seconds")
	ErrCaptureTimeInFuture = errors.New("gps capture timestamp cannot be in the future")

	// Distance & Location Errors
	ErrOutsideOfficeRadius = errors.New("current location is outside the assigned office radius")

	// Attendance Session Errors
	ErrActiveSessionExists = errors.New("an active attendance session is already open")
	ErrNoActiveSession     = errors.New("no active attendance session found to check out")
	ErrSessionAlreadyEnded = errors.New("attendance session has already been completed")
)
