package http

import (
	"net/http"

	"github.com/gin-gonic/gin"

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
