package http

import (
	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"

	"location-attendance/internal/middleware"
	"location-attendance/internal/repository"
)

type RouterConfig struct {
	AuthHandler       *AuthHandler
	EmployeeHandler   *EmployeeHandler
	AttendanceHandler *AttendanceHandler
	SettingsHandler   *SettingsHandler
	LeaveHandler      *LeaveHandler
	UploadHandler     *UploadHandler
	EmployeeRepo      repository.EmployeeRepository
	JWTSecret         string
	StorageLocalDir   string
}

func SetupRouter(cfg RouterConfig) *gin.Engine {

	router := gin.New()

	router.Use(middleware.RequestLogger())
	router.Use(middleware.Recovery())

	// Static serving for locally stored uploads (e.g. leave attachments)
	if cfg.StorageLocalDir != "" {
		router.Static("/uploads", cfg.StorageLocalDir)
	}

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
		protected.Use(middleware.JWTAuth(cfg.JWTSecret, cfg.EmployeeRepo))
		{
			protected.POST("/auth/logout", cfg.AuthHandler.Logout)

			protected.GET("/me", cfg.EmployeeHandler.GetMe)

			protected.GET("/offices/assigned", cfg.EmployeeHandler.GetAssignedOffice)

			attGroup := protected.Group("/attendance")
			attGroup.Use(middleware.RateLimit(attendanceLimiter))
			{
				attGroup.POST("/check-in", cfg.AttendanceHandler.CheckIn)
				attGroup.POST("/check-out", cfg.AttendanceHandler.CheckOut)
				attGroup.POST("/force-checkout", cfg.AttendanceHandler.ForceCheckOut)
				attGroup.POST("/breach-warning", cfg.AttendanceHandler.RecordBreach)
				attGroup.DELETE("/breach-warning", cfg.AttendanceHandler.ClearBreach)
				attGroup.POST("/clear-breach", cfg.AttendanceHandler.ClearBreach)
				attGroup.GET("/me", cfg.AttendanceHandler.GetMyAttendance)
				attGroup.GET("/today-status", cfg.AttendanceHandler.GetTodayStatus)
			}

			if cfg.SettingsHandler != nil {
				settingsGroup := protected.Group("/settings")
				{
					settingsGroup.GET("", cfg.SettingsHandler.GetSettings)
					settingsGroup.PUT("", cfg.SettingsHandler.UpdateSettings)
				}
			}

			if cfg.LeaveHandler != nil {
				leaveGroup := protected.Group("/leave")
				{
					leaveGroup.GET("/types", cfg.LeaveHandler.GetLeaveTypes)
					leaveGroup.GET("/balances", cfg.LeaveHandler.GetLeaveBalances)
					leaveGroup.POST("/apply", cfg.LeaveHandler.ApplyLeave)
					leaveGroup.GET("/my-applications", cfg.LeaveHandler.GetMyApplications)
					leaveGroup.POST("/:id/cancel", cfg.LeaveHandler.CancelApplication)
					leaveGroup.GET("/approvals", cfg.LeaveHandler.GetPendingApprovals)
					leaveGroup.POST("/:id/approve", cfg.LeaveHandler.ApproveApplication)
					leaveGroup.POST("/:id/reject", cfg.LeaveHandler.RejectApplication)
				}
			}

			if cfg.UploadHandler != nil {
				protected.POST("/upload", cfg.UploadHandler.Upload)
			}
		}
	}

	return router
}

