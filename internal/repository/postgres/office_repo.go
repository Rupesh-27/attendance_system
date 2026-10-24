package postgres

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type officeRepo struct {
	db *DB
}

func NewOfficeRepository(db *DB) repository.OfficeRepository {
	return &officeRepo{db: db}
}

func (r *officeRepo) GetByID(ctx context.Context, id uuid.UUID) (*domain.Office, error) {
	queryWithTz := `
		SELECT id, name, latitude, longitude, radius_meters, timezone, is_active, created_at, updated_at
		FROM offices
		WHERE id = $1
	`
	var office domain.Office
	err := r.db.Pool.QueryRow(ctx, queryWithTz, id).Scan(
		&office.ID,
		&office.Name,
		&office.Latitude,
		&office.Longitude,
		&office.RadiusMeters,
		&office.Timezone,
		&office.IsActive,
		&office.CreatedAt,
		&office.UpdatedAt,
	)
	if err == nil {
		return &office, nil
	}
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, domain.ErrOfficeNotFound
	}

	// Fallback query for database instances where timezone column migration is not yet executed
	queryLegacy := `
		SELECT id, name, latitude, longitude, radius_meters, is_active, created_at, updated_at
		FROM offices
		WHERE id = $1
	`
	errLegacy := r.db.Pool.QueryRow(ctx, queryLegacy, id).Scan(
		&office.ID,
		&office.Name,
		&office.Latitude,
		&office.Longitude,
		&office.RadiusMeters,
		&office.IsActive,
		&office.CreatedAt,
		&office.UpdatedAt,
	)
	if errLegacy != nil {
		if errors.Is(errLegacy, pgx.ErrNoRows) {
			return nil, domain.ErrOfficeNotFound
		}
		return nil, errLegacy
	}
	office.Timezone = "Asia/Kolkata"
	return &office, nil
}
