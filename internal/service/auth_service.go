package service

import (
	"context"
	"errors"
	"time"

	"golang.org/x/crypto/bcrypt"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
	"location-attendance/pkg/jwt"
)

type authService struct {
	employeeRepo  repository.EmployeeRepository
	jwtSecret     string
	jwtExpiration time.Duration
}

func NewAuthService(
	employeeRepo repository.EmployeeRepository,
	jwtSecret string,
	jwtExpiration time.Duration,
) AuthService {
	return &authService{
		employeeRepo:  employeeRepo,
		jwtSecret:     jwtSecret,
		jwtExpiration: jwtExpiration,
	}
}

func (s *authService) Login(ctx context.Context, employeeCode, password string) (*AuthResult, error) {
	if employeeCode == "" || password == "" {
		return nil, domain.ErrInvalidCredentials
	}

	emp, err := s.employeeRepo.GetByCode(ctx, employeeCode)
	if err != nil {
		if errors.Is(err, domain.ErrEmployeeNotFound) {
			return nil, domain.ErrInvalidCredentials
		}
		return nil, err
	}

	// Verify password hash
	if err := bcrypt.CompareHashAndPassword([]byte(emp.PasswordHash), []byte(password)); err != nil {
		return nil, domain.ErrInvalidCredentials
	}

	// Check if employee is active and role is EMPLOYEE
	if err := emp.CanAuthenticate(); err != nil {
		return nil, err
	}

	tokenStr, expiresAt, err := jwt.GenerateToken(emp, s.jwtSecret, s.jwtExpiration)
	if err != nil {
		return nil, err
	}

	return &AuthResult{
		AccessToken: tokenStr,
		ExpiresAt:   expiresAt,
		Employee:    emp,
	}, nil
}
