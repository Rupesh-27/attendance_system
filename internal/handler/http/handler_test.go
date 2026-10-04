package http_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/bcrypt"

	"location-attendance/internal/domain"
	handler "location-attendance/internal/handler/http"
	"location-attendance/internal/repository/mock"
	"location-attendance/internal/service"
	"location-attendance/pkg/jwt"
)

func setupTestRouter() (
	*gin.Engine,
	*domain.Employee,
	*domain.Office,
	string,
) {
	gin.SetMode(gin.TestMode)

	empRepo := mock.NewMockEmployeeRepo()
	officeRepo := mock.NewMockOfficeRepo()
	attRepo := mock.NewMockAttendanceRepo()

	office := &domain.Office{
		ID:           uuid.New(),
		Name:         "Headquarters",
		Latitude:     13.000000,
		Longitude:    80.000000,
		RadiusMeters: 10.0,
		IsActive:     true,
	}
	officeRepo.Seed(office)

	hash, _ := bcrypt.GenerateFromPassword([]byte("Password123!"), bcrypt.DefaultCost)
	emp := &domain.Employee{
		ID:           uuid.New(),
		EmployeeCode: "EMP001",
		PasswordHash: string(hash),
		FullName:     "Alice Wonderland",
		Role:         domain.RoleEmployee,
		OfficeID:     office.ID,
		IsActive:     true,
	}
	empRepo.Seed(emp)

	jwtSecret := "test-secret-key-32-bytes-length-ok!"
	authSvc := service.NewAuthService(empRepo, jwtSecret, 1*time.Hour)
	empSvc := service.NewEmployeeService(empRepo, officeRepo)

	currentTime := time.Date(2026, 9, 23, 12, 0, 0, 0, time.UTC)
	clock := func() time.Time { return currentTime }

	attSvc := service.NewAttendanceService(empRepo, officeRepo, attRepo, clock)

	r := handler.SetupRouter(handler.RouterConfig{
		AuthHandler:       handler.NewAuthHandler(authSvc),
		EmployeeHandler:   handler.NewEmployeeHandler(empSvc),
		AttendanceHandler: handler.NewAttendanceHandler(attSvc),
		JWTSecret:         jwtSecret,
	})

	return r, emp, office, jwtSecret
}

func TestHandler_HealthCheck(t *testing.T) {
	router, _, _, _ := setupTestRouter()

	req, _ := http.NewRequest(http.MethodGet, "/health", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	assert.Contains(t, w.Body.String(), `"status":"UP"`)
}

func TestHandler_Auth_Login_Success(t *testing.T) {
	router, _, _, _ := setupTestRouter()

	body := map[string]string{
		"employeeCode": "EMP001",
		"password":     "Password123!",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp handler.APIResponse
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	require.NoError(t, err)
	assert.True(t, resp.Success)
}

func TestHandler_Auth_Login_Failure(t *testing.T) {
	router, _, _, _ := setupTestRouter()

	body := map[string]string{
		"employeeCode": "EMP001",
		"password":     "WrongPassword",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
	var resp handler.APIResponse
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	require.NoError(t, err)
	assert.False(t, resp.Success)
	assert.Equal(t, "AUTH_INVALID", resp.Code)
	assert.Equal(t, "AUTH_INVALID", resp.Error.Code)
}

func TestHandler_Attendance_CheckIn_And_CheckOut(t *testing.T) {
	router, emp, office, secret := setupTestRouter()

	// Generate valid JWT
	token, _, err := jwt.GenerateToken(emp, secret, 1*time.Hour)
	require.NoError(t, err)

	now := time.Date(2026, 9, 23, 12, 0, 0, 0, time.UTC)

	// 1. Check-In inside office radius
	checkInBody := handler.GPSRequest{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     now,
	}
	jsonBody, _ := json.Marshal(checkInBody)

	req, _ := http.NewRequest(http.MethodPost, "/api/v1/attendance/check-in", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var checkInResp handler.AttendanceCheckInResponse
	err = json.Unmarshal(w.Body.Bytes(), &checkInResp)
	require.NoError(t, err)
	assert.True(t, checkInResp.Success)
	assert.Equal(t, "CHECKED_IN", checkInResp.Status)
	assert.NotEmpty(t, checkInResp.AttendanceID)
	assert.Equal(t, 10.0, checkInResp.AllowedRadiusMeters)

	// 2. Duplicate Check-In attempt should fail with 409 Conflict
	wDup := httptest.NewRecorder()
	reqDup, _ := http.NewRequest(http.MethodPost, "/api/v1/attendance/check-in", bytes.NewBuffer(jsonBody))
	reqDup.Header.Set("Content-Type", "application/json")
	reqDup.Header.Set("Authorization", "Bearer "+token)
	router.ServeHTTP(wDup, reqDup)

	assert.Equal(t, http.StatusConflict, wDup.Code)

	// 3. Check-Out inside office radius
	checkOutBody := handler.GPSRequest{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 8.0,
		CapturedAt:     now,
	}
	jsonCheckOut, _ := json.Marshal(checkOutBody)

	reqOut, _ := http.NewRequest(http.MethodPost, "/api/v1/attendance/check-out", bytes.NewBuffer(jsonCheckOut))
	reqOut.Header.Set("Content-Type", "application/json")
	reqOut.Header.Set("Authorization", "Bearer "+token)
	wOut := httptest.NewRecorder()
	router.ServeHTTP(wOut, reqOut)

	assert.Equal(t, http.StatusOK, wOut.Code)
	var checkOutResp handler.AttendanceCheckOutResponse
	err = json.Unmarshal(wOut.Body.Bytes(), &checkOutResp)
	require.NoError(t, err)
	assert.True(t, checkOutResp.Success)
	assert.Equal(t, "COMPLETED", checkOutResp.Status)
	assert.NotEmpty(t, checkOutResp.AttendanceID)

	// 4. Query Attendance History with from & to filters
	reqHist, _ := http.NewRequest(http.MethodGet, "/api/v1/attendance/me?from=2026-09-01&to=2026-09-30", nil)
	reqHist.Header.Set("Authorization", "Bearer "+token)
	wHist := httptest.NewRecorder()
	router.ServeHTTP(wHist, reqHist)

	assert.Equal(t, http.StatusOK, wHist.Code)
	var histResp handler.APIResponse
	err = json.Unmarshal(wHist.Body.Bytes(), &histResp)
	require.NoError(t, err)
	assert.True(t, histResp.Success)
}

func TestHandler_CheckIn_OutsideRadius_Returns422(t *testing.T) {
	router, emp, office, secret := setupTestRouter()

	token, _, err := jwt.GenerateToken(emp, secret, 1*time.Hour)
	require.NoError(t, err)

	now := time.Date(2026, 9, 23, 12, 0, 0, 0, time.UTC)

	// Coordinates 500m away
	checkInBody := handler.GPSRequest{
		Latitude:       office.Latitude + 0.005,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     now,
	}
	jsonBody, _ := json.Marshal(checkInBody)

	req, _ := http.NewRequest(http.MethodPost, "/api/v1/attendance/check-in", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnprocessableEntity, w.Code)
	var resp handler.APIResponse
	err = json.Unmarshal(w.Body.Bytes(), &resp)
	require.NoError(t, err)
	assert.Equal(t, "OUTSIDE_RADIUS", resp.Code)
	assert.Equal(t, "OUTSIDE_RADIUS", resp.Error.Code)
}

func TestHandler_CheckOut_WithoutCheckIn_Returns400(t *testing.T) {
	router, emp, office, secret := setupTestRouter()

	token, _, err := jwt.GenerateToken(emp, secret, 1*time.Hour)
	require.NoError(t, err)

	now := time.Date(2026, 9, 23, 12, 0, 0, 0, time.UTC)

	checkOutBody := handler.GPSRequest{
		Latitude:       office.Latitude,
		Longitude:      office.Longitude,
		AccuracyMeters: 5.0,
		CapturedAt:     now,
	}
	jsonBody, _ := json.Marshal(checkOutBody)

	req, _ := http.NewRequest(http.MethodPost, "/api/v1/attendance/check-out", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
	var resp handler.APIResponse
	err = json.Unmarshal(w.Body.Bytes(), &resp)
	require.NoError(t, err)
	assert.Equal(t, "NOT_CHECKED_IN", resp.Code)
	assert.Equal(t, "NOT_CHECKED_IN", resp.Error.Code)
}

func TestHandler_GetMe_And_GetAssignedOffice(t *testing.T) {
	router, emp, _, secret := setupTestRouter()

	token, _, err := jwt.GenerateToken(emp, secret, 1*time.Hour)
	require.NoError(t, err)

	// GET /api/v1/me
	reqMe, _ := http.NewRequest(http.MethodGet, "/api/v1/me", nil)
	reqMe.Header.Set("Authorization", "Bearer "+token)
	wMe := httptest.NewRecorder()
	router.ServeHTTP(wMe, reqMe)

	assert.Equal(t, http.StatusOK, wMe.Code)
	assert.Contains(t, wMe.Body.String(), "Alice Wonderland")

	// GET /api/v1/offices/assigned
	reqOffice, _ := http.NewRequest(http.MethodGet, "/api/v1/offices/assigned", nil)
	reqOffice.Header.Set("Authorization", "Bearer "+token)
	wOffice := httptest.NewRecorder()
	router.ServeHTTP(wOffice, reqOffice)

	assert.Equal(t, http.StatusOK, wOffice.Code)
	assert.Contains(t, wOffice.Body.String(), "Headquarters")
}

func TestHandler_ProtectedEndpoints_WithoutJWT(t *testing.T) {
	router, _, _, _ := setupTestRouter()

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/me", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}
