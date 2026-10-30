package http

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

type mockStorage struct {
	savedFilename string
	savedBytes    []byte
}

func (m *mockStorage) Save(ctx context.Context, originalFilename string, r io.Reader) (string, error) {
	data, _ := io.ReadAll(r)
	m.savedFilename = originalFilename
	m.savedBytes = data
	return "/uploads/mock-saved-" + originalFilename, nil
}

func (m *mockStorage) Delete(ctx context.Context, fileURL string) error {
	return nil
}

func TestUploadHandler_UploadSuccess(t *testing.T) {
	gin.SetMode(gin.TestMode)
	storage := &mockStorage{}
	h := NewUploadHandler(storage, 5)

	router := gin.New()
	router.POST("/upload", h.Upload)

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("file", "doctor_note.pdf")
	if err != nil {
		t.Fatalf("failed to create form file: %v", err)
	}
	sampleContent := []byte("Medical certificate for sick leave")
	part.Write(sampleContent)
	writer.Close()

	req, _ := http.NewRequest(http.MethodPost, "/upload", body)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got: %d, body: %s", w.Code, w.Body.String())
	}

	var resp map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to parse json response: %v", err)
	}

	if resp["success"] != true {
		t.Fatalf("expected success true, got: %v", resp["success"])
	}

	data := resp["data"].(map[string]interface{})
	if data["url"] != "/uploads/mock-saved-doctor_note.pdf" {
		t.Fatalf("unexpected url: %v", data["url"])
	}
}

func TestUploadHandler_DisallowedFileType(t *testing.T) {
	gin.SetMode(gin.TestMode)
	storage := &mockStorage{}
	h := NewUploadHandler(storage, 5)

	router := gin.New()
	router.POST("/upload", h.Upload)

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, _ := writer.CreateFormFile("file", "malicious_script.exe")
	part.Write([]byte("danger"))
	writer.Close()

	req, _ := http.NewRequest(http.MethodPost, "/upload", body)
	req.Header.Set("Content-Type", writer.FormDataContentType())

	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400 for exe file, got: %d", w.Code)
	}
}

