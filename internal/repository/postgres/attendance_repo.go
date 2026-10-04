package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"location-attendance/internal/domain"
	"location-attendance/internal/repository"
)

type attendanceRepo struct {
	db *DB
}

func NewAttendanceRepository(db *DB) repository.AttendanceRepository {
	return &attendanceRepo{db: db}
}

func (r *attendanceRepo) GetActiveSession(ctx context.Context, employeeID uuid.UUID) (*domain.AttendanceSession, error) {
	query := `
		SELECT 
			id, employee_id, office_id, 
			office_snapshot_name, office_snapshot_lat, office_snapshot_lon, office_snapshot_radius,
			check_in_time, check_in_latitude, check_in_longitude, check_in_accuracy_meters, check_in_captured_at, check_in_distance_meters,
			check_out_time, check_out_latitude, check_out_longitude, check_out_accuracy_meters, check_out_captured_at, check_out_distance_meters,
			duration_seconds, status, created_at, updated_at
		FROM attendance_sessions
		WHERE employee_id = $1 AND status = 'CHECKED_IN'
		LIMIT 1
	`
	var s domain.AttendanceSession
	err := r.db.Pool.QueryRow(ctx, query, employeeID).Scan(
		&s.ID,
		&s.EmployeeID,
		&s.OfficeID,
		&s.OfficeSnapshotName,
		&s.OfficeSnapshotLat,
		&s.OfficeSnapshotLon,
		&s.OfficeSnapshotRadius,
		&s.CheckInTime,
		&s.CheckInLatitude,
		&s.CheckInLongitude,
		&s.CheckInAccuracyMeters,
		&s.CheckInCapturedAt,
		&s.CheckInDistanceMeters,
		&s.CheckOutTime,
		&s.CheckOutLatitude,
		&s.CheckOutLongitude,
		&s.CheckOutAccuracyMeters,
		&s.CheckOutCapturedAt,
		&s.CheckOutDistanceMeters,
		&s.DurationSeconds,
		&s.Status,
		&s.CreatedAt,
		&s.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrNoActiveSession
		}
		return nil, err
	}

	return &s, nil
}

func (r *attendanceRepo) CreateSession(ctx context.Context, s *domain.AttendanceSession) error {
	query := `
		INSERT INTO attendance_sessions (
			id, employee_id, office_id,
			office_snapshot_name, office_snapshot_lat, office_snapshot_lon, office_snapshot_radius,
			check_in_time, check_in_latitude, check_in_longitude, check_in_accuracy_meters, check_in_captured_at, check_in_distance_meters,
			status, created_at, updated_at
		) VALUES (
			$1, $2, $3,
			$4, $5, $6, $7,
			$8, $9, $10, $11, $12, $13,
			$14, $15, $16
		)
	`
	_, err := r.db.Pool.Exec(ctx, query,
		s.ID, s.EmployeeID, s.OfficeID,
		s.OfficeSnapshotName, s.OfficeSnapshotLat, s.OfficeSnapshotLon, s.OfficeSnapshotRadius,
		s.CheckInTime, s.CheckInLatitude, s.CheckInLongitude, s.CheckInAccuracyMeters, s.CheckInCapturedAt, s.CheckInDistanceMeters,
		s.Status, s.CreatedAt, s.UpdatedAt,
	)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" { // unique_violation
			return domain.ErrActiveSessionExists
		}
		return err
	}

	return nil
}

func (r *attendanceRepo) UpdateSession(ctx context.Context, s *domain.AttendanceSession) error {
	query := `
		UPDATE attendance_sessions
		SET 
			check_out_time = $1,
			check_out_latitude = $2,
			check_out_longitude = $3,
			check_out_accuracy_meters = $4,
			check_out_captured_at = $5,
			check_out_distance_meters = $6,
			duration_seconds = $7,
			status = $8,
			updated_at = $9
		WHERE id = $10
	`
	cmdTag, err := r.db.Pool.Exec(ctx, query,
		s.CheckOutTime,
		s.CheckOutLatitude,
		s.CheckOutLongitude,
		s.CheckOutAccuracyMeters,
		s.CheckOutCapturedAt,
		s.CheckOutDistanceMeters,
		s.DurationSeconds,
		s.Status,
		s.UpdatedAt,
		s.ID,
	)
	if err != nil {
		return err
	}
	if cmdTag.RowsAffected() == 0 {
		return domain.ErrNoActiveSession
	}

	return nil
}

func (r *attendanceRepo) GetHistoryByEmployeeID(
	ctx context.Context,
	employeeID uuid.UUID,
	from, to *time.Time,
	limit, offset int,
) ([]*domain.AttendanceSession, int64, error) {
	countQuery := `
		SELECT COUNT(*)
		FROM attendance_sessions
		WHERE employee_id = $1
		  AND ($2::timestamptz IS NULL OR check_in_time >= $2)
		  AND ($3::timestamptz IS NULL OR check_in_time <= $3)
	`
	var total int64
	if err := r.db.Pool.QueryRow(ctx, countQuery, employeeID, from, to).Scan(&total); err != nil {
		return nil, 0, err
	}

	selectQuery := `
		SELECT 
			id, employee_id, office_id, 
			office_snapshot_name, office_snapshot_lat, office_snapshot_lon, office_snapshot_radius,
			check_in_time, check_in_latitude, check_in_longitude, check_in_accuracy_meters, check_in_captured_at, check_in_distance_meters,
			check_out_time, check_out_latitude, check_out_longitude, check_out_accuracy_meters, check_out_captured_at, check_out_distance_meters,
			duration_seconds, status, created_at, updated_at
		FROM attendance_sessions
		WHERE employee_id = $1
		  AND ($2::timestamptz IS NULL OR check_in_time >= $2)
		  AND ($3::timestamptz IS NULL OR check_in_time <= $3)
		ORDER BY check_in_time DESC
		LIMIT $4 OFFSET $5
	`
	rows, err := r.db.Pool.Query(ctx, selectQuery, employeeID, from, to, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var sessions []*domain.AttendanceSession
	for rows.Next() {
		var s domain.AttendanceSession
		err := rows.Scan(
			&s.ID,
			&s.EmployeeID,
			&s.OfficeID,
			&s.OfficeSnapshotName,
			&s.OfficeSnapshotLat,
			&s.OfficeSnapshotLon,
			&s.OfficeSnapshotRadius,
			&s.CheckInTime,
			&s.CheckInLatitude,
			&s.CheckInLongitude,
			&s.CheckInAccuracyMeters,
			&s.CheckInCapturedAt,
			&s.CheckInDistanceMeters,
			&s.CheckOutTime,
			&s.CheckOutLatitude,
			&s.CheckOutLongitude,
			&s.CheckOutAccuracyMeters,
			&s.CheckOutCapturedAt,
			&s.CheckOutDistanceMeters,
			&s.DurationSeconds,
			&s.Status,
			&s.CreatedAt,
			&s.UpdatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		sessions = append(sessions, &s)
	}

	return sessions, total, nil
}
