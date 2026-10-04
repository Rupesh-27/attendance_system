# BrandHRMS - Mobile Attendance API Specification
## Shared Integration Contract (Version 1.0.0)

**Application**: BrandHRMS Location-Based Mobile Attendance  
**Base URL**: `/api/v1`  
**Protocol**: HTTPS (JSON over HTTP/1.1 or HTTP/2)  
**Standard Authorization**: `Authorization: Bearer <access_token>`  
**Reference Document**: *BrandHRMS Backend Authentication and Attendance API Developer Implementation Guide (Version 1.0.0, 22 September 2026)*

---

## 1. System Conventions & Strict Units

| Property | Standard / Unit | Example / Constraint |
| :--- | :--- | :--- |
| **Coordinate System** | WGS-84 Decimal Degrees | `13.082700`, `80.270700` (Latitude: `[-90, 90]`, Longitude: `[-180, 180]`) |
| **Distance & Geofence** | SI Meters (floating point) | `10.0` meters (Default office radius: `10m`) |
| **Accuracy Threshold** | SI Meters (floating point) | Maximum allowed accuracy: `20.0m` |
| **Timestamps** | UTC ISO-8601 (`RFC3339`) | `2026-08-14T08:59:41Z` (All server decisions use UTC server clock) |
| **Working Duration** | Integer Seconds | `28800` (8 hours) |
| **Attendance Source** | Enum String | `"GPS_MOBILE"` (coexists with legacy `"BIOMETRIC"` and `"WEB"`) |
| **Server Authority** | Server Timestamp & Server Distance | Client `capturedAt` is preserved as forensic evidence only |

---

## 2. Standard Response Shapes

### 2.1 Standard Error Response (HTTP 4xx / 5xx)
All error responses strictly follow the single uniform shape defined in the BrandHRMS Guide (Page 7):
```json
{
  "success": false,
  "code": "OUTSIDE_RADIUS",
  "message": "current location is outside the assigned office radius",
  "details": null
}
```

### 2.2 Standard Error Codes Catalog

| HTTP Status | Error Code | Trigger Condition | Client Behavior (Flutter) |
| :---: | :--- | :--- | :--- |
| **401** | `AUTH_INVALID` | Invalid credentials, missing/malformed token, or inactive account | Show neutral login error |
| **401** | `AUTH_EXPIRED` | JWT access token expired | Clear session & redirect to login |
| **403** | `FORBIDDEN` | Authenticated user lacks required role (`EMPLOYEE`) | Show access denied; do not retry |
| **400** | `LOCATION_REQUIRED` | Coordinates missing, invalid range, or malformed body | Prompt user to re-acquire GPS fix |
| **422** | `LOCATION_INACCURATE` | Reported accuracy > 20 meters | Prompt user to move to an open area |
| **422** | `OUTSIDE_RADIUS` | Haversine distance exceeds office geofence radius | Display distance and guide user closer |
| **409** | `ALREADY_CHECKED_IN` | Active `CHECKED_IN` session already exists | Refresh current attendance state |
| **400** | `NOT_CHECKED_IN` | No active open session found when checking out | Refresh current attendance state |
| **404** | `NOT_FOUND` | Employee or assigned office record does not exist | Show resource not found message |
| **500** | `INTERNAL_SERVER_ERROR` | Unhandled server error | Show generic retry prompt |
| *Client*| `NETWORK_ERROR` | Device cannot reach backend server | Keep action unconfirmed; retry |

---

## 3. Authoritative Distance Algorithm

Calculated server-side using the great-circle Haversine formula with spherical Earth radius $R = 6,371,000.0\text{ meters}$:
$$\Delta\phi = \frac{\pi}{180}(\text{lat}_2 - \text{lat}_1),\quad \Delta\lambda = \frac{\pi}{180}(\text{lon}_2 - \text{lon}_1)$$
$$a = \sin^2\left(\frac{\Delta\phi}{2}\right) + \cos(\phi_1)\cos(\phi_2)\sin^2\left(\frac{\Delta\lambda}{2}\right)$$
$$d = 2 \cdot R \cdot \operatorname{atan2}\left(\sqrt{a}, \sqrt{1 - a}\right)$$

---

## 4. API Endpoint Specifications

### 4.1 Employee Login
`POST /api/v1/auth/login`
* **Access**: Public (Protected by IP Rate Limiter: 5 req/s)
* **Description**: Verifies credentials and returns a signed HMAC-SHA256 JWT.

#### Request Body
```json
{
  "employeeCode": "EMP1001",
  "password": "Password123!"
}
```

#### Success Response (`200 OK`)
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAt": "2026-09-25T03:00:00Z",
    "employee": {
      "id": "e4b5a320-1a7f-4a3e-b7d1-5a2e1d09e8a1",
      "employeeCode": "EMP1001",
      "fullName": "Bhavani Johnson",
      "role": "EMPLOYEE",
      "officeId": "c3a1b2d0-8f9e-4e2a-a1b2-c3d4e5f6a7b8",
      "isActive": true,
      "createdAt": "2026-01-01T00:00:00Z",
      "updatedAt": "2026-01-01T00:00:00Z"
    }
  }
}
```

---

### 4.2 Current User Profile
`GET /api/v1/me`
* **Access**: Authenticated (`EMPLOYEE`)
* **Headers**: `Authorization: Bearer <token>`

#### Success Response (`200 OK`)
```json
{
  "success": true,
  "data": {
    "id": "e4b5a320-1a7f-4a3e-b7d1-5a2e1d09e8a1",
    "employeeCode": "EMP1001",
    "fullName": "Bhavani Johnson",
    "role": "EMPLOYEE",
    "officeId": "c3a1b2d0-8f9e-4e2a-a1b2-c3d4e5f6a7b8",
    "isActive": true,
    "createdAt": "2026-01-01T00:00:00Z",
    "updatedAt": "2026-01-01T00:00:00Z"
  }
}
```

---

### 4.3 Assigned Office Configuration
`GET /api/v1/offices/assigned`
* **Access**: Authenticated (`EMPLOYEE`)
* **Headers**: `Authorization: Bearer <token>`
* **Description**: Returns employee's assigned office coordinates and radius for geofence map rendering in the Flutter mobile application.

#### Success Response (`200 OK`)
```json
{
  "success": true,
  "data": {
    "id": "c3a1b2d0-8f9e-4e2a-a1b2-c3d4e5f6a7b8",
    "name": "Munich HQ / Unterschleissheim",
    "latitude": 48.278900,
    "longitude": 11.573200,
    "radiusMeters": 10.0,
    "isActive": true,
    "createdAt": "2026-01-01T00:00:00Z",
    "updatedAt": "2026-01-01T00:00:00Z"
  }
}
```

---

### 4.4 Attendance Check-In
`POST /api/v1/attendance/check-in`
* **Access**: Authenticated (`EMPLOYEE`, Protected by Rate Limiter: 10 req/s)
* **Headers**: `Authorization: Bearer <token>`
* **Description**: Validates GPS coordinates and accuracy, calculates authoritative Haversine distance, verifies employee is inside the geofence, and opens an attendance session.

#### Request Body
```json
{
  "latitude": 48.278902,
  "longitude": 11.573204,
  "accuracyMeters": 7.4,
  "capturedAt": "2026-08-14T08:59:41Z"
}
```

#### Success Response (`200 OK` - BrandHRMS Guide Page 8)
```json
{
  "success": true,
  "attendanceId": "61a52b8e-3df5-4ef0-9bb3-7d52a201c130",
  "status": "CHECKED_IN",
  "distanceMeters": 6.8,
  "allowedRadiusMeters": 10.0,
  "serverTime": "2026-08-14T09:00:02Z"
}
```

#### Rejection Cases
* Outside radius: `HTTP 422` with `OUTSIDE_RADIUS`
* Low accuracy: `HTTP 422` with `LOCATION_INACCURATE`
* Already checked in: `HTTP 409` with `ALREADY_CHECKED_IN`
* Missing/Invalid GPS: `HTTP 400` with `LOCATION_REQUIRED`

---

### 4.5 Attendance Check-Out
`POST /api/v1/attendance/check-out`
* **Access**: Authenticated (`EMPLOYEE`, Protected by Rate Limiter: 10 req/s)
* **Headers**: `Authorization: Bearer <token>`
* **Description**: Validates GPS coordinates, closes the active session, calculates total working duration in seconds, and transitions session to `COMPLETED`.

#### Request Body
```json
{
  "latitude": 48.278901,
  "longitude": 11.573203,
  "accuracyMeters": 6.2,
  "capturedAt": "2026-08-14T17:00:01Z"
}
```

#### Success Response (`200 OK`)
```json
{
  "success": true,
  "attendanceId": "61a52b8e-3df5-4ef0-9bb3-7d52a201c130",
  "status": "COMPLETED",
  "distanceMeters": 5.4,
  "allowedRadiusMeters": 10.0,
  "durationSeconds": 28800,
  "serverTime": "2026-08-14T17:00:02Z"
}
```

#### Rejection Cases
* No open check-in: `HTTP 400` with `NOT_CHECKED_IN`
* Outside radius: `HTTP 422` with `OUTSIDE_RADIUS`
* Low accuracy: `HTTP 422` with `LOCATION_INACCURATE`

---

### 4.6 Employee Attendance History
`GET /api/v1/attendance/me?from=&to=&page=&pageSize=`
* **Access**: Authenticated (`EMPLOYEE`)
* **Headers**: `Authorization: Bearer <token>`
* **Query Parameters**:
  * `from` (optional): Filter sessions with `checkInTime >= from` (Format: `YYYY-MM-DD` or ISO 8601 UTC)
  * `to` (optional): Filter sessions with `checkInTime <= to` (Format: `YYYY-MM-DD` or ISO 8601 UTC)
  * `page` (optional, default `1`): Page number
  * `pageSize` (optional, default `10`, max `50`): Results per page

#### Success Response (`200 OK`)
```json
{
  "success": true,
  "data": {
    "total": 1,
    "page": 1,
    "pageSize": 10,
    "sessions": [
      {
        "id": "61a52b8e-3df5-4ef0-9bb3-7d52a201c130",
        "employeeId": "e4b5a320-1a7f-4a3e-b7d1-5a2e1d09e8a1",
        "officeId": "c3a1b2d0-8f9e-4e2a-a1b2-c3d4e5f6a7b8",
        "source": "GPS_MOBILE",
        "officeSnapshotName": "Munich HQ / Unterschleissheim",
        "officeSnapshotLat": 48.278900,
        "officeSnapshotLon": 11.573200,
        "officeSnapshotRadius": 10.0,
        "checkInTime": "2026-08-14T09:00:02Z",
        "checkInLatitude": 48.278902,
        "checkInLongitude": 11.573204,
        "checkInAccuracyMeters": 7.4,
        "checkInCapturedAt": "2026-08-14T08:59:41Z",
        "checkInDistanceMeters": 6.8,
        "checkOutTime": "2026-08-14T17:00:02Z",
        "checkOutLatitude": 48.278901,
        "checkOutLongitude": 11.573203,
        "checkOutAccuracyMeters": 6.2,
        "checkOutCapturedAt": "2026-08-14T17:00:01Z",
        "checkOutDistanceMeters": 5.4,
        "durationSeconds": 28800,
        "status": "COMPLETED",
        "createdAt": "2026-08-14T09:00:02Z",
        "updatedAt": "2026-08-14T17:00:02Z"
      }
    ]
  }
}
```

---

### 4.7 Service Health Check
`GET /health`
* **Access**: Public
* **Description**: Infrastructure and load balancer liveness probe.

#### Success Response (`200 OK`)
```json
{
  "status": "UP",
  "service": "location-attendance",
  "version": "1.0.0",
  "timestamp": "2026-09-24T03:00:00Z"
}
```

---

## 5. Database Interaction & Migration Contract (For PostgreSQL Developer)

1. **Schema Authority**: Single unified table `attendance_sessions` with source field `source VARCHAR(20) DEFAULT 'GPS_MOBILE'`.
2. **Backward Compatibility**: Nullable GPS telemetry columns (`check_in_latitude`, `check_in_longitude`, etc.) ensuring legacy `BIOMETRIC` and `WEB` attendance rows remain fully valid without fabricated data.
3. **Race Condition Prevention**: Enforce single active session invariant per employee using a partial unique index:
   ```sql
   CREATE UNIQUE INDEX idx_attendance_one_active_per_employee 
   ON attendance_sessions (employee_id) 
   WHERE status = 'CHECKED_IN';
   ```
4. **Decision Immutability**: Store `office_snapshot_name`, `office_snapshot_lat`, `office_snapshot_lon`, and `office_snapshot_radius` in each attendance record so historical attendance remains valid even if an office location or radius is subsequently changed by an administrator.
