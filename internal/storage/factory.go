package storage

import (
	"fmt"
	"strings"
)

// Config holds configuration parameters for file storage providers.
type Config struct {
	Driver   string // "local" or "s3"
	LocalDir string // e.g. "./uploads"
	BaseURL  string // e.g. "/uploads" or "https://bucket.s3.amazonaws.com"
}

// NewStorageProvider creates and returns the appropriate StorageProvider based on configuration.
func NewStorageProvider(cfg Config) (StorageProvider, error) {
	switch strings.ToLower(cfg.Driver) {
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

