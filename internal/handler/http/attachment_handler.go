package http

import (
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"location-attendance/internal/storage"
)

type AttachmentHandler struct {
	postgresStorage *storage.PostgresStorage
}

func NewAttachmentHandler(s *storage.PostgresStorage) *AttachmentHandler {
	return &AttachmentHandler{
		postgresStorage: s,
	}
}

// GetAttachment streams stored binary attachments directly from the database with appropriate MIME headers.
func (h *AttachmentHandler) GetAttachment(c *gin.Context) {
	idStr := c.Param("id")
	cleanID := strings.TrimSuffix(idStr, filepath.Ext(idStr))
	id, err := uuid.Parse(cleanID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Invalid attachment ID",
			"code":    "INVALID_ATTACHMENT_ID",
		})
		return
	}

	if h.postgresStorage == nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Database storage provider is not active",
			"code":    "STORAGE_UNAVAILABLE",
		})
		return
	}

	file, err := h.postgresStorage.Get(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"success": false,
			"message": "Attachment not found",
			"code":    "ATTACHMENT_NOT_FOUND",
		})
		return
	}

	c.Header("Content-Type", file.ContentType)
	c.Header("Content-Length", strconv.Itoa(file.FileSize))
	c.Header("Content-Disposition", fmt.Sprintf("inline; filename=\"%s\"", file.FileName))
	c.Header("Cache-Control", "public, max-age=86400")

	c.Data(http.StatusOK, file.ContentType, file.FileData)
}
