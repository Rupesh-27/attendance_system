import 'dart:convert';
import 'package:http/http.dart' as http;

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

class SystemSettings {
  final int retryIntervalMinutes;
  final int maxRetries;
  final bool telegramAlertsEnabled;
  final bool forceCheckoutEnabled;

  SystemSettings({
    required this.retryIntervalMinutes,
    required this.maxRetries,
    required this.telegramAlertsEnabled,
    required this.forceCheckoutEnabled,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      retryIntervalMinutes: (json['retryIntervalMinutes'] as num?)?.toInt() ?? 2,
      maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 1,
      telegramAlertsEnabled: json['telegramAlertsEnabled'] ?? true,
      forceCheckoutEnabled: json['forceCheckoutEnabled'] ?? true,
    );
  }
}

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
  final String? checkoutReason;
  final DateTime? initialOutOfRadiusAt;
  final String? attendanceDay;

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
    this.checkoutReason,
    this.initialOutOfRadiusAt,
    this.attendanceDay,
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
      checkoutReason: json['checkoutReason'],
      initialOutOfRadiusAt: json['initialOutOfRadiusAt'] != null
          ? DateTime.parse(json['initialOutOfRadiusAt'])
          : null,
      attendanceDay: json['attendanceDay'],
    );
  }
}

class TodayStatusResult {
  final String attendanceDay;
  final bool isCarriedOver;
  final AttendanceRecord? activeSession;
  final List<AttendanceRecord> todaySessions;
  final int totalWorkSeconds;

  TodayStatusResult({
    required this.attendanceDay,
    required this.isCarriedOver,
    this.activeSession,
    required this.todaySessions,
    required this.totalWorkSeconds,
  });

  factory TodayStatusResult.fromJson(Map<String, dynamic> json) {
    return TodayStatusResult(
      attendanceDay: json['attendanceDay'] ?? '',
      isCarriedOver: json['isCarriedOver'] ?? false,
      activeSession: json['activeSession'] != null
          ? AttendanceRecord.fromJson(json['activeSession'])
          : null,
      todaySessions: (json['todaySessions'] as List? ?? [])
          .map((s) => AttendanceRecord.fromJson(s))
          .toList(),
      totalWorkSeconds: (json['totalWorkSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class ApiService {

  static String baseUrl = "https://attendancesystem-production-8ce5.up.railway.app/api/v1";

  static String? authToken;
  static EmployeeProfile? currentEmployee;
  static AssignedOffice? assignedOffice;

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

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

  static Future<Map<String, dynamic>> forceCheckOut({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    DateTime? breachedAt,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/force-checkout'),
        headers: _authHeaders,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'accuracyMeters': accuracyMeters,
          'capturedAt': DateTime.now().toUtc().toIso8601String(),
          if (breachedAt != null) 'breachedAt': breachedAt.toUtc().toIso8601String(),
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'attendanceId': data['attendanceId'],
          'status': data['status'],
          'checkoutReason': data['checkoutReason'] ?? 'FORCE_CHECKOUT_OUT_OF_RADIUS',
          'distanceMeters': (data['distanceMeters'] as num?)?.toDouble() ?? 0.0,
          'allowedRadiusMeters': (data['allowedRadiusMeters'] as num?)?.toDouble() ?? 10.0,
          'durationSeconds': data['durationSeconds'] ?? 0,
          'serverTime': data['serverTime'],
        };
      } else {
        return {
          'success': false,
          'code': data['code'] ?? 'FORCE_CHECKOUT_FAILED',
          'message': data['message'] ?? 'Force check-out failed.',
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

  static Future<bool> recordBreachWarning({DateTime? breachedAt}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/breach-warning'),
        headers: _authHeaders,
        body: jsonEncode({
          'breachedAt': (breachedAt ?? DateTime.now()).toUtc().toIso8601String(),
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<SystemSettings?> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SystemSettings.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return null;
  }

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

  static Future<TodayStatusResult?> getTodayStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/today-status'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return TodayStatusResult.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  static void logout() {
    authToken = null;
    currentEmployee = null;
    assignedOffice = null;
  }
}
