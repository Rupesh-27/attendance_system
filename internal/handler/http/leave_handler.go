package http

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"location-attendance/internal/domain"
	"location-attendance/internal/middleware"
	"location-attendance/internal/service"
)

type LeaveHandler struct {
	leaveService service.LeaveService
}

func NewLeaveHandler(leaveService service.LeaveService) *LeaveHandler {
	return &LeaveHandler{leaveService: leaveService}
}

type LeaveApprovalRequest struct {
	Remarks *string `json:"remarks"`
}

func (h *LeaveHandler) GetLeaveTypes(c *gin.Context) {
	types, err := h.leaveService.GetLeaveTypes(c.Request.Context())
	if err != nil {
		MapDomainError(c, err)
		return
	}
	SendSuccess(c, http.StatusOK, types)
}

func (h *LeaveHandler) GetLeaveBalances(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	var year int
	if yearStr := c.Query("year"); yearStr != "" {
		if y, err := strconv.Atoi(yearStr); err == nil {
			year = y
		}
	}

	balances, err := h.leaveService.GetLeaveBalances(c.Request.Context(), empID, year)
	if err != nil {
		MapDomainError(c, err)
		return
	}
	SendSuccess(c, http.StatusOK, balances)
}

func (h *LeaveHandler) ApplyLeave(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	var req service.ApplyLeaveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		SendError(c, http.StatusBadRequest, "INVALID_REQUEST", "Invalid leave application payload", err.Error())
		return
	}

	app, err := h.leaveService.ApplyLeave(c.Request.Context(), empID, req)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusCreated, app)
}

func (h *LeaveHandler) GetMyApplications(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	var statusPtr *domain.LeaveStatus
	if s := c.Query("status"); s != "" {
		status := domain.LeaveStatus(s)
		statusPtr = &status
	}

	apps, err := h.leaveService.GetMyApplications(c.Request.Context(), empID, statusPtr)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, apps)
}

func (h *LeaveHandler) CancelApplication(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	appID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		SendError(c, http.StatusBadRequest, "INVALID_ID", "Invalid leave application ID", nil)
		return
	}

	if err := h.leaveService.CancelApplication(c.Request.Context(), empID, appID); err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, gin.H{"message": "Leave application cancelled successfully"})
}

func (h *LeaveHandler) GetPendingApprovals(c *gin.Context) {
	apps, err := h.leaveService.GetPendingApprovals(c.Request.Context())
	if err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, apps)
}

func (h *LeaveHandler) ApproveApplication(c *gin.Context) {
	reviewerIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	reviewerID := reviewerIDVal.(uuid.UUID)

	appID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		SendError(c, http.StatusBadRequest, "INVALID_ID", "Invalid leave application ID", nil)
		return
	}

	var req LeaveApprovalRequest
	_ = c.ShouldBindJSON(&req)

	app, err := h.leaveService.ApproveApplication(c.Request.Context(), appID, reviewerID, req.Remarks)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, app)
}

func (h *LeaveHandler) RejectApplication(c *gin.Context) {
	reviewerIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	reviewerID := reviewerIDVal.(uuid.UUID)

	appID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		SendError(c, http.StatusBadRequest, "INVALID_ID", "Invalid leave application ID", nil)
		return
	}

	var req LeaveApprovalRequest
	_ = c.ShouldBindJSON(&req)

	app, err := h.leaveService.RejectApplication(c.Request.Context(), appID, reviewerID, req.Remarks)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, app)
}
