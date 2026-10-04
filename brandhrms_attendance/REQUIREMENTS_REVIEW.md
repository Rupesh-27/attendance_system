# BrandHRMS Mobile Application – Requirements Review

## 1. Application Scope

The application is an employee-facing Flutter mobile application integrated with the existing Go backend.

The mobile application will support:
- Employee login
- Dashboard
- Location verification
- GPS-based check-in
- GPS-based check-out
- Attendance history
- Employee profile

The backend remains authoritative for attendance eligibility, official distance validation, attendance state transitions, and server time.

## 2. Required Screens

1. Splash Screen
2. Login Screen
3. Dashboard
4. Location Verification
5. Attendance History
6. Profile

## 3. Authentication

The application will:
- Accept employee ID/email and password.
- Integrate with the backend login API.
- Store the access token securely.
- Restore the authenticated session.
- Support logout and expired-session handling.
- Never store passwords.

## 4. Location Requirements

Location should be requested only when the employee explicitly attempts attendance.

The application will collect:
- Latitude
- Longitude
- Accuracy
- Capture time

The application will not implement background location tracking.

The backend is authoritative for the final attendance decision.

## 5. Attendance

The application will provide:
- Check-in
- Check-out
- Server-confirmed attendance status
- Duplicate-action handling
- Backend error handling

Client-calculated distance is only an estimate and is not authoritative.

## 6. Attendance History

Employees should be able to view their own attendance records and use date/date-range filters.

## 7. Profile

The profile should display:
- Name
- Employee ID
- Department
- Designation
- Email
- Phone

Profile information is read-only unless an approved update API exists.

## 8. Security and Privacy

The application must:
- Securely store authentication tokens.
- Never store passwords.
- Use HTTPS outside local development.
- Avoid logging tokens and precise coordinates.
- Avoid background location tracking.
- Clear the session after logout or expired authentication.

## 9. Error Handling

The application must handle:
- Location permission denied
- Permanently denied permission
- GPS disabled
- Poor location accuracy
- Location timeout/unavailable
- Network unavailable
- Authentication failure/expiry
- Authorization failure
- Duplicate attendance
- Backend rejection

## 10. Testing

Testing should cover:
- Login
- Session restoration
- Logout
- Location permissions
- GPS disabled
- Poor location accuracy
- Successful check-in/check-out
- Outside-radius attempt
- Duplicate attendance
- Network/server errors
- Different screen sizes
- Accessibility

## 11. Clarifications for Project Team

1. What is the development/staging Go backend base URL?
2. What test employee accounts are available?
3. Can the team provide the final API request/response examples?
4. What accuracy threshold should be used for LOCATION_INACCURATE?
5. What should happen when an employee has no assigned office?
6. Does the attendance history API require pagination?
7. Which Flutter state-management approach should be used?
8. What Android/iOS versions must be supported?
9. Are official BrandHRMS logo and design assets available?