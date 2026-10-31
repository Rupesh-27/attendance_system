package http

import (
	"net/http"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"location-attendance/internal/domain"
	"location-attendance/internal/middleware"
	"location-attendance/internal/service"
	"location-attendance/internal/storage"
)

type LeaveHandler struct {
	leaveService   service.LeaveService
	storage        storage.StorageProvider
	maxUploadBytes int64
}

func NewLeaveHandler(leaveService service.LeaveService, extra ...interface{}) *LeaveHandler {
	h := &LeaveHandler{
		leaveService:   leaveService,
		maxUploadBytes: 10 * 1024 * 1024,
	}
	for _, e := range extra {
		if s, ok := e.(storage.StorageProvider); ok {
			h.storage = s
		} else if m, ok := e.(int); ok && m > 0 {
			h.maxUploadBytes = int64(m) * 1024 * 1024
		}
	}
	return h
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

func (h *LeaveHandler) UpdateAttachment(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	idStr := c.Param("id")
	appID, err := uuid.Parse(idStr)
	if err != nil {
		SendError(c, http.StatusBadRequest, "INVALID_ID", "Invalid leave application ID", nil)
		return
	}

	if h.storage == nil {
		SendError(c, http.StatusServiceUnavailable, "STORAGE_UNAVAILABLE", "Storage provider not configured", nil)
		return
	}

	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, h.maxUploadBytes)
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		SendError(c, http.StatusBadRequest, "INVALID_FILE", "Invalid file upload: please provide a file under 'file'", nil)
		return
	}
	defer file.Close()

	if header.Size > h.maxUploadBytes {
		SendError(c, http.StatusBadRequest, "FILE_TOO_LARGE", "File exceeds maximum allowed size", nil)
		return
	}

	ext := strings.ToLower(filepath.Ext(header.Filename))
	allowedExtensions := map[string]bool{
		".pdf":  true,
		".png":  true,
		".jpg":  true,
		".jpeg": true,
		".doc":  true,
		".docx": true,
	}
	if !allowedExtensions[ext] {
		SendError(c, http.StatusBadRequest, "INVALID_FILE_TYPE", "Unsupported format. Allowed: PDF, PNG, JPG, JPEG, DOC, DOCX", nil)
		return
	}

	uploadCtx := storage.WithApplicationID(storage.WithEmployeeID(c.Request.Context(), empID), appID)
	newURL, err := h.storage.Save(uploadCtx, header.Filename, file)
	if err != nil {
		SendError(c, http.StatusInternalServerError, "STORAGE_ERROR", "Failed to save file: "+err.Error(), nil)
		return
	}

	if err := h.leaveService.UpdateAttachment(c.Request.Context(), empID, appID, newURL); err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, gin.H{
		"attachmentUrl": newURL,
		"message":       "Attachment updated successfully",
	})
}

func (h *LeaveHandler) DeleteAttachment(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	idStr := c.Param("id")
	appID, err := uuid.Parse(idStr)
	if err != nil {
		SendError(c, http.StatusBadRequest, "INVALID_ID", "Invalid leave application ID", nil)
		return
	}

	if err := h.leaveService.DeleteAttachment(c.Request.Context(), empID, appID); err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, gin.H{
		"message": "Attachment removed successfully",
	})
}
