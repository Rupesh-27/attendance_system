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

	"location-attendance/internal/domain"
	handler "location-attendance/internal/handler/http"
	"location-attendance/internal/repository/mock"
	"location-attendance/internal/service"
	"location-attendance/pkg/jwt"
)

func setupLeaveHandlerTest() (*gin.Engine, *domain.Employee, *mock.MockLeaveRepo, uuid.UUID, string) {
	gin.SetMode(gin.TestMode)

	empRepo := mock.NewMockEmployeeRepo()
	leaveRepo := mock.NewMockLeaveRepo()

	empID := uuid.New()
	emp := &domain.Employee{
		ID:           empID,
		EmployeeCode: "EMP1001",
		FullName:     "John Doe",
		Role:         domain.RoleEmployee,
		IsActive:     true,
	}
	empRepo.Seed(emp)

	types, _ := leaveRepo.GetLeaveTypes(nil)
	clTypeID := types[0].ID

	leaveRepo.SeedBalance(&domain.EmployeeLeaveBalance{
		ID:            uuid.New(),
		EmployeeID:    empID,
		LeaveTypeID:   clTypeID,
		Year:          2026,
		AllocatedDays: 12,
		UsedDays:      0,
		RemainingDays: 12,
	})

	jwtSecret := "test-leave-secret-key-32-bytes!!"
	token, _, _ := jwt.GenerateToken(emp, jwtSecret, 1*time.Hour)

	clock := func() time.Time { return time.Date(2026, 10, 15, 10, 0, 0, 0, time.UTC) }
	leaveSvc := service.NewLeaveService(leaveRepo, empRepo, clock)
	leaveH := handler.NewLeaveHandler(leaveSvc)

	r := handler.SetupRouter(handler.RouterConfig{
		LeaveHandler: leaveH,
		JWTSecret:    jwtSecret,
	})

	return r, emp, leaveRepo, clTypeID, token
}

func TestLeaveHandler_GetLeaveTypesAndBalances(t *testing.T) {
	router, _, _, _, token := setupLeaveHandlerTest()

	// 1. Get Leave Types
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/leave/types", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp handler.APIResponse
	err := json.Unmarshal(w.Body.Bytes(), &resp)
	require.NoError(t, err)
	assert.True(t, resp.Success)

	// 2. Get Leave Balances
	req, _ = http.NewRequest(http.MethodGet, "/api/v1/leave/balances?year=2026", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w = httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var balResp handler.APIResponse
	err = json.Unmarshal(w.Body.Bytes(), &balResp)
	require.NoError(t, err)
	assert.True(t, balResp.Success)
}

func TestLeaveHandler_ApplyAndApproveFlow(t *testing.T) {
	router, emp, _, clTypeID, token := setupLeaveHandlerTest()

	// 1. Apply Leave
	applyBody := service.ApplyLeaveRequest{
		LeaveTypeID: clTypeID,
		StartDate:   "2026-10-20",
		EndDate:     "2026-10-20",
		IsHalfDay:   false,
		Reason:      "Medical appointment",
	}
	bodyBytes, _ := json.Marshal(applyBody)
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/leave/apply", bytes.NewReader(bodyBytes))
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)
	var applyResp struct {
		Success bool                    `json:"success"`
		Data    domain.LeaveApplication `json:"data"`
	}
	err := json.Unmarshal(w.Body.Bytes(), &applyResp)
	require.NoError(t, err)
	appID := applyResp.Data.ID

	// 2. Get My Applications
	req, _ = http.NewRequest(http.MethodGet, "/api/v1/leave/my-applications", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w = httptest.NewRecorder()
	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	// 3. Get Pending Approvals
	req, _ = http.NewRequest(http.MethodGet, "/api/v1/leave/approvals", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	w = httptest.NewRecorder()
	router.ServeHTTP(w, req)
	assert.Equal(t, http.StatusOK, w.Code)

	// 4. Approve Application
	remarks := "Approved by team lead"
	approvalBody := handler.LeaveApprovalRequest{Remarks: &remarks}
	approvalBytes, _ := json.Marshal(approvalBody)
	req, _ = http.NewRequest(http.MethodPost, "/api/v1/leave/"+appID.String()+"/approve", bytes.NewReader(approvalBytes))
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	w = httptest.NewRecorder()
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var appResp struct {
		Success bool                    `json:"success"`
		Data    domain.LeaveApplication `json:"data"`
	}
	err = json.Unmarshal(w.Body.Bytes(), &appResp)
	require.NoError(t, err)
	assert.Equal(t, domain.LeaveStatusApproved, appResp.Data.Status)
	assert.Equal(t, &emp.ID, appResp.Data.ReviewedBy)
}
