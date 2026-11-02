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

func (s *authService) Login(ctx context.Context, params LoginParams) (*AuthResult, error) {
	if params.EmployeeCode == "" || params.Password == "" {
		return nil, domain.ErrInvalidCredentials
	}

	emp, err := s.employeeRepo.GetByCode(ctx, params.EmployeeCode)
	if err != nil {
		if errors.Is(err, domain.ErrEmployeeNotFound) {
			return nil, domain.ErrInvalidCredentials
		}
		return nil, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(emp.PasswordHash), []byte(params.Password)); err != nil {
		return nil, domain.ErrInvalidCredentials
	}

	if err := emp.CanAuthenticate(); err != nil {
		return nil, err
	}

	// Device Binding Policy (Policy 2):
	if params.DeviceID != "" {
		if emp.DeviceID == nil || *emp.DeviceID == "" {
			// First-time login on a device or device was reset by Admin: BIND THIS DEVICE!
			if err := s.employeeRepo.UpdateDeviceBinding(ctx, emp.ID, &params.DeviceID, &params.DeviceModel); err != nil {
				return nil, err
			}
			emp.DeviceID = &params.DeviceID
			emp.DeviceModel = &params.DeviceModel
		} else if *emp.DeviceID != params.DeviceID {
			// Device does not match registered device! Strictly block access
			return nil, domain.ErrDeviceLockedToAnotherPhone
		}
		// If *emp.DeviceID == params.DeviceID: same device, automatically proceed!
	} else {
		// Fallback for requests without device ID (e.g. legacy/testing)
		if emp.ActiveSessionID != nil && !params.Force {
			return nil, domain.ErrDeviceAlreadyLoggedIn
		}
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
