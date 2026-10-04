import 'dart:convert';
import 'package:http/http.dart' as http;

/// Data model representing an authenticated employee
class EmployeeProfile {
  final String id;
  final String employeeCode;
  final String fullName;
  final String role;
  final String officeId;
  final String? email;
  final bool isActive;

  EmployeeProfile({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.role,
    required this.officeId,
    this.email,
    required this.isActive,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      id: json['id'] ?? '',
      employeeCode: json['employeeCode'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'EMPLOYEE',
      officeId: json['officeId'] ?? '',
      email: json['email'],
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Data model representing an assigned office and its geofence
class AssignedOffice {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;

  AssignedOffice({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
  });

  factory AssignedOffice.fromJson(Map<String, dynamic> json) {
    return AssignedOffice(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 10.0,
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Data model representing an attendance record from the database
class AttendanceRecord {
  final String id;
  final String employeeId;
  final String officeId;
  final String officeSnapshotName;
  final DateTime checkInTime;
  final double checkInDistanceMeters;
  final DateTime? checkOutTime;
  final double? checkOutDistanceMeters;
  final int? durationSeconds;
  final String status;

  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.officeId,
    required this.officeSnapshotName,
    required this.checkInTime,
    required this.checkInDistanceMeters,
    this.checkOutTime,
    this.checkOutDistanceMeters,
    this.durationSeconds,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      officeId: json['officeId'] ?? '',
      officeSnapshotName: json['officeSnapshotName'] ?? '',
      checkInTime: DateTime.parse(json['checkInTime']),
      checkInDistanceMeters: (json['checkInDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      checkOutDistanceMeters: (json['checkOutDistanceMeters'] as num?)?.toDouble(),
      durationSeconds: json['durationSeconds'] as int?,
      status: json['status'] ?? 'CHECKED_IN',
    );
  }
}

/// Centralized API service for communicating with the Go backend
class ApiService {
  // Configurable base URL:
  // - Physical Device on Wi-Fi: "http://192.168.31.91:8080/api/v1"
  // - Android Emulator: "http://10.0.2.2:8080/api/v1"
  // - Localhost / Web / Desktop: "http://localhost:8080/api/v1"
  // static String baseUrl = "http://192.168.31.91:8080/api/v1";

  static String baseUrl = "https://attendancesystem-production-8ce5.up.railway.app/api/v1";



  // In-memory active session state
  static String? authToken;
  static EmployeeProfile? currentEmployee;
  static AssignedOffice? assignedOffice;

  // Helper for auth headers
  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  /// 1. Employee Login: supports either employeeCode OR email
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeCode': identifier.trim(),
          'password': password.trim(),
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        authToken = data['data']['accessToken'];
        if (data['data']['employee'] != null) {
          currentEmployee = EmployeeProfile.fromJson(data['data']['employee']);
        }
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'code': data['code'] ?? 'AUTH_INVALID',
          'message': data['message'] ?? 'Login failed. Please check your credentials.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'code': 'NETWORK_ERROR',
        'message': 'Cannot reach the backend server. Please verify network connection.',
      };
    }
  }

  /// 2. Fetch User Profile
  static Future<EmployeeProfile?> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          currentEmployee = EmployeeProfile.fromJson(data['data']);
          return currentEmployee;
        }
      }
    } catch (_) {}
    return null;
  }

  /// 3. Fetch Assigned Office and Geofence Radius
  static Future<AssignedOffice?> getAssignedOffice() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/offices/assigned'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          assignedOffice = AssignedOffice.fromJson(data['data']);
          return assignedOffice;
        }
      }
    } catch (_) {}
    return null;
  }

  /// 4. Submit Check-In with Live GPS Telemetry
  static Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-in'),
        headers: _authHeaders,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'accuracyMeters': accuracyMeters,
          'capturedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'attendanceId': data['attendanceId'],
          'status': data['status'],
          'distanceMeters': (data['distanceMeters'] as num?)?.toDouble() ?? 0.0,
          'allowedRadiusMeters': (data['allowedRadiusMeters'] as num?)?.toDouble() ?? 10.0,
          'serverTime': data['serverTime'],
        };
      } else {
        return {
          'success': false,
          'code': data['code'] ?? 'CHECK_IN_FAILED',
          'message': data['message'] ?? 'Check-in validation failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'code': 'NETWORK_ERROR',
        'message': 'Failed to connect to attendance server. Please retry.',
      };
    }
  }

  /// 5. Submit Check-Out with Live GPS Telemetry
  static Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-out'),
        headers: _authHeaders,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'accuracyMeters': accuracyMeters,
          'capturedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'attendanceId': data['attendanceId'],
          'status': data['status'],
          'distanceMeters': (data['distanceMeters'] as num?)?.toDouble() ?? 0.0,
          'allowedRadiusMeters': (data['allowedRadiusMeters'] as num?)?.toDouble() ?? 10.0,
          'durationSeconds': data['durationSeconds'] ?? 0,
          'serverTime': data['serverTime'],
        };
      } else {
        return {
          'success': false,
          'code': data['code'] ?? 'CHECK_OUT_FAILED',
          'message': data['message'] ?? 'Check-out validation failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'code': 'NETWORK_ERROR',
        'message': 'Failed to connect to attendance server. Please retry.',
      };
    }
  }

  /// 6. Fetch Employee Attendance History
  static Future<List<AttendanceRecord>> getHistory({String? from, String? to}) async {
    try {
      String endpoint = '$baseUrl/attendance/me';
      List<String> queryParams = ['pageSize=50'];
      if (from != null && from.isNotEmpty) queryParams.add('from=$from');
      if (to != null && to.isNotEmpty) queryParams.add('to=$to');
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['sessions'] != null) {
          final List rawSessions = data['data']['sessions'];
          return rawSessions.map((s) => AttendanceRecord.fromJson(s)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// 7. Logout and Clear Session
  static void logout() {
    authToken = null;
    currentEmployee = null;
    assignedOffice = null;
  }
}
