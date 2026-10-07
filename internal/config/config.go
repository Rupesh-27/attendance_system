package config

import (
	"bufio"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Port             string
	DatabaseURL      string
	JWTSecret        string
	JWTExpiration    time.Duration
	RateLimitLogin   float64 // requests per second
	RateLimitBurst   int
	TelegramBotToken string
	TelegramChatID   string
}

func LoadConfig() *Config {
	loadDotEnv(".env")

	port := getEnv("PORT", "8080")
	dbURL := getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/attendance_db?sslmode=disable")
	jwtSecret := getEnv("JWT_SECRET", "super-secret-attendance-key-change-in-production")
	telegramBotToken := getEnv("TELEGRAM_BOT_TOKEN", "")
	telegramChatID := getEnv("TELEGRAM_CHAT_ID", "")

	jwtExpHours, _ := strconv.Atoi(getEnv("JWT_EXPIRATION_HOURS", "24"))
	if jwtExpHours <= 0 {
		jwtExpHours = 24
	}

	return &Config{
		Port:             port,
		DatabaseURL:      dbURL,
		JWTSecret:        jwtSecret,
		JWTExpiration:    time.Duration(jwtExpHours) * time.Hour,
		RateLimitLogin:   1.0,
		RateLimitBurst:   5,
		TelegramBotToken: telegramBotToken,
		TelegramChatID:   telegramChatID,
	}
}

func loadDotEnv(filepath string) {
	file, err := os.Open(filepath)
	if err != nil {
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			val := strings.TrimSpace(parts[1])
			val = strings.Trim(val, `"'`)
			if os.Getenv(key) == "" {
				os.Setenv(key, val)
			}
		}
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
