package middleware

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
	"location-attendance/pkg/jwt"
)

const (
	ContextKeyEmployeeID   = "employee_id"
	ContextKeyEmployeeCode = "employee_code"
	ContextKeyEmployeeRole = "employee_role"
	ContextKeySessionID    = "session_id"
)

// JWTAuth middleware verifies the Bearer token in the Authorization header
func JWTAuth(jwtSecret string, empRepo ...repository.EmployeeRepository) gin.HandlerFunc {
	var repo repository.EmployeeRepository
	if len(empRepo) > 0 {
		repo = empRepo[0]
	}

	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"code":    "AUTH_INVALID",
				"message": "Authorization header is required",
				"error": gin.H{
					"code":    "AUTH_INVALID",
					"message": "Authorization header is required",
				},
			})
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"success": false,
				"code":    "AUTH_INVALID",
				"message": "Authorization header format must be 'Bearer <token>'",
				"error": gin.H{
					"code":    "AUTH_INVALID",
					"message": "Authorization header format must be 'Bearer <token>'",
				},
			})
			return
		}

		claims, err := jwt.ValidateToken(parts[1], jwtSecret)
		if err != nil {
			errCode := "AUTH_INVALID"
			status := http.StatusUnauthorized
			if errors.Is(err, jwt.ErrTokenExpired) {
				errCode = "AUTH_EXPIRED"
			} else if errors.Is(err, domain.ErrForbiddenRole) {
				errCode = "FORBIDDEN"
				status = http.StatusForbidden
			}

			c.AbortWithStatusJSON(status, gin.H{
				"success": false,
				"code":    errCode,
				"message": err.Error(),
				"error": gin.H{
					"code":    errCode,
					"message": err.Error(),
				},
			})
			return
		}

		if repo != nil && claims.SessionID != uuid.Nil {
			emp, err := repo.GetByID(c.Request.Context(), claims.EmployeeID)
			if err != nil || emp.ActiveSessionID == nil || *emp.ActiveSessionID != claims.SessionID {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
					"success": false,
					"code":    "SESSION_TERMINATED",
					"message": "Session has expired or been terminated. Please log in again.",
					"error": gin.H{
						"code":    "SESSION_TERMINATED",
						"message": "Session has expired or been terminated. Please log in again.",
					},
				})
				return
			}
		}

		c.Set(ContextKeyEmployeeID, claims.EmployeeID)
		c.Set(ContextKeyEmployeeCode, claims.EmployeeCode)
		c.Set(ContextKeyEmployeeRole, claims.Role)
		c.Set(ContextKeySessionID, claims.SessionID)

		c.Next()
	}
}
