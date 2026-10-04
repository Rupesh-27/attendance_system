package http

import (
	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"

	"location-attendance/internal/middleware"
)

type RouterConfig struct {
	AuthHandler       *AuthHandler
	EmployeeHandler   *EmployeeHandler
	AttendanceHandler *AttendanceHandler
	JWTSecret         string
}

func SetupRouter(cfg RouterConfig) *gin.Engine {
	// Gin release mode in production, or test mode in testing
	router := gin.New()

	// Global Middlewares
	router.Use(middleware.RequestLogger())
	router.Use(middleware.Recovery())

	// Health endpoint
	router.GET("/health", HealthCheck)

	// Rate limiters: 5 req/s burst for login, 10 req/s burst for attendance
	loginLimiter := middleware.NewIPRateLimiter(rate.Limit(5), 5)
	attendanceLimiter := middleware.NewIPRateLimiter(rate.Limit(10), 10)

	apiV1 := router.Group("/api/v1")
	{
		// Public Auth endpoints
		authGroup := apiV1.Group("/auth")
		{
			authGroup.POST("/login", middleware.RateLimit(loginLimiter), cfg.AuthHandler.Login)
		}

		// Protected endpoints
		protected := apiV1.Group("")
		protected.Use(middleware.JWTAuth(cfg.JWTSecret))
		{
			// Employee endpoints
			protected.GET("/me", cfg.EmployeeHandler.GetMe)

			// Office endpoints
			protected.GET("/offices/assigned", cfg.EmployeeHandler.GetAssignedOffice)

			// Attendance endpoints
			attGroup := protected.Group("/attendance")
			attGroup.Use(middleware.RateLimit(attendanceLimiter))
			{
				attGroup.POST("/check-in", cfg.AttendanceHandler.CheckIn)
				attGroup.POST("/check-out", cfg.AttendanceHandler.CheckOut)
				attGroup.GET("/me", cfg.AttendanceHandler.GetMyAttendance)
			}
		}
	}

	return router
}
