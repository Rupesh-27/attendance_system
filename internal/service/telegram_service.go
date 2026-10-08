package service

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type TelegramService interface {
	SendForceCheckoutAlert(ctx context.Context, emp *domain.Employee, office *domain.Office, session *domain.AttendanceSession, distanceMeters float64) error
	SendMessage(ctx context.Context, text string) error
}

type telegramService struct {
	settingsRepo   repository.SettingsRepository
	fallbackToken  string
	fallbackChatID string
	httpClient     *http.Client
}

func NewTelegramService(settingsRepo repository.SettingsRepository, fallbackToken, fallbackChatID string) TelegramService {
	return &telegramService{
		settingsRepo:   settingsRepo,
		fallbackToken:  fallbackToken,
		fallbackChatID: fallbackChatID,
		httpClient:     &http.Client{Timeout: 8 * time.Second},
	}
}

func (s *telegramService) getCredentials(ctx context.Context) (botToken string, chatID string, enabled bool) {
	enabled = true
	if s.settingsRepo != nil {
		if st, err := s.settingsRepo.GetSettings(ctx); err == nil && st != nil {
			enabled = st.TelegramAlertsEnabled
			botToken = st.TelegramBotToken
			chatID = st.TelegramChatID
		}
	}
	if botToken == "" {
		botToken = s.fallbackToken
	}
	if chatID == "" {
		chatID = s.fallbackChatID
	}
	return botToken, chatID, enabled
}

func (s *telegramService) SendMessage(ctx context.Context, text string) error {
	botToken, chatID, enabled := s.getCredentials(ctx)
	if !enabled {
		log.Printf("[Telegram] Telegram alerts are disabled in settings")
		return nil
	}
	if botToken == "" || chatID == "" {
		log.Printf("[Telegram] Bot token or chat ID is missing. Skipping Telegram notification.")
		return nil
	}

	payload := map[string]interface{}{
		"chat_id":    chatID,
		"text":       text,
		"parse_mode": "HTML",
	}

	jsonBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal telegram payload: %w", err)
	}

	url := fmt.Sprintf("https://api.telegram.org/bot%s/sendMessage", botToken)
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonBytes))
	if err != nil {
		return fmt.Errorf("failed to create telegram request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		log.Printf("[Telegram] Network error sending alert: %v", err)
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		body, _ := io.ReadAll(resp.Body)
		log.Printf("[Telegram] Telegram API error (%d): %s", resp.StatusCode, string(body))
		return fmt.Errorf("telegram API returned status %d: %s", resp.StatusCode, string(body))
	}

	log.Printf("[Telegram] Alert message sent successfully to chat %s", chatID)
	return nil
}

func (s *telegramService) SendForceCheckoutAlert(
	ctx context.Context,
	emp *domain.Employee,
	office *domain.Office,
	session *domain.AttendanceSession,
	distanceMeters float64,
) error {
	loc, err := time.LoadLocation("Asia/Kolkata")
	if err != nil {
		loc = time.Local
	}

	checkoutTimeStr := "Just now"
	if session.CheckOutTime != nil {
		checkoutTimeStr = session.CheckOutTime.In(loc).Format("02 Jan 2006, 03:04:02 PM IST")
	}

	empName := "Unknown Employee"
	empCode := "N/A"
	if emp != nil {
		empName = emp.FullName
		empCode = emp.EmployeeCode
	}

	officeName := session.OfficeSnapshotName
	radius := session.OfficeSnapshotRadius
	if office != nil {
		officeName = office.Name
		radius = office.RadiusMeters
	}

	msg := fmt.Sprintf(
		"<b>HR Attendance Alert: Out-of-Radius Force Checkout</b>\n\n"+
			"<b>Employee:</b> %s (%s)\n"+
			"<b>Assigned Office:</b> %s\n"+
			"<b>Allowed Radius:</b> %.0fm\n"+
			"<b>Current Distance:</b> %.1fm\n"+
			"<b>Checkout Time:</b> %s\n"+
			"<b>Reason:</b> Employee remained outside the designated office boundary for more than 2 minutes.",
		empName,
		empCode,
		officeName,
		radius,
		distanceMeters,
		checkoutTimeStr,
	)

	return s.SendMessage(ctx, msg)
}
