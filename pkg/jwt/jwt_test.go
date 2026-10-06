package jwt_test

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"location-attendance/internal/domain"
	"location-attendance/pkg/jwt"
)

func TestJWT_GenerateAndValidate(t *testing.T) {
	emp := &domain.Employee{
		ID:           uuid.New(),
		EmployeeCode: "EMP001",
		FullName:     "Alice Test",
		Role:         domain.RoleEmployee,
		IsActive:     true,
	}

	secret := "super-secure-secret-key-12345"
	tokenStr, exp, err := jwt.GenerateToken(emp, secret, 1*time.Hour)
	require.NoError(t, err)
	assert.NotEmpty(t, tokenStr)
	assert.True(t, exp.After(time.Now()))

	claims, err := jwt.ValidateToken(tokenStr, secret)
	require.NoError(t, err)
	assert.Equal(t, emp.ID, claims.EmployeeID)
	assert.Equal(t, emp.EmployeeCode, claims.EmployeeCode)
	assert.Equal(t, domain.RoleEmployee, claims.Role)
}

func TestJWT_ExpiredToken(t *testing.T) {
	emp := &domain.Employee{
		ID:           uuid.New(),
		EmployeeCode: "EMP002",
		Role:         domain.RoleEmployee,
		IsActive:     true,
	}

	secret := "secret-key"

	tokenStr, _, err := jwt.GenerateToken(emp, secret, -10*time.Second)
	require.NoError(t, err)

	_, err = jwt.ValidateToken(tokenStr, secret)
	assert.ErrorIs(t, err, jwt.ErrTokenExpired)
}

func TestJWT_InvalidSignature(t *testing.T) {
	emp := &domain.Employee{
		ID:           uuid.New(),
		EmployeeCode: "EMP003",
		Role:         domain.RoleEmployee,
		IsActive:     true,
	}

	tokenStr, _, err := jwt.GenerateToken(emp, "correct-secret", 1*time.Hour)
	require.NoError(t, err)

	_, err = jwt.ValidateToken(tokenStr, "wrong-secret")
	assert.ErrorIs(t, err, jwt.ErrInvalidSignature)
}
