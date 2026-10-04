package jwt

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"location-attendance/internal/domain"
)

var (
	ErrTokenExpired     = errors.New("jwt token has expired")
	ErrTokenInvalid     = errors.New("invalid jwt token")
	ErrInvalidSignature = errors.New("invalid token signature")
	ErrInvalidClaims    = errors.New("invalid token claims")
)

// CustomClaims stores authenticated employee identity in the token
type CustomClaims struct {
	EmployeeID   uuid.UUID   `json:"employeeId"`
	EmployeeCode string      `json:"employeeCode"`
	Role         domain.Role `json:"role"`
	jwt.RegisteredClaims
}

// GenerateToken generates a signed HMAC-SHA256 JWT for an active employee
func GenerateToken(emp *domain.Employee, secret string, ttl time.Duration) (string, time.Time, error) {
	now := time.Now().UTC()
	expiresAt := now.Add(ttl)

	claims := CustomClaims{
		EmployeeID:   emp.ID,
		EmployeeCode: emp.EmployeeCode,
		Role:         emp.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   emp.ID.String(),
			Issuer:    "location-attendance-backend",
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			NotBefore: jwt.NewNumericDate(now),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		return "", time.Time{}, fmt.Errorf("failed to sign jwt: %w", err)
	}

	return tokenString, expiresAt, nil
}

// ValidateToken parses, validates the signature, and verifies the expiration of a JWT
func ValidateToken(tokenString, secret string) (*CustomClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &CustomClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(secret), nil
	})

	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return nil, ErrTokenExpired
		}
		if errors.Is(err, jwt.ErrTokenSignatureInvalid) {
			return nil, ErrInvalidSignature
		}
		return nil, ErrTokenInvalid
	}

	claims, ok := token.Claims.(*CustomClaims)
	if !ok || !token.Valid {
		return nil, ErrInvalidClaims
	}

	if claims.Role != domain.RoleEmployee {
		return nil, domain.ErrForbiddenRole
	}

	return claims, nil
}
