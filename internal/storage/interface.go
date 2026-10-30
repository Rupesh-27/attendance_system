package storage

import (
	"context"
	"io"
)

// StorageProvider defines the contract for persisting and retrieving attachments.
// This interface allows seamless switching between local disk storage and cloud storage (e.g. AWS S3).
type StorageProvider interface {
	// Save persists a file from an io.Reader and returns the accessible URL or path.
	Save(ctx context.Context, originalFilename string, r io.Reader) (string, error)

	// Delete removes an existing file given its URL or path.
	Delete(ctx context.Context, fileURL string) error
}

