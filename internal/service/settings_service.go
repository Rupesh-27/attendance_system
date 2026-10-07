package service

import (
	"context"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type SettingsService interface {
	GetSettings(ctx context.Context) (*domain.SystemSettings, error)
	UpdateSettings(ctx context.Context, s *domain.SystemSettings) error
}

type settingsService struct {
	repo repository.SettingsRepository
}

func NewSettingsService(repo repository.SettingsRepository) SettingsService {
	return &settingsService{repo: repo}
}

func (s *settingsService) GetSettings(ctx context.Context) (*domain.SystemSettings, error) {
	return s.repo.GetSettings(ctx)
}

func (s *settingsService) UpdateSettings(ctx context.Context, settings *domain.SystemSettings) error {
	return s.repo.UpdateSettings(ctx, settings)
}
