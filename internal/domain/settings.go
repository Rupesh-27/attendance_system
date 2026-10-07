package domain

import "time"

type SystemSettings struct {
	ID                    int       `json:"id"`
	RetryIntervalMinutes  int       `json:"retryIntervalMinutes"`
	MaxRetries            int       `json:"maxRetries"`
	TelegramAlertsEnabled bool      `json:"telegramAlertsEnabled"`
	ForceCheckoutEnabled  bool      `json:"forceCheckoutEnabled"`
	TelegramBotToken      string    `json:"telegramBotToken,omitempty"`
	TelegramChatID        string    `json:"telegramChatId,omitempty"`
	UpdatedAt             time.Time `json:"updatedAt"`
}
