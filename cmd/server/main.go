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
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"

	"location-attendance/internal/config"
	"location-attendance/internal/domain"
	handler "location-attendance/internal/handler/http"
	"location-attendance/internal/repository"
	"location-attendance/internal/repository/mock"
	"location-attendance/internal/repository/postgres"
	"location-attendance/internal/service"
	"location-attendance/internal/storage"
)

func main() {
	cfg := config.LoadConfig()
	log.Printf("Starting Location-Based Attendance Backend on port %s", cfg.Port)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 1. Initialize Database Repositories (Auto fallback to in-memory mocks if DB is unavailable)
	var (
		empRepo      repository.EmployeeRepository
		offRepo      repository.OfficeRepository
		attRepo      repository.AttendanceRepository
		settingsRepo repository.SettingsRepository
		leaveRepo    repository.LeaveRepository
	)

	db, err := postgres.NewDB(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Printf("INFO: PostgreSQL is not reachable (%v).", err)
		log.Println("🔄 Activating IN-MEMORY MOCK REPOSITORY MODE for standalone testing...")

		mockEmp := mock.NewMockEmployeeRepo()
		mockOff := mock.NewMockOfficeRepo()
		mockAtt := mock.NewMockAttendanceRepo()
		mockSettings := mock.NewMockSettingsRepo()
		mockLeave := mock.NewMockLeaveRepo()

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
			ID:                        empID,
			EmployeeCode:              "EMP1001",
			PasswordHash:              string(hash),
			FullName:                  "John Doe",
			Role:                      domain.RoleEmployee,
			OfficeID:                  officeID,
			LocationAttendanceEnabled: true,
			IsActive:                  true,
			CreatedAt:                 time.Now().UTC(),
			UpdatedAt:                 time.Now().UTC(),
		}
		mockEmp.Seed(emp)

		// Seed initial 2026 leave balances for EMP1001
		clID := uuid.MustParse("c0000000-0000-0000-0000-000000000001")
		slID := uuid.MustParse("c0000000-0000-0000-0000-000000000002")
		plID := uuid.MustParse("c0000000-0000-0000-0000-000000000003")
		mockLeave.SeedBalance(&domain.EmployeeLeaveBalance{
			ID:            uuid.New(),
			EmployeeID:    empID,
			LeaveTypeID:   clID,
			Year:          2026,
			AllocatedDays: 12,
			UsedDays:      0,
			RemainingDays: 12,
		})
		mockLeave.SeedBalance(&domain.EmployeeLeaveBalance{
			ID:            uuid.New(),
			EmployeeID:    empID,
			LeaveTypeID:   slID,
			Year:          2026,
			AllocatedDays: 8,
			UsedDays:      0,
			RemainingDays: 8,
		})
		mockLeave.SeedBalance(&domain.EmployeeLeaveBalance{
			ID:            uuid.New(),
			EmployeeID:    empID,
			LeaveTypeID:   plID,
			Year:          2026,
			AllocatedDays: 15,
			UsedDays:      0,
			RemainingDays: 15,
		})

		log.Println("✅ In-memory mock repositories initialized:")
		log.Printf("   - Test Employee: Code 'EMP1001' | Password 'Password123!'")
		log.Printf("   - Assigned Office: '%s' (Lat: %f, Lon: %f, Radius: %.1fm)", office.Name, office.Latitude, office.Longitude, office.RadiusMeters)
		log.Println("   - Leave Balances: CL (12d), SL (8d), PL (15d)")

		empRepo = mockEmp
		offRepo = mockOff
		attRepo = mockAtt
		settingsRepo = mockSettings
		leaveRepo = mockLeave
	} else {
		defer db.Close()
		log.Println("Successfully connected to PostgreSQL database cluster")
		empRepo = postgres.NewEmployeeRepository(db)
		offRepo = postgres.NewOfficeRepository(db)
		attRepo = postgres.NewAttendanceRepository(db)
		settingsRepo = postgres.NewSettingsRepository(db)
		leaveRepo = postgres.NewLeaveRepository(db)
	}

	telegramSvc := service.NewTelegramService(settingsRepo, cfg.TelegramBotToken, cfg.TelegramChatID)
	settingsSvc := service.NewSettingsService(settingsRepo)

	var pool *pgxpool.Pool
	if db != nil {
		pool = db.Pool
	}

	storageProvider, err := storage.NewStorageProvider(storage.Config{
		Driver:   cfg.StorageDriver,
		LocalDir: cfg.StorageLocalDir,
		BaseURL:  cfg.StorageBaseURL,
		DBPool:   pool,
	})
	if err != nil {
		log.Fatalf("Failed to initialize storage provider: %v", err)
	}

	authSvc := service.NewAuthService(empRepo, cfg.JWTSecret, cfg.JWTExpiration)
	empSvc := service.NewEmployeeService(empRepo, offRepo)
	attSvc := service.NewAttendanceService(empRepo, offRepo, attRepo, nil, telegramSvc, settingsRepo, leaveRepo)
	leaveSvc := service.NewLeaveService(leaveRepo, empRepo, nil, storageProvider)

	var attachmentHandler *handler.AttachmentHandler
	if pgStorage, ok := storageProvider.(*storage.PostgresStorage); ok {
		attachmentHandler = handler.NewAttachmentHandler(pgStorage)
	}

	authHandler := handler.NewAuthHandler(authSvc)
	empHandler := handler.NewEmployeeHandler(empSvc)
	attHandler := handler.NewAttendanceHandler(attSvc)
	settingsHandler := handler.NewSettingsHandler(settingsSvc)
	leaveHandler := handler.NewLeaveHandler(leaveSvc, storageProvider, cfg.MaxUploadSizeMB)
	uploadHandler := handler.NewUploadHandler(storageProvider, cfg.MaxUploadSizeMB)

	router := handler.SetupRouter(handler.RouterConfig{
		AuthHandler:       authHandler,
		EmployeeHandler:   empHandler,
		AttendanceHandler: attHandler,
		SettingsHandler:   settingsHandler,
		LeaveHandler:      leaveHandler,
		UploadHandler:     uploadHandler,
		AttachmentHandler: attachmentHandler,
		EmployeeRepo:      empRepo,
		JWTSecret:         cfg.JWTSecret,
		StorageLocalDir:   cfg.StorageLocalDir,
	})

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Background Worker: Auto Force-Checkout for Expired Out-of-Radius Breaches
	workerCtx, workerCancel := context.WithCancel(ctx)
	defer workerCancel()

	go func() {
		ticker := time.NewTicker(10 * time.Second)
		defer ticker.Stop()
		log.Println("⏱️  Auto Force-Checkout background worker active (interval: 10s)")

		for {
			select {
			case <-workerCtx.Done():
				return
			case <-ticker.C:
				count, err := attSvc.ProcessAutoForceCheckouts(workerCtx)
				if err != nil && !errors.Is(err, context.Canceled) {
					log.Printf("[Worker Error] Auto force-checkout processing failed: %v", err)
				} else if count > 0 {
					log.Printf("🚨 [Worker] Automatically force-checked out %d employee(s) out-of-radius", count)
				}
			}
		}
	}()

	go func() {
		log.Printf("HTTP server listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("Server error: %v", err)
		}
	}()

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
