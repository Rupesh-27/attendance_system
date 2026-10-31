package storage

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// AttachmentFile holds binary attachment contents retrieved from the database.
type AttachmentFile struct {
	ID          uuid.UUID
	FileName    string
	ContentType string
	FileSize    int
	FileData    []byte
}

// PostgresStorage persists files directly into PostgreSQL as binary (BYTEA) records.
type PostgresStorage struct {
	pool    *pgxpool.Pool
	baseURL string
}

// NewPostgresStorage creates a new PostgreSQL storage provider.
func NewPostgresStorage(pool *pgxpool.Pool, baseURL string) *PostgresStorage {
	cleanBaseURL := strings.TrimRight(baseURL, "/")
	if cleanBaseURL == "" {
		cleanBaseURL = "/api/v1/attachments"
	}

	return &PostgresStorage{
		pool:    pool,
		baseURL: cleanBaseURL,
	}
}

// Save reads all file content and stores it directly into leave_attachment_files table.
func (s *PostgresStorage) Save(ctx context.Context, originalFilename string, r io.Reader) (string, error) {
	data, err := io.ReadAll(r)
	if err != nil {
		return "", fmt.Errorf("failed to read file bytes: %w", err)
	}

	ext := strings.ToLower(filepath.Ext(originalFilename))
	var contentType string
	switch ext {
	case ".pdf":
		contentType = "application/pdf"
	case ".png":
		contentType = "image/png"
	case ".jpg", ".jpeg":
		contentType = "image/jpeg"
	case ".doc":
		contentType = "application/msword"
	case ".docx":
		contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
	default:
		contentType = http.DetectContentType(data)
	}

	id := uuid.New()
	query := `
		INSERT INTO leave_attachment_files (id, file_name, content_type, file_size, file_data, created_at)
		VALUES ($1, $2, $3, $4, $5, NOW())
	`

	_, err = s.pool.Exec(ctx, query, id, originalFilename, contentType, len(data), data)
	if err != nil {
		return "", fmt.Errorf("failed to store attachment in database: %w", err)
	}

	return fmt.Sprintf("%s/%s%s", s.baseURL, id.String(), ext), nil
}

// Get retrieves attachment metadata and raw file bytes from PostgreSQL by UUID.
func (s *PostgresStorage) Get(ctx context.Context, id uuid.UUID) (*AttachmentFile, error) {
	query := `
		SELECT id, file_name, content_type, file_size, file_data
		FROM leave_attachment_files
		WHERE id = $1
	`

	f := &AttachmentFile{}
	err := s.pool.QueryRow(ctx, query, id).Scan(&f.ID, &f.FileName, &f.ContentType, &f.FileSize, &f.FileData)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("attachment not found")
		}
		return nil, fmt.Errorf("failed to retrieve attachment from database: %w", err)
	}

	return f, nil
}

// Delete removes an attachment record from PostgreSQL.
func (s *PostgresStorage) Delete(ctx context.Context, fileURL string) error {
	rawID := filepath.Base(fileURL)
	rawID = strings.TrimSuffix(rawID, filepath.Ext(rawID))
	id, err := uuid.Parse(rawID)
	if err != nil {
		return fmt.Errorf("invalid attachment id in url: %w", err)
	}

	query := `DELETE FROM leave_attachment_files WHERE id = $1`
	_, err = s.pool.Exec(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete attachment from database: %w", err)
	}

	return nil
}
