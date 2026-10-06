package http

import (
	"errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"location-attendance/internal/domain"
)

type APIResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	// Standard error fields matching BrandHRMS guide page 7: { success: false, code, message, details? }
	Code    string      `json:"code,omitempty"`
	Message string      `json:"message,omitempty"`
	Details interface{} `json:"details,omitempty"`
	Error   *APIError   `json:"error,omitempty"`
}

type APIError struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

// AttendanceCheckInResponse matches BrandHRMS Guide Page 8 specification
type AttendanceCheckInResponse struct {
	Success             bool      `json:"success"`
	AttendanceID        string    `json:"attendanceId"`
	Status              string    `json:"status"`
	DistanceMeters      float64   `json:"distanceMeters"`
	AllowedRadiusMeters float64   `json:"allowedRadiusMeters"`
	ServerTime          time.Time `json:"serverTime"`
}

// AttendanceCheckOutResponse matches BrandHRMS Guide Page 8 & duration calculation
type AttendanceCheckOutResponse struct {
	Success             bool      `json:"success"`
	AttendanceID        string    `json:"attendanceId"`
	Status              string    `json:"status"`
	DistanceMeters      float64   `json:"distanceMeters"`
	AllowedRadiusMeters float64   `json:"allowedRadiusMeters"`
	DurationSeconds     int64     `json:"durationSeconds"`
	ServerTime          time.Time `json:"serverTime"`
}

func SendSuccess(c *gin.Context, httpStatus int, data interface{}) {
	c.JSON(httpStatus, APIResponse{
		Success: true,
		Data:    data,
	})
}

func SendError(c *gin.Context, httpStatus int, code, message string, details interface{}) {
	c.JSON(httpStatus, APIResponse{
		Success: false,
		Code:    code,
		Message: message,
		Details: details,
		Error: &APIError{
			Code:    code,
			Message: message,
			Details: details,
		},
	})
}

func MapDomainError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, domain.ErrInvalidCredentials),
		errors.Is(err, domain.ErrEmployeeInactive),
		errors.Is(err, domain.ErrUnauthorized):
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", err.Error(), nil)

	case errors.Is(err, domain.ErrForbiddenRole):
		SendError(c, http.StatusForbidden, "FORBIDDEN", err.Error(), nil)

	case errors.Is(err, domain.ErrInvalidLatitude),
		errors.Is(err, domain.ErrInvalidLongitude),
		errors.Is(err, domain.ErrInvalidAccuracy),
		errors.Is(err, domain.ErrCaptureTimeStale),
		errors.Is(err, domain.ErrCaptureTimeInFuture):
		SendError(c, http.StatusBadRequest, "LOCATION_REQUIRED", err.Error(), nil)

	case errors.Is(err, domain.ErrAccuracyTooLow):
		SendError(c, http.StatusUnprocessableEntity, "LOCATION_INACCURATE", err.Error(), nil)

	case errors.Is(err, domain.ErrOutsideOfficeRadius):
		SendError(c, http.StatusUnprocessableEntity, "OUTSIDE_RADIUS", err.Error(), nil)

	case errors.Is(err, domain.ErrActiveSessionExists):
		SendError(c, http.StatusConflict, "ALREADY_CHECKED_IN", err.Error(), nil)

	case errors.Is(err, domain.ErrNoActiveSession),
		errors.Is(err, domain.ErrSessionAlreadyEnded):
		SendError(c, http.StatusBadRequest, "NOT_CHECKED_IN", err.Error(), nil)

	case errors.Is(err, domain.ErrEmployeeNotFound),
		errors.Is(err, domain.ErrOfficeNotFound):
		SendError(c, http.StatusNotFound, "NOT_FOUND", err.Error(), nil)

	default:
		SendError(c, http.StatusInternalServerError, "INTERNAL_SERVER_ERROR", "An unexpected error occurred", nil)
	}
}
