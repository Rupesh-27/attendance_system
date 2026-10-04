package service

import (
	"context"

	"github.com/google/uuid"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type employeeService struct {
	employeeRepo repository.EmployeeRepository
	officeRepo   repository.OfficeRepository
}

func NewEmployeeService(
	employeeRepo repository.EmployeeRepository,
	officeRepo repository.OfficeRepository,
) EmployeeService {
	return &employeeService{
		employeeRepo: employeeRepo,
		officeRepo:   officeRepo,
	}
}

func (s *employeeService) GetProfile(ctx context.Context, employeeID uuid.UUID) (*domain.Employee, error) {
	emp, err := s.employeeRepo.GetByID(ctx, employeeID)
	if err != nil {
		return nil, err
	}
	if !emp.IsActive {
		return nil, domain.ErrEmployeeInactive
	}
	return emp, nil
}

func (s *employeeService) GetAssignedOffice(ctx context.Context, employeeID uuid.UUID) (*domain.Office, error) {
	emp, err := s.employeeRepo.GetByID(ctx, employeeID)
	if err != nil {
		return nil, err
	}
	if !emp.IsActive {
		return nil, domain.ErrEmployeeInactive
	}

	office, err := s.officeRepo.GetByID(ctx, emp.OfficeID)
	if err != nil {
		return nil, err
	}
	if !office.IsActive {
		return nil, domain.ErrOfficeInactive
	}

	return office, nil
}
