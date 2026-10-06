package middleware

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"location-attendance/internal/domain"
	"location-attendance/pkg/jwt"
)

const (
	ContextKeyEmployeeID   = "employee_id"
	ContextKeyEmployeeCode = "employee_code"
	ContextKeyEmployeeRole = "employee_role"
)

// JWTAuth middleware verifies the Bearer token in the Authorization header
func JWTAuth(jwtSecret string) gin.HandlerFunc {
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

		c.Set(ContextKeyEmployeeID, claims.EmployeeID)
		c.Set(ContextKeyEmployeeCode, claims.EmployeeCode)
		c.Set(ContextKeyEmployeeRole, claims.Role)

		c.Next()
	}
}
