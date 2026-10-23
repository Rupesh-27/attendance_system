package service

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
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

func (s *authService) Login(ctx context.Context, employeeCode, password string, force ...bool) (*AuthResult, error) {
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

	if err := bcrypt.CompareHashAndPassword([]byte(emp.PasswordHash), []byte(password)); err != nil {
		return nil, domain.ErrInvalidCredentials
	}

	if err := emp.CanAuthenticate(); err != nil {
		return nil, err
	}

	forceLogin := len(force) > 0 && force[0]
	// Single-device login check: If active session already exists on another device, block login unless force takeover is requested
	if emp.ActiveSessionID != nil && !forceLogin {
		return nil, domain.ErrDeviceAlreadyLoggedIn
	}

	newSessionID := uuid.New()
	if err := s.employeeRepo.UpdateActiveSessionID(ctx, emp.ID, &newSessionID); err != nil {
		return nil, err
	}
	emp.ActiveSessionID = &newSessionID

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

func (s *authService) Logout(ctx context.Context, employeeID uuid.UUID) error {
	return s.employeeRepo.UpdateActiveSessionID(ctx, employeeID, nil)
}
