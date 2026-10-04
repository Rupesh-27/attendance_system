package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"location-attendance/internal/config"
	"location-attendance/internal/domain"
	handler "location-attendance/internal/handler/http"
	"location-attendance/internal/repository"
	"location-attendance/internal/repository/mock"
	"location-attendance/internal/repository/postgres"
	"location-attendance/internal/service"
)

func main() {
	cfg := config.LoadConfig()
	log.Printf("Starting Location-Based Attendance Backend on port %s", cfg.Port)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 1. Initialize Database Repositories (Auto fallback to in-memory mocks if DB is unavailable)
	var (
		empRepo repository.EmployeeRepository
		offRepo repository.OfficeRepository
		attRepo repository.AttendanceRepository
	)

	db, err := postgres.NewDB(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Printf("INFO: PostgreSQL is not reachable (%v).", err)
		log.Println("🔄 Activating IN-MEMORY MOCK REPOSITORY MODE for standalone testing...")

		mockEmp := mock.NewMockEmployeeRepo()
		mockOff := mock.NewMockOfficeRepo()
		mockAtt := mock.NewMockAttendanceRepo()

		officeID := uuid.MustParse("a0000000-0000-0000-0000-000000000001")
		office := &domain.Office{
			ID:           officeID,
			Name:         "Chennai Tech Hub",
			Latitude:     13.082700,
			Longitude:    80.270700,
			RadiusMeters: 10.0,
			IsActive:     true,
			CreatedAt:    time.Now().UTC(),
			UpdatedAt:    time.Now().UTC(),
		}
		mockOff.Seed(office)

		hash, _ := bcrypt.GenerateFromPassword([]byte("Password123!"), bcrypt.DefaultCost)
		empID := uuid.MustParse("b0000000-0000-0000-0000-000000000001")
		emp := &domain.Employee{
			ID:           empID,
			EmployeeCode: "EMP1001",
			PasswordHash: string(hash),
			FullName:     "John Doe",
			Role:         domain.RoleEmployee,
			OfficeID:     officeID,
			IsActive:     true,
			CreatedAt:    time.Now().UTC(),
			UpdatedAt:    time.Now().UTC(),
		}
		mockEmp.Seed(emp)

		log.Println("✅ In-memory mock repositories initialized:")
		log.Printf("   - Test Employee: Code 'EMP1001' | Password 'Password123!'")
		log.Printf("   - Assigned Office: '%s' (Lat: %f, Lon: %f, Radius: %.1fm)", office.Name, office.Latitude, office.Longitude, office.RadiusMeters)

		empRepo = mockEmp
		offRepo = mockOff
		attRepo = mockAtt
	} else {
		defer db.Close()
		log.Println("Successfully connected to PostgreSQL database cluster")
		empRepo = postgres.NewEmployeeRepository(db)
		offRepo = postgres.NewOfficeRepository(db)
		attRepo = postgres.NewAttendanceRepository(db)
	}

	// 2. Initialize Services
	authSvc := service.NewAuthService(empRepo, cfg.JWTSecret, cfg.JWTExpiration)
	empSvc := service.NewEmployeeService(empRepo, offRepo)
	attSvc := service.NewAttendanceService(empRepo, offRepo, attRepo, nil)

	// 3. Initialize HTTP Handlers
	authHandler := handler.NewAuthHandler(authSvc)
	empHandler := handler.NewEmployeeHandler(empSvc)
	attHandler := handler.NewAttendanceHandler(attSvc)

	// 4. Initialize HTTP Router
	router := handler.SetupRouter(handler.RouterConfig{
		AuthHandler:       authHandler,
		EmployeeHandler:   empHandler,
		AttendanceHandler: attHandler,
		JWTSecret:         cfg.JWTSecret,
	})

	// 5. Start HTTP Server with Graceful Shutdown
	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Printf("HTTP server listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("Server error: %v", err)
		}
	}()

	// Listen for termination signals
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutdown signal received, shutting down gracefully...")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited successfully")
}
