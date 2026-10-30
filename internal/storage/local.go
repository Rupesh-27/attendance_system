package storage

import (
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
)

// LocalStorage implements StorageProvider by persisting files to a local directory on disk.
type LocalStorage struct {
	baseDir string
	baseURL string
}

// NewLocalStorage creates a new LocalStorage instance with a target directory and public base URL.
func NewLocalStorage(baseDir, baseURL string) (*LocalStorage, error) {
	cleanDir := filepath.Clean(baseDir)
	if err := os.MkdirAll(cleanDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create upload directory %s: %w", cleanDir, err)
	}

	cleanBaseURL := strings.TrimRight(baseURL, "/")
	if cleanBaseURL == "" {
		cleanBaseURL = "/uploads"
	}

	return &LocalStorage{
		baseDir: cleanDir,
		baseURL: cleanBaseURL,
	}, nil
}

// Save writes the incoming file content to disk under a uniquely generated UUID filename.
func (s *LocalStorage) Save(ctx context.Context, originalFilename string, r io.Reader) (string, error) {
	ext := filepath.Ext(originalFilename)
	uniqueFilename := fmt.Sprintf("%s%s", uuid.New().String(), strings.ToLower(ext))
	targetPath := filepath.Join(s.baseDir, uniqueFilename)

	dst, err := os.Create(targetPath)
	if err != nil {
		return "", fmt.Errorf("failed to create destination file: %w", err)
	}
	defer dst.Close()

	if _, err := io.Copy(dst, r); err != nil {
		_ = os.Remove(targetPath)
		return "", fmt.Errorf("failed to write file contents: %w", err)
	}

	return fmt.Sprintf("%s/%s", s.baseURL, uniqueFilename), nil
}

// Delete removes a file stored locally, ensuring path safety against directory traversal.
func (s *LocalStorage) Delete(ctx context.Context, fileURL string) error {
	filename := filepath.Base(fileURL)
	if filename == "." || filename == "/" || strings.Contains(filename, "..") {
		return fmt.Errorf("invalid file path")
	}

	targetPath := filepath.Join(s.baseDir, filename)
	if err := os.Remove(targetPath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to delete file: %w", err)
	}

	return nil
}

