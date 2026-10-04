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
	query := `
		SELECT id, name, latitude, longitude, radius_meters, is_active, created_at, updated_at
		FROM offices
		WHERE id = $1
	`
	var office domain.Office
	err := r.db.Pool.QueryRow(ctx, query, id).Scan(
		&office.ID,
		&office.Name,
		&office.Latitude,
		&office.Longitude,
		&office.RadiusMeters,
		&office.IsActive,
		&office.CreatedAt,
		&office.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrOfficeNotFound
		}
		return nil, err
	}

	return &office, nil
}
