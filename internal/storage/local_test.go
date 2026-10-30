package storage

import (
	"bytes"
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLocalStorage_SaveAndDelete(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "storage_test_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	provider, err := NewLocalStorage(tempDir, "/uploads")
	if err != nil {
		t.Fatalf("failed to create LocalStorage: %v", err)
	}

	content := []byte("hello world leave attachment")
	ctx := context.Background()

	fileURL, err := provider.Save(ctx, "medical_certificate.pdf", bytes.NewReader(content))
	if err != nil {
		t.Fatalf("unexpected save error: %v", err)
	}

	if !strings.HasPrefix(fileURL, "/uploads/") || !strings.HasSuffix(fileURL, ".pdf") {
		t.Fatalf("expected /uploads/...pdf, got: %s", fileURL)
	}

	// Verify file exists on disk
	filename := filepath.Base(fileURL)
	diskPath := filepath.Join(tempDir, filename)
	savedBytes, err := os.ReadFile(diskPath)
	if err != nil {
		t.Fatalf("failed to read saved file from disk: %v", err)
	}
	if string(savedBytes) != string(content) {
		t.Fatalf("content mismatch: got %s, want %s", string(savedBytes), string(content))
	}

	// Delete file
	if err := provider.Delete(ctx, fileURL); err != nil {
		t.Fatalf("failed to delete file: %v", err)
	}

	if _, err := os.Stat(diskPath); !os.IsNotExist(err) {
		t.Fatalf("expected file to be deleted, but still exists")
	}
}

