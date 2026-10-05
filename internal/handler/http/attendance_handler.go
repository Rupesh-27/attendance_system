package http

import (
	"math"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"location-attendance/internal/domain"
	"location-attendance/internal/middleware"
	"location-attendance/internal/service"
)

type AttendanceHandler struct {
	attendanceService service.AttendanceService
}

func NewAttendanceHandler(attendanceService service.AttendanceService) *AttendanceHandler {
	return &AttendanceHandler{attendanceService: attendanceService}
}

func (h *AttendanceHandler) CheckIn(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	var req GPSRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		SendError(c, http.StatusBadRequest, "LOCATION_REQUIRED", "Valid latitude, longitude, accuracyMeters and capturedAt are required", nil)
		return
	}

	gps := domain.GPSLocation{
		Latitude:       req.Latitude,
		Longitude:      req.Longitude,
		AccuracyMeters: req.AccuracyMeters,
		CapturedAt:     req.CapturedAt,
	}

	session, err := h.attendanceService.CheckIn(c.Request.Context(), empID, gps)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	// BrandHRMS Guide Page 8 response schema
	c.JSON(http.StatusOK, AttendanceCheckInResponse{
		Success:             true,
		AttendanceID:        session.ID.String(),
		Status:              string(session.Status),
		DistanceMeters:      math.Round(session.CheckInDistanceMeters*10) / 10,
		AllowedRadiusMeters: session.OfficeSnapshotRadius,
		ServerTime:          session.CheckInTime,
	})
}

func (h *AttendanceHandler) CheckOut(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	var req GPSRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		SendError(c, http.StatusBadRequest, "LOCATION_REQUIRED", "Valid latitude, longitude, accuracyMeters and capturedAt are required", nil)
		return
	}

	gps := domain.GPSLocation{
		Latitude:       req.Latitude,
		Longitude:      req.Longitude,
		AccuracyMeters: req.AccuracyMeters,
		CapturedAt:     req.CapturedAt,
	}

	session, err := h.attendanceService.CheckOut(c.Request.Context(), empID, gps)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	duration := int64(0)
	if session.DurationSeconds != nil {
		duration = *session.DurationSeconds
	}
	distance := float64(0)
	if session.CheckOutDistanceMeters != nil {
		distance = math.Round(*session.CheckOutDistanceMeters*10) / 10
	}

	// BrandHRMS Guide Page 8 response schema
	c.JSON(http.StatusOK, AttendanceCheckOutResponse{
		Success:             true,
		AttendanceID:        session.ID.String(),
		Status:              string(session.Status),
		DistanceMeters:      distance,
		AllowedRadiusMeters: session.OfficeSnapshotRadius,
		DurationSeconds:     duration,
		ServerTime:          *session.CheckOutTime,
	})
}

func (h *AttendanceHandler) GetMyAttendance(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "10"))

	var fromTime, toTime *time.Time
	if fromStr := c.Query("from"); fromStr != "" {
		t, err := parseDateFilter(fromStr, false)
		if err != nil {
			SendError(c, http.StatusBadRequest, "LOCATION_REQUIRED", "Invalid 'from' timestamp format. Use ISO 8601 (e.g. 2026-08-14 or 2026-08-14T00:00:00Z)", nil)
			return
		}
		fromTime = &t
	}
	if toStr := c.Query("to"); toStr != "" {
		t, err := parseDateFilter(toStr, true)
		if err != nil {
			SendError(c, http.StatusBadRequest, "LOCATION_REQUIRED", "Invalid 'to' timestamp format. Use ISO 8601 (e.g. 2026-08-14 or 2026-08-14T23:59:59Z)", nil)
			return
		}
		toTime = &t
	}

	history, err := h.attendanceService.GetMyHistory(c.Request.Context(), empID, fromTime, toTime, page, pageSize)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, history)
}

func (h *AttendanceHandler) GetTodayStatus(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	status, err := h.attendanceService.GetTodayStatus(c.Request.Context(), empID)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, status)
}


func parseDateFilter(s string, isEndOfDay bool) (time.Time, error) {
	// Try RFC3339 first
	if t, err := time.Parse(time.RFC3339, s); err == nil {
		return t.UTC(), nil
	}
	// Try date only YYYY-MM-DD
	if t, err := time.Parse("2006-01-02", s); err == nil {
		if isEndOfDay {
			t = time.Date(t.Year(), t.Month(), t.Day(), 23, 59, 59, 999999999, time.UTC)
		} else {
			t = t.UTC()
		}
		return t, nil
	}
	return time.Time{}, strconv.ErrSyntax
}
