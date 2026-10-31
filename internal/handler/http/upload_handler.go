package http

import (
	"fmt"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"location-attendance/internal/middleware"
	"location-attendance/internal/storage"
)

type UploadHandler struct {
	storage        storage.StorageProvider
	maxUploadBytes int64
}

func NewUploadHandler(storage storage.StorageProvider, maxUploadSizeMB int) *UploadHandler {
	if maxUploadSizeMB <= 0 {
		maxUploadSizeMB = 10
	}
	return &UploadHandler{
		storage:        storage,
		maxUploadBytes: int64(maxUploadSizeMB) * 1024 * 1024,
	}
}

// Upload handles multipart/form-data upload for leave attachments and documents.
func (h *UploadHandler) Upload(c *gin.Context) {
	// Limit request body size
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, h.maxUploadBytes)

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid file upload: please provide a file under the 'file' field (max 10MB)",
			"code":    "INVALID_FILE",
		})
		return
	}
	defer file.Close()

	if header.Size > h.maxUploadBytes {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": fmt.Sprintf("File exceeds maximum allowed size of %dMB", h.maxUploadBytes/(1024*1024)),
			"code":    "FILE_TOO_LARGE",
		})
		return
	}

	ext := strings.ToLower(filepath.Ext(header.Filename))
	allowedExtensions := map[string]bool{
		".pdf":  true,
		".png":  true,
		".jpg":  true,
		".jpeg": true,
		".doc":  true,
		".docx": true,
	}

	if !allowedExtensions[ext] {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Unsupported file format. Allowed formats: PDF, PNG, JPG, JPEG, DOC, DOCX",
			"code":    "INVALID_FILE_TYPE",
		})
		return
	}

	uploadCtx := c.Request.Context()
	if empIDVal, exists := c.Get(middleware.ContextKeyEmployeeID); exists {
		if empID, ok := empIDVal.(uuid.UUID); ok {
			uploadCtx = storage.WithEmployeeID(uploadCtx, empID)
		}
	}

	fileURL, err := h.storage.Save(uploadCtx, header.Filename, file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Failed to store file: " + err.Error(),
			"code":    "STORAGE_ERROR",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "File uploaded successfully",
		"data": gin.H{
			"url":      fileURL,
			"filename": header.Filename,
			"size":     header.Size,
		},
	})
}

