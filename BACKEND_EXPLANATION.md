# Location-Based Attendance System — Backend Architecture & File Guide

This document provides a complete, clear, and structured breakdown of the Go backend. It explains the high-level architecture, directory layout, core business flows, and **every single file** in the codebase.

---

## 1. High-Level Architecture Overview

The backend is built with **Go (Golang)** using a **Clean / Hexagonal Architecture** pattern. This ensures loose coupling, testability, and clear separation of concerns:

```
                  ┌──────────────────────────────────────────────┐
                  │                 HTTP Clients                 │
                  │        (Flutter Mobile App, Postman)         │
                  └──────────────────────┬───────────────────────┘
                                         │ JSON / HTTPS
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│  Handler Layer (internal/handler/http)                                           │
│  - Parses HTTP requests & binds JSON DTOs                                       │
│  - Validates request payloads and maps domain errors to standard HTTP responses  │
└────────────────────────────────────────┬────────────────────────────────────────┘
                                         │ Calls interface methods
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│  Service Layer (internal/service)                                               │
│  - Core business logic: Geofencing validation, Midnight Rollover, Autocheckout  │
│  - Autonomous background workers & Telegram alerts                              │
└───────────────────┬─────────────────────────────────────────┬───────────────────┘
                    │                                         │
                    ▼                                         ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────────────┐
│  Domain Layer (internal/domain)      │  │  Repository Layer                    │
│  - Pure business models & entities   │  │  (internal/repository)               │
│  - Haversine distance math           │  │  - Database access (pgxpool)         │
│  - GPS accuracy rules & error types  │  │  - PostgreSQL queries & Mock repos   │
└──────────────────────────────────────┘  └──────────────────┬───────────────────┘
                                                             │ SQL
                                                             ▼
                                          ┌──────────────────────────────────────┐
                                          │      PostgreSQL Database Cluster     │
                                          │     (Offices, Employees, Sessions)   │
                                          └──────────────────────────────────────┘
```

### Why Clean Architecture?
1. **Independent of Frameworks**: Switching web frameworks (e.g. Gin to Chi or Fiber) requires changes **only** in the handler layer; the core business logic remains untouched.
2. **Testable**: Repositories and external services (like Telegram) have Go interfaces, allowing 100% offline unit tests via in-memory mock repositories.
3. **Database Agnostic**: PostgreSQL query logic is isolated inside `internal/repository/postgres/`.

---

## 2. Directory Structure

```
├── cmd/
│   └── server/
│       └── main.go               # Server entry point & background worker
├── internal/
│   ├── config/
│   │   └── config.go             # Environment variable loader & app settings
│   ├── domain/                   # Enterprise business rules & entities
│   │   ├── attendance.go         # Session model & checkout status logic
│   │   ├── domain_test.go        # Unit tests for domain models
│   │   ├── employee.go           # Employee entity & authorization rules
│   │   ├── errors.go             # Domain-specific error definitions
│   │   ├── gps.go                # GPS telemetry rules & validation
│   │   ├── haversine.go          # Haversine distance calculation formula
│   │   ├── office.go             # Office entity & geofence radius check
│   │   └── settings.go           # Dynamic system configuration model
│   ├── handler/
│   │   └── http/                 # Transport layer (Gin HTTP controllers)
│   │       ├── attendance_handler.go # Check-in, check-out, breach endpoints
│   │       ├── auth_handler.go       # Login endpoint
│   │       ├── employee_handler.go   # Profile & assigned office endpoints
│   │       ├── handler_test.go       # HTTP endpoint integration tests
│   │       ├── health_handler.go     # Server health check endpoint
│   │       ├── request.go            # Request DTO structs
│   │       ├── response.go           # Standard JSON response envelope & error mapper
│   │       ├── router.go             # Gin engine routing & middleware pipeline
│   │       └── settings_handler.go   # Runtime settings endpoints
│   ├── middleware/               # HTTP filters & cross-cutting concerns
│   │   ├── auth_jwt.go           # JWT token verification & context injection
│   │   ├── logger.go             # Request/response logging
│   │   ├── rate_limiter.go       # IP-based rate limiting (Token Bucket)
│   │   └── recovery.go           # Panic recovery wrapper
│   ├── repository/               # Data persistence layer
│   │   ├── interfaces.go         # Repository contracts / interfaces
│   │   ├── mock/
│   │   │   └── mock_repos.go     # In-memory mock repositories for testing
│   │   └── postgres/             # PostgreSQL database adapters
│   │       ├── attendance_repo.go# Attendance session SQL queries
│   │       ├── db.go             # pgxpool connection management
│   │       ├── employee_repo.go  # Employee SQL queries
│   │       ├── office_repo.go    # Office SQL queries
│   │       └── settings_repo.go  # Settings SQL queries
│   └── service/                  # Application business services
│       ├── attendance_service.go # Core attendance & autocheckout logic
│       ├── auth_service.go       # Authentication & bcrypt verification
│       ├── employee_service.go   # Employee business operations
│       ├── interfaces.go         # Service layer contracts / interfaces
│       ├── service_test.go       # Service layer test suite
│       ├── settings_service.go   # Dynamic runtime settings service
│       └── telegram_service.go   # Telegram bot alert notifications
├── pkg/
│   └── jwt/
│       ├── jwt.go                # JWT token signing & verification utility
│       └── jwt_test.go           # JWT unit tests
├── migrations/                   # PostgreSQL schema version migrations
│   ├── 000001_init_schema.up.sql / down.sql
│   ├── 000002_attendance_rollover.up.sql / down.sql
│   ├── 000003_force_checkout_and_settings.up.sql / down.sql
│   └── seed.sql                  # Seed data for initial database setup
├── .env                          # Local environment variables
└── go.mod / go.sum               # Go modules dependency definitions
```

---

## 3. Detailed File-by-File Breakdown

### 3.1 Application Entry Point (`cmd/`)

#### [`cmd/server/main.go`](file:///d:/Projects/TEST(LBS)/cmd/server/main.go)
- **Role**: Application bootstrap and lifecycle manager.
- **What happens inside**:
  1. Calls `config.LoadConfig()` to parse environment variables from `.env`.
  2. Initializes PostgreSQL connection pool (`postgres.NewDB`). If the database is unreachable, it automatically activates **In-Memory Mock Repositories** pre-seeded with test accounts (`EMP1001`), ensuring the server runs smoothly in any environment.
  3. Instantiates Repositories (`employeeRepo`, `officeRepo`, `attendanceRepo`, `settingsRepo`).
  4. Instantiates Services (`authSvc`, `empSvc`, `attSvc`, `telegramSvc`, `settingsSvc`).
  5. Initializes HTTP Handlers and attaches them to the Gin Router with middleware (Logger, Rate Limiter, Recovery, JWT).
  6. **Launches Background Worker**: Runs a goroutine with a 10-second ticker executing `attSvc.ProcessAutoForceCheckouts()`. This worker automatically inspects active sessions for expired out-of-radius breaches (>= 2 minutes) and forces checkouts even if the employee's phone is asleep or offline.
  7. Starts the HTTP server on configured port (e.g. `8080`).
  8. Listens for OS shutdown signals (`SIGINT`, `SIGTERM`) to perform a graceful shutdown within 10 seconds.

---

### 3.2 Configuration Layer (`internal/config/`)

#### [`internal/config/config.go`](file:///d:/Projects/TEST(LBS)/internal/config/config.go)
- **Role**: Configuration loader.
- **What happens inside**:
  - Defines the `Config` struct holding: `Port`, `DatabaseURL`, `JWTSecret`, `JWTExpiration`, `TelegramBotToken`, `TelegramChatID`, and rate limit parameters.
  - `loadDotEnv()` reads key-value pairs from `.env` line-by-line if present.
  - `LoadConfig()` extracts environment variables with production-ready fallback defaults (e.g., default port `8080`, 24-hour JWT expiry).

---

### 3.3 Domain Layer (`internal/domain/`)
*The domain layer contains zero external dependencies. It defines entities, invariants, and pure business calculations.*

#### [`internal/domain/attendance.go`](file:///d:/Projects/TEST(LBS)/internal/domain/attendance.go)
- **Role**: Attendance session domain model.
- **What happens inside**:
  - Defines status types: `CHECKED_IN`, `CARRIED_OVER`, `COMPLETED`.
  - Defines checkout reason types: `MANUAL`, `FORCE_CHECKOUT_OUT_OF_RADIUS`.
  - Defines `AttendanceSession` struct: Tracks employee ID, office ID, snapshot of office parameters at check-in (lat/lon/radius), check-in/out timestamps, check-in/out GPS coordinates, distance, total work duration (seconds), and `InitialOutOfRadiusAt` timestamp.
  - `IsActive()`: Returns true if status is `CHECKED_IN` or `CARRIED_OVER`.
  - `CompleteCheckoutWithReason()`: Transitions active session to `COMPLETED`, calculates duration elapsed between check-in and server-time, and records checkout telemetry.

#### [`internal/domain/gps.go`](file:///d:/Projects/TEST(LBS)/internal/domain/gps.go)
- **Role**: GPS telemetry validation and anti-spoofing constraints.
- **What happens inside**:
  - Defines `GPSLocation` struct (`Latitude`, `Longitude`, `AccuracyMeters`, `CapturedAt`).
  - Constants: `MaxAllowedGPSAccuracyMeters = 20.0`, `MaxAllowedForceCheckoutAccuracyMeters = 100.0`, `MaxGPSCaptureAgeSeconds = 30.0`.
  - `Validate(serverTime)`: Ensures:
    1. Latitude is between -90 and +90.
    2. Longitude is between -180 and +180.
    3. Accuracy is $\le 20\text{ meters}$ (prevents poor cellular triangulation / fake GPS drift).
    4. Capture time is not from the future (> 15s ahead of server).
    5. Capture time is fresh ($\le 30\text{ seconds}$ old) against authoritative server clock.
  - `ValidateForForceCheckout(serverTime)`: Relaxed accuracy validation ($\le 100\text{ meters}$) to allow reliable checkout even if an employee enters an indoor or obstructed area when leaving the office.

#### [`internal/domain/haversine.go`](file:///d:/Projects/TEST(LBS)/internal/domain/haversine.go)
- **Role**: Server-authoritative distance calculation.
- **What happens inside**:
  - Implements the great-circle **Haversine formula** using Earth radius $R = 6,371,000\text{ meters}$.
  - Takes `(lat1, lon1, lat2, lon2)` and returns the exact distance in meters.
  - Used by the server to independently verify whether an employee is inside or outside the office radius, making it impossible for a client to cheat by spoofing distance numbers.

#### [`internal/domain/office.go`](file:///d:/Projects/TEST(LBS)/internal/domain/office.go)
- **Role**: Office entity and geofence boundary rules.
- **What happens inside**:
  - Defines `Office` struct (`ID`, `Name`, `Latitude`, `Longitude`, `RadiusMeters`, `IsActive`).
  - `IsWithinRadius(distanceMeters)`: Compares the calculated Haversine distance against `RadiusMeters` (defaults to 10.0m if unset).

#### [`internal/domain/employee.go`](file:///d:/Projects/TEST(LBS)/internal/domain/employee.go)
- **Role**: Employee entity and access control invariants.
- **What happens inside**:
  - Defines `Employee` struct (`ID`, `EmployeeCode`, `PasswordHash`, `FullName`, `Email`, `Role`, `OfficeID`, `IsActive`).
  - `CanAuthenticate()`: Enforces that inactive accounts cannot log in and only users with role `EMPLOYEE` can access attendance workflows.

#### [`internal/domain/settings.go`](file:///d:/Projects/TEST(LBS)/internal/domain/settings.go)
- **Role**: Dynamic system settings entity.
- **What happens inside**:
  - Defines `SystemSettings` struct: `RetryIntervalMinutes` (e.g. 2 minutes), `MaxRetries`, `TelegramAlertsEnabled`, `ForceCheckoutEnabled`, `TelegramBotToken`, `TelegramChatID`.

#### [`internal/domain/errors.go`](file:///d:/Projects/TEST(LBS)/internal/domain/errors.go)
- **Role**: Centralized domain error sentinels.
- **What happens inside**:
  - Defines standard domain errors: `ErrInvalidCredentials`, `ErrEmployeeNotFound`, `ErrEmployeeInactive`, `ErrOfficeNotFound`, `ErrOutsideOfficeRadius`, `ErrActiveSessionExists`, `ErrNoActiveSession`, `ErrAccuracyTooLow`, `ErrCaptureTimeStale`, etc.

#### [`internal/domain/domain_test.go`](file:///d:/Projects/TEST(LBS)/internal/domain/domain_test.go)
- **Role**: Unit test suite for domain models.
- **What happens inside**:
  - Tests Haversine distance calculations against known geographic coordinates.
  - Tests GPS validation under varied boundary conditions (stale times, high accuracy error, future timestamps).
  - Tests session state machine transitions.

---

### 3.4 Service Layer (`internal/service/`)
*The service layer coordinates domain logic, repository queries, and external integrations.*

#### [`internal/service/interfaces.go`](file:///d:/Projects/TEST(LBS)/internal/service/interfaces.go)
- **Role**: Service contracts.
- **What happens inside**:
  - Declares interfaces: `AuthService`, `EmployeeService`, `AttendanceService`, `SettingsService`, and `TelegramAlertService`.
  - Defines helper transfer models like `TodayAttendanceStatus` and `AttendanceHistoryResult`.

#### [`internal/service/attendance_service.go`](file:///d:/Projects/TEST(LBS)/internal/service/attendance_service.go)
- **Role**: **The core attendance engine.**
- **Key Methods**:
  - `CheckIn()`:
    1. Validates submitted GPS coordinates and accuracy ($\le 20\text{m}$).
    2. Ensures employee has no active open session (`ErrActiveSessionExists`).
    3. Fetches assigned office and verifies it is active.
    4. Computes Haversine distance. If distance $>$ office radius, rejects with `ErrOutsideOfficeRadius`.
    5. Calculates `AttendanceDay` in Indian Standard Time (`Asia/Kolkata` YYYY-MM-DD).
    6. Creates and persists new `AttendanceSession` with status `CHECKED_IN`.
  - `CheckOut()`:
    1. Validates GPS accuracy and freshness.
    2. Retrieves active session.
    3. Confirms employee is still within office radius.
    4. Computes total duration and closes session with reason `MANUAL`.
  - `ForceCheckOut()`:
    1. Validates GPS with relaxed tolerance ($\le 100\text{m}$).
    2. Completes session with reason `FORCE_CHECKOUT_OUT_OF_RADIUS`.
    3. Asynchronously triggers Telegram HR alert in a background goroutine.
  - `RecordOutOfRadiusBreach()`:
    - Stores the initial time an employee stepped out of the office (`initial_out_of_radius_at`), initiating the 2-minute countdown.
  - `ClearOutOfRadiusBreach()`:
    - Resets `initial_out_of_radius_at` to `NULL` when employee returns inside the geofence within 2 minutes.
  - `ProcessAutoForceCheckouts()`:
    - Called every 10s by the background worker.
    - Queries database for active sessions where `initial_out_of_radius_at` is older than 2 minutes.
    - Autonomously completes checkout and sends Telegram alert without waiting for mobile device connection.
  - `GetTodayStatus()`:
    - Evaluates active session for **Midnight Rollover**: If `AttendanceDay < CurrentDate`, automatically tags session as `CARRIED_OVER`.
    - Computes accumulated work duration across all sessions for the shift day.
  - `GetMyHistory()`:
    - Returns paginated history filtered by optional date ranges.

#### [`internal/service/auth_service.go`](file:///d:/Projects/TEST(LBS)/internal/service/auth_service.go)
- **Role**: Employee authentication.
- **What happens inside**:
  - Looks up employee by `employeeCode`.
  - Compares submitted password against stored Bcrypt hash using `bcrypt.CompareHashAndPassword`.
  - Checks `CanAuthenticate()` status.
  - Issues signed JWT token containing employee ID, role, and expiration time.

#### [`internal/service/employee_service.go`](file:///d:/Projects/TEST(LBS)/internal/service/employee_service.go)
- **Role**: Employee profile service.
- **What happens inside**:
  - `GetProfile()`: Returns employee metadata (code, name, email, role).
  - `GetAssignedOffice()`: Retrieves geofence coordinates and radius of the employee's designated office.

#### [`internal/service/telegram_service.go`](file:///d:/Projects/TEST(LBS)/internal/service/telegram_service.go)
- **Role**: Instant HR Telegram alert dispatcher.
- **What happens inside**:
  - Reads bot credentials from database settings (with fallback to `.env`).
  - `SendForceCheckoutAlert()`: Constructs an HTML-formatted alert containing:
    - 🚨 Employee Name & Code
    - 🏢 Assigned Office Name
    - 📍 Out of Radius Distance
    - ⏰ Check-In & Auto Force Check-Out Time
    - ⏱ Total Work Duration
    - 🗺 Direct Google Maps link pointing to breach coordinates
  - Posts payload to Telegram Bot API: `https://api.telegram.org/bot<TOKEN>/sendMessage`.

#### [`internal/service/settings_service.go`](file:///d:/Projects/TEST(LBS)/internal/service/settings_service.go)
- **Role**: System settings management.
- **What happens inside**:
  - Provides getters and setters for dynamic parameters like countdown duration and Telegram toggle.

#### [`internal/service/service_test.go`](file:///d:/Projects/TEST(LBS)/internal/service/service_test.go)
- **Role**: Full business logic test suite.
- **What happens inside**:
  - Unit tests covering check-in within radius, out-of-radius rejection, duplicate check-in prevention, manual check-out, force check-out, midnight rollover duration calculation, and mock Telegram notifications.

---

### 3.5 Repository Layer (`internal/repository/`)
*The repository layer isolates all database persistence logic behind clean Go interfaces.*

#### [`internal/repository/interfaces.go`](file:///d:/Projects/TEST(LBS)/internal/repository/interfaces.go)
- **Role**: Repository contracts.
- **What happens inside**:
  - Defines interfaces for `EmployeeRepository`, `OfficeRepository`, `AttendanceRepository`, and `SettingsRepository`.

#### [`internal/repository/postgres/db.go`](file:///d:/Projects/TEST(LBS)/internal/repository/postgres/db.go)
- **Role**: PostgreSQL connection pool setup.
- **What happens inside**:
  - Uses `github.com/jackc/pgx/v5/pgxpool`.
  - Configures maximum connection limits, idle timeouts, and verifies connectivity via `db.Ping(ctx)`.

#### [`internal/repository/postgres/attendance_repo.go`](file:///d:/Projects/TEST(LBS)/internal/repository/postgres/attendance_repo.go)
- **Role**: Attendance session database operations.
- **What happens inside**:
  - `GetActiveSession()`: Finds sessions where `status IN ('CHECKED_IN', 'CARRIED_OVER')`.
  - `CreateSession()`: Inserts a new check-in record.
  - `UpdateSession()`: Saves check-out details, duration, reason, and status.
  - `UpdateInitialOutOfRadiusAt()`: Updates breach start timestamp.
  - `GetExpiredBreachSessions()`: Finds active sessions where `initial_out_of_radius_at <= cutoff` for the auto-checkout worker.
  - `GetSessionsByAttendanceDay()`: Fetches all sessions for a specific day.
  - `GetHistoryByEmployeeID()`: Queries paginated history with `COUNT(*) OVER()` window function.

#### [`internal/repository/postgres/employee_repo.go`](file:///d:/Projects/TEST(LBS)/internal/repository/postgres/employee_repo.go)
- **Role**: Employee database operations.
- **What happens inside**:
  - `GetByID()`: Queries employee details by UUID.
  - `GetByCode()`: Queries employee by unique employee code.

#### [`internal/repository/postgres/office_repo.go`](file:///d:/Projects/TEST(LBS)/internal/repository/postgres/office_repo.go)
- **Role**: Office database operations.
- **What happens inside**:
  - `GetByID()`: Queries office geofence data (latitude, longitude, radius).

#### [`internal/repository/postgres/settings_repo.go`](file:///d:/Projects/TEST(LBS)/internal/repository/postgres/settings_repo.go)
- **Role**: System settings database operations.
- **What happens inside**:
  - `GetSettings()` / `UpdateSettings()`: Reads and updates system configurations in the `system_settings` table.

#### [`internal/repository/mock/mock_repos.go`](file:///d:/Projects/TEST(LBS)/internal/repository/mock/mock_repos.go)
- **Role**: In-memory repository implementations.
- **What happens inside**:
  - Implements all repository interfaces using Go thread-safe `sync.RWMutex` maps.
  - Allows full backend execution without PostgreSQL during offline development or testing.

---

### 3.6 Transport / Handler Layer (`internal/handler/http/`)
*The handler layer handles HTTP routing, request binding, and JSON responses using Gin.*

#### [`internal/handler/http/router.go`](file:///d:/Projects/TEST(LBS)/internal/handler/http/router.go)
- **Role**: Gin router setup and endpoint mapping.
- **What happens inside**:
  - Configures global middleware: Logger, Recovery.
  - Attaches Rate Limiters: Login limiter (5 req/sec), Attendance limiter (10 req/sec).
  - Routes:
    - Public: `GET /health`, `POST /api/v1/auth/login`.
    - Protected (JWT required):
      - `GET /api/v1/me`
      - `GET /api/v1/offices/assigned`
      - `POST /api/v1/attendance/check-in`
      - `POST /api/v1/attendance/check-out`
      - `POST /api/v1/attendance/force-checkout`
      - `POST /api/v1/attendance/breach-warning`
      - `DELETE /api/v1/attendance/breach-warning` & `POST /api/v1/attendance/clear-breach`
      - `GET /api/v1/attendance/today-status`
      - `GET /api/v1/attendance/me`
      - `GET /api/v1/settings` & `PUT /api/v1/settings`

#### [`internal/handler/http/attendance_handler.go`](file:///d:/Projects/TEST(LBS)/internal/handler/http/attendance_handler.go)
- **Role**: Attendance HTTP controller.
- **What happens inside**:
  - Extracts authenticated `employeeID` from Gin context.
  - Binds JSON payloads (`GPSRequest`, `ForceCheckoutRequest`).
  - Calls corresponding `AttendanceService` methods.
  - Returns structured JSON responses or maps domain errors.

#### [`internal/handler/http/auth_handler.go`](file:///d:/Projects/TEST(LBS)/internal/handler/http/auth_handler.go)
- **Role**: Authentication controller.
- **What happens inside**:
  - Handles `POST /api/v1/auth/login`, validates employee credentials, and returns JWT Bearer token.

#### [`internal/handler/http/employee_handler.go`](file:///d:/Projects/TEST(LBS)/internal/handler/http/employee_handler.go)
- **Role**: Employee profile controller.
- **What happens inside**:
  - Handles `GET /api/v1/me` and `GET /api/v1/offices/assigned`.

#### [`internal/handler/http/settings_handler.go`](file:///d:/Projects/TEST(LBS)/internal/handler/http/settings_handler.go)
- **Role**: System settings controller.
- **What happens inside**:
  - Handles `GET /api/v1/settings` and `PUT /api/v1/settings`.

#### [`internal/handler/http/health_handler.go`](file:///d:/Projects/TEST(LBS)/internal/handler/http/health_handler.go)
- **Role**: Liveness check controller.
- **What happens inside**:
  - Returns `{"status": "ok", "timestamp": ...}` for uptime monitoring.

#### [`internal/handler/http/request.go`](file:///d:/Projects/TEST(LBS)/internal/handler/http/request.go)
- **Role**: Request DTOs.
- **What happens inside**:
  - Defines Go structs with JSON and validation tags for all incoming requests (`LoginRequest`, `GPSRequest`, `ForceCheckoutRequest`, etc.).

#### [`internal/handler/http/response.go`](file:///d:/Projects/TEST(LBS)/internal/handler/http/response.go)
- **Role**: Standardized API responses and error mapping.
- **What happens inside**:
  - `SendSuccess()`: Wraps data in standard `{ "success": true, "data": ... }`.
  - `SendError()`: Wraps failures in `{ "success": false, "error": { "code": ..., "message": ... } }`.
  - `MapDomainError()`: Maps domain error sentinels to appropriate HTTP status codes (e.g. `ErrOutsideOfficeRadius` $\rightarrow$ 400 Bad Request with code `OUTSIDE_OFFICE_RADIUS`).

#### [`internal/handler/http/handler_test.go`](file:///d:/Projects/TEST(LBS)/internal/handler/http/handler_test.go)
- **Role**: HTTP layer unit & integration tests using `httptest.ResponseRecorder`.

---

### 3.7 Middleware Layer (`internal/middleware/`)

#### [`internal/middleware/auth_jwt.go`](file:///d:/Projects/TEST(LBS)/internal/middleware/auth_jwt.go)
- **Role**: JWT Bearer token validation.
- **What happens inside**:
  - Reads `Authorization: Bearer <token>` header.
  - Verifies token signature and claims.
  - Injects `employeeId` and `role` into Gin context (`c.Set(ContextKeyEmployeeID, ...)`).

#### [`internal/middleware/logger.go`](file:///d:/Projects/TEST(LBS)/internal/middleware/logger.go)
- **Role**: Request logging middleware.
- **What happens inside**:
  - Logs HTTP method, URL path, response status code, and latency for each incoming request.

#### [`internal/middleware/rate_limiter.go`](file:///d:/Projects/TEST(LBS)/internal/middleware/rate_limiter.go)
- **Role**: Denial-of-service and brute force protection.
- **What happens inside**:
  - Implements an IP-based Token Bucket rate limiter using `golang.org/x/time/rate`.

#### [`internal/middleware/recovery.go`](file:///d:/Projects/TEST(LBS)/internal/middleware/recovery.go)
- **Role**: Crash resilience.
- **What happens inside**:
  - Catches unexpected panics in handlers and returns a clean 500 Internal Server Error instead of terminating the server process.

---

### 3.8 Packages (`pkg/`)

#### [`pkg/jwt/jwt.go`](file:///d:/Projects/TEST(LBS)/pkg/jwt/jwt.go) & [`jwt_test.go`](file:///d:/Projects/TEST(LBS)/pkg/jwt/jwt_test.go)
- **Role**: Reusable cryptographic JWT utility.
- **What happens inside**:
  - `GenerateToken()`: Signs claims using HMAC-SHA256 (`jwt.SigningMethodHS256`).
  - `ValidateToken()`: Parses token string, verifies cryptographic signature, checks expiration, and extracts claims.

---

### 3.9 Database Migrations (`migrations/`)

- [`000001_init_schema.up.sql`](file:///d:/Projects/TEST(LBS)/migrations/000001_init_schema.up.sql): Creates initial tables: `offices`, `employees`, and `attendance_sessions`.
- [`000002_attendance_rollover.up.sql`](file:///d:/Projects/TEST(LBS)/migrations/000002_attendance_rollover.up.sql): Adds `attendance_day`, index optimizations, and `CARRIED_OVER` status support for night shifts.
- [`000003_force_checkout_and_settings.up.sql`](file:///d:/Projects/TEST(LBS)/migrations/000003_force_checkout_and_settings.up.sql): Adds `initial_out_of_radius_at` breach tracking timestamp, `checkout_reason`, and the `system_settings` configuration table.
- [`seed.sql`](file:///d:/Projects/TEST(LBS)/migrations/seed.sql): Provides default seed data for testing.

---

## 4. Key Mechanisms Explained Simply

### 1. GPS Geofencing & Distance Verification
1. The mobile app captures the device's latitude, longitude, and accuracy.
2. The server independently verifies accuracy ($\le 20\text{m}$) and freshness ($\le 30\text{s}$).
3. The server calculates the real distance to the office using the **Haversine formula**.
4. If `distance <= office.RadiusMeters`, check-in is approved; otherwise, it is rejected.

### 2. Autonomous 2-Minute Out-of-Radius Force Checkout
1. When an employee walks out of radius, the app registers a breach timestamp (`initial_out_of_radius_at`).
2. A 2-minute countdown begins on the mobile app.
3. If the employee returns within 2 minutes, the breach timestamp is cleared.
4. **Autonomous Backend Fallback**: If the employee does not return and their phone screen is locked or battery dies, the backend's background worker (running every 10 seconds in `main.go`) automatically detects the expired breach, force-checks out the session, and triggers an immediate Telegram alert.

### 3. Midnight Rollover (Night Shift Support)
1. When an employee checks in at night (e.g. 10:00 PM on Oct 8), the session is anchored to `attendance_day = 2026-10-08`.
2. When midnight passes (12:00 AM on Oct 9), the session status transitions to `CARRIED_OVER`.
3. The mobile dashboard continues accumulating total working hours continuously without resetting to 0.
4. When checking out in the morning, the hours are attributed correctly to the shift's starting day.

### 4. Telegram HR Alerts
- When a force check-out occurs, `telegram_service.go` formats an instant alert with employee details, office name, out-of-radius distance, duration, and a direct Google Maps link, and dispatches it directly to the management Telegram group.

---

## 5. Summary Cheat Sheet for Mentor Presentation

| Component | Technology | Responsibility |
|---|---|---|
| **Language & Framework** | Go 1.22+ / Gin Engine | High performance, lightweight backend |
| **Database** | PostgreSQL (`pgxpool`) | Relational persistence with connection pooling |
| **Security** | JWT (HS256) + Bcrypt | Secure token authentication & hashed passwords |
| **Distance Math** | Haversine Formula | Server-authoritative distance calculation |
| **GPS Enforcement** | Server-side validation | Max 20m accuracy, max 30s age (anti-spoofing) |
| **Reliability** | Autonomous Background Worker | Forces checkout after 2 mins even if phone is sleeping |
| **Alerts** | Telegram Bot API | Instant notification to HR group on force checkout |
