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

	router := gin.New()

	router.Use(middleware.RequestLogger())
	router.Use(middleware.Recovery())

	router.GET("/health", HealthCheck)

	loginLimiter := middleware.NewIPRateLimiter(rate.Limit(5), 5)
	attendanceLimiter := middleware.NewIPRateLimiter(rate.Limit(10), 10)

	apiV1 := router.Group("/api/v1")
	{

		authGroup := apiV1.Group("/auth")
		{
			authGroup.POST("/login", middleware.RateLimit(loginLimiter), cfg.AuthHandler.Login)
		}

		protected := apiV1.Group("")
		protected.Use(middleware.JWTAuth(cfg.JWTSecret))
		{

			protected.GET("/me", cfg.EmployeeHandler.GetMe)

			protected.GET("/offices/assigned", cfg.EmployeeHandler.GetAssignedOffice)

			attGroup := protected.Group("/attendance")
			attGroup.Use(middleware.RateLimit(attendanceLimiter))
			{
				attGroup.POST("/check-in", cfg.AttendanceHandler.CheckIn)
				attGroup.POST("/check-out", cfg.AttendanceHandler.CheckOut)
				attGroup.GET("/me", cfg.AttendanceHandler.GetMyAttendance)
				attGroup.GET("/today-status", cfg.AttendanceHandler.GetTodayStatus)
			}
		}
	}

	return router
}
