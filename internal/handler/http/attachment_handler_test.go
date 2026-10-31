package http

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestAttachmentHandler_InvalidID(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewAttachmentHandler(nil)

	router := gin.New()
	router.GET("/attachments/:id", h.GetAttachment)

	req, _ := http.NewRequest(http.MethodGet, "/attachments/not-a-valid-uuid", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400 for invalid UUID, got: %d", w.Code)
	}

	var resp map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to parse json response: %v", err)
	}
	if resp["code"] != "INVALID_ATTACHMENT_ID" {
		t.Fatalf("expected code INVALID_ATTACHMENT_ID, got: %v", resp["code"])
	}
}

func TestAttachmentHandler_StorageUnavailable(t *testing.T) {
	gin.SetMode(gin.TestMode)
	h := NewAttachmentHandler(nil)

	router := gin.New()
	router.GET("/attachments/:id", h.GetAttachment)

	req, _ := http.NewRequest(http.MethodGet, "/attachments/a0000000-0000-0000-0000-000000000001.png", nil)
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)

	if w.Code != http.StatusNotFound {
		t.Fatalf("expected status 404 when storage provider is nil, got: %d", w.Code)
	}

	var resp map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to parse json response: %v", err)
	}
	if resp["code"] != "STORAGE_UNAVAILABLE" {
		t.Fatalf("expected code STORAGE_UNAVAILABLE, got: %v", resp["code"])
	}
}

