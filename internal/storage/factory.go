package storage

import (
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Config holds configuration parameters for file storage providers.
type Config struct {
	Driver   string        // "db" (default when pool present), "local", or "s3"
	LocalDir string        // e.g. "./uploads"
	BaseURL  string        // e.g. "/api/v1/attachments" or "/uploads"
	DBPool   *pgxpool.Pool // PostgreSQL connection pool for database storage
}

// NewStorageProvider creates and returns the appropriate StorageProvider based on configuration.
func NewStorageProvider(cfg Config) (StorageProvider, error) {
	driver := strings.ToLower(cfg.Driver)

	// If driver is explicitly db/postgres or empty with pool provided, use PostgreSQL
	if driver == "db" || driver == "postgres" || (driver == "" && cfg.DBPool != nil) {
		if cfg.DBPool == nil {
			// In-memory / mock repository fallback when database connection is not active
			dir := cfg.LocalDir
			if dir == "" {
				dir = "./uploads"
			}
			baseURL := cfg.BaseURL
			if baseURL == "" || baseURL == "/api/v1/attachments" {
				baseURL = "/uploads"
			}
			return NewLocalStorage(dir, baseURL)
		}
		return NewPostgresStorage(cfg.DBPool, cfg.BaseURL), nil
	}

	switch driver {
	case "local", "":
		dir := cfg.LocalDir
		if dir == "" {
			dir = "./uploads"
		}
		return NewLocalStorage(dir, cfg.BaseURL)
	case "s3":
		return nil, fmt.Errorf("S3 storage driver is not yet initialized; configure AWS credentials")
	default:
		return nil, fmt.Errorf("unsupported storage driver: %s", cfg.Driver)
	}
}
