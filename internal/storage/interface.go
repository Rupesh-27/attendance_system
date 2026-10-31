package storage

import (
	"context"
	"io"

	"github.com/google/uuid"
)

type contextKey string

const (
	ctxKeyEmployeeID    contextKey = "storage_employee_id"
	ctxKeyApplicationID contextKey = "storage_application_id"
)

// WithEmployeeID attaches the uploader's employee ID to the context.
func WithEmployeeID(ctx context.Context, id uuid.UUID) context.Context {
	return context.WithValue(ctx, ctxKeyEmployeeID, id)
}

// WithApplicationID attaches the leave application ID to the context.
func WithApplicationID(ctx context.Context, id uuid.UUID) context.Context {
	return context.WithValue(ctx, ctxKeyApplicationID, id)
}

// StorageProvider defines the contract for persisting and retrieving attachments.
// This interface allows seamless switching between local disk storage and cloud storage (e.g. AWS S3).
type StorageProvider interface {
	// Save persists a file from an io.Reader and returns the accessible URL or path.
	Save(ctx context.Context, originalFilename string, r io.Reader) (string, error)

	// Delete removes an existing file given its URL or path.
	Delete(ctx context.Context, fileURL string) error
}

