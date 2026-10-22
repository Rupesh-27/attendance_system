import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmployeeProfile {
  final String id;
  final String employeeCode;
  final String fullName;
  final String role;
  final String officeId;
  final String? email;
  final bool locationAttendanceEnabled;
  final bool isActive;

  EmployeeProfile({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.role,
    required this.officeId,
    this.email,
    this.locationAttendanceEnabled = true,
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
      locationAttendanceEnabled: json['locationAttendanceEnabled'] ?? true,
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
  final bool locationAttendanceEnabled;

  SystemSettings({
    required this.retryIntervalMinutes,
    required this.maxRetries,
    required this.telegramAlertsEnabled,
    required this.forceCheckoutEnabled,
    this.locationAttendanceEnabled = true,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      retryIntervalMinutes: (json['retryIntervalMinutes'] as num?)?.toInt() ?? 2,
      maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 1,
      telegramAlertsEnabled: json['telegramAlertsEnabled'] ?? true,
      forceCheckoutEnabled: json['forceCheckoutEnabled'] ?? true,
      locationAttendanceEnabled: json['locationAttendanceEnabled'] ?? true,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String employeeId;
  final String officeId;
  final String officeSnapshotName;
  final DateTime checkInTime;
  final double checkInLatitude;
  final double checkInLongitude;
  final double checkInAccuracyMeters;
  final double checkInDistanceMeters;
  final String? checkInAddress;
  final DateTime? checkOutTime;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final double? checkOutAccuracyMeters;
  final double? checkOutDistanceMeters;
  final String? checkOutAddress;
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
    this.checkInLatitude = 0.0,
    this.checkInLongitude = 0.0,
    this.checkInAccuracyMeters = 0.0,
    required this.checkInDistanceMeters,
    this.checkInAddress,
    this.checkOutTime,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutAccuracyMeters,
    this.checkOutDistanceMeters,
    this.checkOutAddress,
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
      checkInLatitude: (json['checkInLatitude'] as num?)?.toDouble() ?? 0.0,
      checkInLongitude: (json['checkInLongitude'] as num?)?.toDouble() ?? 0.0,
      checkInAccuracyMeters: (json['checkInAccuracyMeters'] as num?)?.toDouble() ?? 0.0,
      checkInDistanceMeters: (json['checkInDistanceMeters'] as num?)?.toDouble() ?? 0.0,
      checkInAddress: json['checkInAddress'],
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      checkOutLatitude: (json['checkOutLatitude'] as num?)?.toDouble(),
      checkOutLongitude: (json['checkOutLongitude'] as num?)?.toDouble(),
      checkOutAccuracyMeters: (json['checkOutAccuracyMeters'] as num?)?.toDouble(),
      checkOutDistanceMeters: (json['checkOutDistanceMeters'] as num?)?.toDouble(),
      checkOutAddress: json['checkOutAddress'],
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

  final bool isOnLeave;
  final LeaveApplication? approvedLeave;

  TodayStatusResult({
    required this.attendanceDay,
    required this.isCarriedOver,
    this.activeSession,
    required this.todaySessions,
    required this.totalWorkSeconds,
    this.isOnLeave = false,
    this.approvedLeave,
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
      isOnLeave: json['isOnLeave'] ?? false,
      approvedLeave: json['approvedLeave'] != null
          ? LeaveApplication.fromJson(json['approvedLeave'])
          : null,
    );
  }
}

class LeaveType {
  final String id;
  final String name;
  final String code;
  final String? description;
  final int annualAllowance;
  final bool isPaid;
  final bool isActive;

  LeaveType({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    required this.annualAllowance,
    required this.isPaid,
    required this.isActive,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'],
      annualAllowance: (json['annualAllowance'] as num?)?.toInt() ?? 0,
      isPaid: json['isPaid'] ?? true,
      isActive: json['isActive'] ?? true,
    );
  }
}

class EmployeeLeaveBalance {
  final String id;
  final String employeeId;
  final String leaveTypeId;
  final String leaveTypeName;
  final String leaveTypeCode;
  final int year;
  final double allocatedDays;
  final double usedDays;
  final double remainingDays;

  EmployeeLeaveBalance({
    required this.id,
    required this.employeeId,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.leaveTypeCode,
    required this.year,
    required this.allocatedDays,
    required this.usedDays,
    required this.remainingDays,
  });

  factory EmployeeLeaveBalance.fromJson(Map<String, dynamic> json) {
    return EmployeeLeaveBalance(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      leaveTypeId: json['leaveTypeId'] ?? '',
      leaveTypeName: json['leaveTypeName'] ?? '',
      leaveTypeCode: json['leaveTypeCode'] ?? '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      allocatedDays: (json['allocatedDays'] as num?)?.toDouble() ?? 0.0,
      usedDays: (json['usedDays'] as num?)?.toDouble() ?? 0.0,
      remainingDays: (json['remainingDays'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LeaveApplication {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String leaveTypeId;
  final String leaveTypeName;
  final String leaveTypeCode;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays;
  final bool isHalfDay;
  final String? halfDaySession;
  final String reason;
  final String status;
  final String? applyingTo;
  final String? cc;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final String? managerRemarks;
  final DateTime createdAt;

  LeaveApplication({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.leaveTypeCode,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.isHalfDay,
    this.halfDaySession,
    required this.reason,
    required this.status,
    this.applyingTo,
    this.cc,
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
    this.managerRemarks,
    required this.createdAt,
  });

  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    return LeaveApplication(
      id: json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      employeeName: json['employeeName'],
      employeeCode: json['employeeCode'],
      leaveTypeId: json['leaveTypeId'] ?? '',
      leaveTypeName: json['leaveTypeName'] ?? '',
      leaveTypeCode: json['leaveTypeCode'] ?? '',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      totalDays: (json['totalDays'] as num?)?.toDouble() ?? 1.0,
      isHalfDay: json['isHalfDay'] ?? false,
      halfDaySession: json['halfDaySession'],
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      applyingTo: json['applyingTo'],
      cc: json['cc'],
      reviewedBy: json['reviewedBy'],
      reviewedByName: json['reviewedByName'],
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt']) : null,
      managerRemarks: json['managerRemarks'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class ApiService {

  static String baseUrl = "https://attendancesystem-production-8ce5.up.railway.app/api/v1";

  static String? authToken;
  static EmployeeProfile? currentEmployee;
  static AssignedOffice? assignedOffice;
  static SystemSettings? systemSettings;

  static bool get isLocationAttendanceRequired {
    if (currentEmployee != null && !currentEmployee!.locationAttendanceEnabled) {
      return false;
    }
    if (systemSettings != null && !systemSettings!.locationAttendanceEnabled) {
      return false;
    }
    return true;
  }

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  static VoidCallback? onSessionTerminated;

  static void handleAuthError(http.Response response) {
    if (response.statusCode == 401) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map && (data['code'] == 'SESSION_TERMINATED' || data['code'] == 'AUTH_INVALID')) {
          authToken = null;
          currentEmployee = null;
          assignedOffice = null;
          onSessionTerminated?.call();
        }
      } catch (_) {}
    }
  }

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
      handleAuthError(response);

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
      handleAuthError(response);

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
    String? address,
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
          if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
        }),
      );
      handleAuthError(response);

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
    String? address,
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
          if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
        }),
      );
      handleAuthError(response);

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
    String? address,
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
          if (address != null && address.trim().isNotEmpty) 'address': address.trim(),
        }),
      );
      handleAuthError(response);

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
      } else if (data['code'] == 'NO_ACTIVE_SESSION') {
        // Session already auto-checked out by backend background worker
        return {
          'success': true,
          'alreadyCheckedOut': true,
          'checkoutReason': 'FORCE_CHECKOUT_OUT_OF_RADIUS',
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
      handleAuthError(response);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> clearBreachWarning() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/clear-breach'),
        headers: _authHeaders,
      );
      handleAuthError(response);
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
      handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          systemSettings = SystemSettings.fromJson(data['data']);
          return systemSettings;
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
      handleAuthError(response);

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
      handleAuthError(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return TodayStatusResult.fromJson(data['data']);
        }
      }
    } catch (_) {}
    return null;
  }

  // Leave Management APIs
  static Future<List<LeaveType>> getLeaveTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leave/types'),
        headers: _authHeaders,
      );
      handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((item) => LeaveType.fromJson(item)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<EmployeeLeaveBalance>> getLeaveBalances({int? year}) async {
    try {
      String endpoint = '$baseUrl/leave/balances';
      if (year != null) {
        endpoint += '?year=$year';
      }
      final response = await http.get(
        Uri.parse(endpoint),
        headers: _authHeaders,
      );
      handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((item) => EmployeeLeaveBalance.fromJson(item)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> applyLeave({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    required bool isHalfDay,
    String? halfDaySession,
    required String reason,
    String? applyingTo,
    String? cc,
    String? attachmentUrl,
  }) async {
    try {
      final payload = <String, dynamic>{
        'leaveTypeId': leaveTypeId,
        'startDate': startDate,
        'endDate': endDate,
        'isHalfDay': isHalfDay,
        'reason': reason,
      };
      if (halfDaySession != null) {
        payload['halfDaySession'] = halfDaySession;
      }
      if (applyingTo != null && applyingTo.isNotEmpty) {
        payload['applyingTo'] = applyingTo;
      }
      if (cc != null && cc.isNotEmpty) {
        payload['cc'] = cc;
      }
      if (attachmentUrl != null && attachmentUrl.isNotEmpty) {
        payload['attachmentUrl'] = attachmentUrl;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/leave/apply'),
        headers: _authHeaders,
        body: jsonEncode(payload),
      );
      handleAuthError(response);

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || (response.statusCode == 200 && data['success'] == true)) {
        return {'success': true, 'data': LeaveApplication.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to apply leave',
          'code': data['code'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<List<LeaveApplication>> getMyLeaveApplications({String? status}) async {
    try {
      String endpoint = '$baseUrl/leave/my-applications';
      if (status != null && status.isNotEmpty) {
        endpoint += '?status=$status';
      }
      final response = await http.get(
        Uri.parse(endpoint),
        headers: _authHeaders,
      );
      handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((item) => LeaveApplication.fromJson(item)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> cancelLeaveApplication(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leave/$id/cancel'),
        headers: _authHeaders,
      );
      handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  static Future<List<LeaveApplication>> getPendingLeaveApprovals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/leave/approvals'),
        headers: _authHeaders,
      );
      handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((item) => LeaveApplication.fromJson(item)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> approveLeaveApplication(String id, {String? remarks}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leave/$id/approve'),
        headers: _authHeaders,
        body: jsonEncode({'remarks': remarks}),
      );
      handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> rejectLeaveApplication(String id, {String? remarks}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leave/$id/reject'),
        headers: _authHeaders,
        body: jsonEncode({'remarks': remarks}),
      );
      handleAuthError(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> logout() async {
    try {
      if (authToken != null) {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: _authHeaders,
        );
      }
    } catch (_) {}
    authToken = null;
    currentEmployee = null;
    assignedOffice = null;
  }
}
