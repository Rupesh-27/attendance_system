package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"location-attendance/internal/middleware"
	"location-attendance/internal/service"
)

type AuthHandler struct {
	authService service.AuthService
}

func NewAuthHandler(authService service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		SendError(c, http.StatusBadRequest, "INVALID_REQUEST_BODY", "Employee code and password are required", nil)
		return
	}

	result, err := h.authService.Login(c.Request.Context(), req.EmployeeCode, req.Password)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, result)
}

func (h *AuthHandler) Logout(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "UNAUTHORIZED", "Unauthorized access", nil)
		return
	}
	empID, ok := empIDVal.(uuid.UUID)
	if !ok {
		SendError(c, http.StatusUnauthorized, "UNAUTHORIZED", "Unauthorized access", nil)
		return
	}

	if err := h.authService.Logout(c.Request.Context(), empID); err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, gin.H{
		"message": "Logged out successfully",
	})
}
