package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"location-attendance/internal/middleware"
	"location-attendance/internal/service"
)

type EmployeeHandler struct {
	employeeService service.EmployeeService
}

func NewEmployeeHandler(employeeService service.EmployeeService) *EmployeeHandler {
	return &EmployeeHandler{employeeService: employeeService}
}

func (h *EmployeeHandler) GetMe(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	profile, err := h.employeeService.GetProfile(c.Request.Context(), empID)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, profile)
}

func (h *EmployeeHandler) GetAssignedOffice(c *gin.Context) {
	empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID)
	if !exists {
		SendError(c, http.StatusUnauthorized, "AUTH_INVALID", "User not authenticated", nil)
		return
	}
	empID := empIDVal.(uuid.UUID)

	office, err := h.employeeService.GetAssignedOffice(c.Request.Context(), empID)
	if err != nil {
		MapDomainError(c, err)
		return
	}

	SendSuccess(c, http.StatusOK, office)
}
