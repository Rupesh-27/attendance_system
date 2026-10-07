package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type settingsRepo struct {
	db *DB
}

func NewSettingsRepository(db *DB) repository.SettingsRepository {
	return &settingsRepo{db: db}
}

func (r *settingsRepo) GetSettings(ctx context.Context) (*domain.SystemSettings, error) {
	query := `
		SELECT
			id, retry_interval_minutes, max_retries,
			telegram_alerts_enabled, force_checkout_enabled,
			COALESCE(telegram_bot_token, ''), COALESCE(telegram_chat_id, ''),
			updated_at
		FROM system_settings
		WHERE id = 1
		LIMIT 1
	`
	var s domain.SystemSettings
	err := r.db.Pool.QueryRow(ctx, query).Scan(
		&s.ID,
		&s.RetryIntervalMinutes,
		&s.MaxRetries,
		&s.TelegramAlertsEnabled,
		&s.ForceCheckoutEnabled,
		&s.TelegramBotToken,
		&s.TelegramChatID,
		&s.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			// Fallback default
			return &domain.SystemSettings{
				ID:                    1,
				RetryIntervalMinutes:  2,
				MaxRetries:            1,
				TelegramAlertsEnabled: true,
				ForceCheckoutEnabled:  true,
				TelegramBotToken:      "",
				TelegramChatID:        "",
				UpdatedAt:             time.Now().UTC(),
			}, nil
		}
		return nil, err
	}

	return &s, nil
}

func (r *settingsRepo) UpdateSettings(ctx context.Context, s *domain.SystemSettings) error {
	query := `
		INSERT INTO system_settings (
			id, retry_interval_minutes, max_retries,
			telegram_alerts_enabled, force_checkout_enabled,
			telegram_bot_token, telegram_chat_id, updated_at
		) VALUES (
			1, $1, $2, $3, $4, $5, $6, NOW()
		)
		ON CONFLICT (id) DO UPDATE SET
			retry_interval_minutes = EXCLUDED.retry_interval_minutes,
			max_retries = EXCLUDED.max_retries,
			telegram_alerts_enabled = EXCLUDED.telegram_alerts_enabled,
			force_checkout_enabled = EXCLUDED.force_checkout_enabled,
			telegram_bot_token = CASE WHEN EXCLUDED.telegram_bot_token <> '' THEN EXCLUDED.telegram_bot_token ELSE system_settings.telegram_bot_token END,
			telegram_chat_id = CASE WHEN EXCLUDED.telegram_chat_id <> '' THEN EXCLUDED.telegram_chat_id ELSE system_settings.telegram_chat_id END,
			updated_at = NOW()
	`
	_, err := r.db.Pool.Exec(ctx, query,
		s.RetryIntervalMinutes,
		s.MaxRetries,
		s.TelegramAlertsEnabled,
		s.ForceCheckoutEnabled,
		s.TelegramBotToken,
		s.TelegramChatID,
	)
	return err
}
