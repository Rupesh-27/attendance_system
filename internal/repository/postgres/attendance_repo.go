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
			duration_seconds, checkout_reason, initial_out_of_radius_at, status, attendance_day, created_at, updated_at
		FROM attendance_sessions
		WHERE employee_id = $1 AND status IN ('CHECKED_IN', 'CARRIED_OVER')
		LIMIT 1
	`
	var s domain.AttendanceSession
	var attDay time.Time
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
		&s.CheckoutReason,
		&s.InitialOutOfRadiusAt,
		&s.Status,
		&attDay,
		&s.CreatedAt,
		&s.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, domain.ErrNoActiveSession
		}
		return nil, err
	}
	s.AttendanceDay = attDay.Format("2006-01-02")

	return &s, nil
}

func (r *attendanceRepo) CreateSession(ctx context.Context, s *domain.AttendanceSession) error {
	reason := s.CheckoutReason
	if reason == "" {
		reason = domain.CheckoutReasonManual
	}

	query := `
		INSERT INTO attendance_sessions (
			id, employee_id, office_id,
			office_snapshot_name, office_snapshot_lat, office_snapshot_lon, office_snapshot_radius,
			check_in_time, check_in_latitude, check_in_longitude, check_in_accuracy_meters, check_in_captured_at, check_in_distance_meters,
			checkout_reason, initial_out_of_radius_at, status, attendance_day, created_at, updated_at
		) VALUES (
			$1, $2, $3,
			$4, $5, $6, $7,
			$8, $9, $10, $11, $12, $13,
			$14, $15, $16, $17, $18, $19
		)
	`
	var attDay time.Time
	if s.AttendanceDay != "" {
		if parsed, err := time.Parse("2006-01-02", s.AttendanceDay); err == nil {
			attDay = parsed
		} else {
			attDay = s.CheckInTime
		}
	} else {
		attDay = s.CheckInTime
	}

	_, err := r.db.Pool.Exec(ctx, query,
		s.ID, s.EmployeeID, s.OfficeID,
		s.OfficeSnapshotName, s.OfficeSnapshotLat, s.OfficeSnapshotLon, s.OfficeSnapshotRadius,
		s.CheckInTime, s.CheckInLatitude, s.CheckInLongitude, s.CheckInAccuracyMeters, s.CheckInCapturedAt, s.CheckInDistanceMeters,
		reason, s.InitialOutOfRadiusAt, s.Status, attDay, s.CreatedAt, s.UpdatedAt,
	)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			return domain.ErrActiveSessionExists
		}
		return err
	}

	return nil
}

func (r *attendanceRepo) UpdateSession(ctx context.Context, s *domain.AttendanceSession) error {
	reason := s.CheckoutReason
	if reason == "" {
		reason = domain.CheckoutReasonManual
	}

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
			checkout_reason = $8,
			initial_out_of_radius_at = $9,
			status = $10,
			updated_at = $11
		WHERE id = $12
	`
	cmdTag, err := r.db.Pool.Exec(ctx, query,
		s.CheckOutTime,
		s.CheckOutLatitude,
		s.CheckOutLongitude,
		s.CheckOutAccuracyMeters,
		s.CheckOutCapturedAt,
		s.CheckOutDistanceMeters,
		s.DurationSeconds,
		reason,
		s.InitialOutOfRadiusAt,
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

func (r *attendanceRepo) UpdateSessionStatus(ctx context.Context, sessionID uuid.UUID, status domain.AttendanceStatus) error {
	query := `
		UPDATE attendance_sessions
		SET status = $1, updated_at = NOW()
		WHERE id = $2
	`
	cmdTag, err := r.db.Pool.Exec(ctx, query, status, sessionID)
	if err != nil {
		return err
	}
	if cmdTag.RowsAffected() == 0 {
		return domain.ErrNoActiveSession
	}
	return nil
}

func (r *attendanceRepo) UpdateInitialOutOfRadiusAt(ctx context.Context, sessionID uuid.UUID, breachTime *time.Time) error {
	query := `
		UPDATE attendance_sessions
		SET initial_out_of_radius_at = $1, updated_at = NOW()
		WHERE id = $2
	`
	cmdTag, err := r.db.Pool.Exec(ctx, query, breachTime, sessionID)
	if err != nil {
		return err
	}
	if cmdTag.RowsAffected() == 0 {
		return domain.ErrNoActiveSession
	}
	return nil
}

func (r *attendanceRepo) GetSessionsByAttendanceDay(ctx context.Context, employeeID uuid.UUID, attendanceDay string) ([]*domain.AttendanceSession, error) {
	query := `
		SELECT
			id, employee_id, office_id,
			office_snapshot_name, office_snapshot_lat, office_snapshot_lon, office_snapshot_radius,
			check_in_time, check_in_latitude, check_in_longitude, check_in_accuracy_meters, check_in_captured_at, check_in_distance_meters,
			check_out_time, check_out_latitude, check_out_longitude, check_out_accuracy_meters, check_out_captured_at, check_out_distance_meters,
			duration_seconds, checkout_reason, initial_out_of_radius_at, status, attendance_day, created_at, updated_at
		FROM attendance_sessions
		WHERE employee_id = $1 AND attendance_day = $2
		ORDER BY check_in_time ASC
	`
	rows, err := r.db.Pool.Query(ctx, query, employeeID, attendanceDay)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var sessions []*domain.AttendanceSession
	for rows.Next() {
		var s domain.AttendanceSession
		var attDay time.Time
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
			&s.CheckoutReason,
			&s.InitialOutOfRadiusAt,
			&s.Status,
			&attDay,
			&s.CreatedAt,
			&s.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		s.AttendanceDay = attDay.Format("2006-01-02")
		sessions = append(sessions, &s)
	}

	return sessions, nil
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
			duration_seconds, checkout_reason, initial_out_of_radius_at, status, attendance_day, created_at, updated_at
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
		var attDay time.Time
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
			&s.CheckoutReason,
			&s.InitialOutOfRadiusAt,
			&s.Status,
			&attDay,
			&s.CreatedAt,
			&s.UpdatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		s.AttendanceDay = attDay.Format("2006-01-02")
		sessions = append(sessions, &s)
	}

	return sessions, total, nil
}
