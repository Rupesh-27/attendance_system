package http

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"location-attendance/internal/domain"
	"location-attendance/internal/service"
)

type SettingsHandler struct {
	settingsService service.SettingsService
}

func NewSettingsHandler(settingsService service.SettingsService) *SettingsHandler {
	return &SettingsHandler{settingsService: settingsService}
}

type UpdateSettingsRequest struct {
	RetryIntervalMinutes  *int    `json:"retryIntervalMinutes"`
	MaxRetries            *int    `json:"maxRetries"`
	TelegramAlertsEnabled *bool   `json:"telegramAlertsEnabled"`
	ForceCheckoutEnabled  *bool   `json:"forceCheckoutEnabled"`
	TelegramBotToken      *string `json:"telegramBotToken"`
	TelegramChatID        *string `json:"telegramChatId"`
}

func (h *SettingsHandler) GetSettings(c *gin.Context) {
	settings, err := h.settingsService.GetSettings(c.Request.Context())
	if err != nil {
		SendError(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to retrieve system settings", err.Error())
		return
	}
	SendSuccess(c, http.StatusOK, settings)
}

func (h *SettingsHandler) UpdateSettings(c *gin.Context) {
	var req UpdateSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		SendError(c, http.StatusBadRequest, "BAD_REQUEST", "Invalid settings payload", err.Error())
		return
	}

	current, err := h.settingsService.GetSettings(c.Request.Context())
	if err != nil {
		current = &domain.SystemSettings{
			ID:                    1,
			RetryIntervalMinutes:  2,
			MaxRetries:            1,
			TelegramAlertsEnabled: true,
			ForceCheckoutEnabled:  true,
		}
	}

	if req.RetryIntervalMinutes != nil && *req.RetryIntervalMinutes > 0 {
		current.RetryIntervalMinutes = *req.RetryIntervalMinutes
	}
	if req.MaxRetries != nil && *req.MaxRetries >= 0 {
		current.MaxRetries = *req.MaxRetries
	}
	if req.TelegramAlertsEnabled != nil {
		current.TelegramAlertsEnabled = *req.TelegramAlertsEnabled
	}
	if req.ForceCheckoutEnabled != nil {
		current.ForceCheckoutEnabled = *req.ForceCheckoutEnabled
	}
	if req.TelegramBotToken != nil {
		current.TelegramBotToken = *req.TelegramBotToken
	}
	if req.TelegramChatID != nil {
		current.TelegramChatID = *req.TelegramChatID
	}

	if err := h.settingsService.UpdateSettings(c.Request.Context(), current); err != nil {
		SendError(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to update system settings", err.Error())
		return
	}

	SendSuccess(c, http.StatusOK, current)
}
