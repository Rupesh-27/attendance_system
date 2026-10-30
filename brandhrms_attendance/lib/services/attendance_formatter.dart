import 'package:flutter/material.dart';
import 'geocoding_service.dart';

/// Centralized formatting and display logic for the Attendance Module
/// according to the BrandPOS Unit Test Specification (v1.0.0).
class AttendanceFormatter {
  /// UT-001 to UT-008: Monthly Efforts – Duration Formatting
  /// Formats minutes into 'Xd Xh Xm'. (1 day = 24 hours = 1,440 minutes).
  /// Handles null, negative, and >30 days values gracefully.
  static String formatMonthlyEfforts(int? minutes) {
    if (minutes == null) return '--';
    if (minutes < 0) return '0d 0h 0m'; // Handles negative values gracefully

    final days = minutes ~/ (24 * 60);
    final remainingMinutes = minutes % (24 * 60);
    final hours = remainingMinutes ~/ 60;
    final mins = remainingMinutes % 60;
    return '${days}d ${hours}h ${mins}m';
  }

  /// UT-019 to UT-027: Today's Login – Session Duration
  /// Formats seconds into 'Xh Xm Xs'.
  /// Displays cumulative hours past 24 hours without resetting.
  /// Handles null or invalid values gracefully.
  static String formatSessionDuration(int? seconds) {
    if (seconds == null || seconds < 0) return '0h 0m 0s';

    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours}h ${mins}m ${secs}s';
  }

  /// UT-009 to UT-018 & UT-041 to UT-042: Location Display Logic
  /// If location-based attendance is enabled: displays configured office name.
  /// If location-based attendance is disabled: displays City, District, State, Country.
  static String formatLocationDisplay({
    required bool locationAttendanceEnabled,
    String? officeName,
    String? rawAddress,
    String fallbackOffice = 'Office',
    String fallbackOffSite = 'Off-Site',
  }) {
    if (locationAttendanceEnabled) {
      if (officeName != null && officeName.trim().isNotEmpty) {
        return officeName.trim();
      }
      return fallbackOffice;
    } else {
      if (rawAddress != null && rawAddress.trim().isNotEmpty) {
        final formatted = GeocodingService.formatCityDistrictStateCountry(rawAddress);
        if (formatted.isNotEmpty) return formatted;
      }
      return fallbackOffSite;
    }
  }

  /// UT-028 to UT-034: Attendance Calendar Status Badges
  /// Returns 'P' for Present, 'A' for Absent.
  /// Suppresses any 'GEN' label (UT-028).
  /// Preserves Holiday ('H'), Leave ('L'), Weekend ('W').
  static String getCalendarStatusBadge(String? status) {
    if (status == null || status.isEmpty) return '—';
    final s = status.toUpperCase().trim();
    if (s == 'GEN' || s == 'GENERAL') return ''; // UT-028: GEN label is not displayed
    if (s == 'PRESENT') return 'P';              // UT-029: Present is P
    if (s == 'SHORTFALL') return 'SF';
    if (s == 'ABSENT') return 'A';               // UT-030: Absent is A
    if (s == 'HOLIDAY') return 'H';              // UT-033
    if (s == 'LEAVE') return 'L';                // UT-033
    if (s == 'WEEK_OFF' || s == 'WEEKEND') return 'W'; // UT-033
    return '•';                                  // UT-034: Safe fallback, not P or A
  }

  /// UT-031 to UT-032: Attendance Calendar Status Colors
  /// Present uses green. Absent must NOT use green.
  static Color getCalendarStatusColor(String? status) {
    if (status == null) return const Color(0xFF94A3B8);
    final s = status.toUpperCase().trim();
    if (s == 'PRESENT') {
      return const Color(0xFF16A34A); // UT-031: Configured green
    }
    if (s == 'SHORTFALL') {
      return const Color(0xFFD97706); // Amber / Orange for Shortfall
    }
    if (s == 'ABSENT') {
      return const Color(0xFFEF4444); // UT-032: Red/coral, never green
    }
    if (s == 'HOLIDAY') {
      return const Color(0xFF6366F1); // Indigo
    }
    if (s == 'LEAVE') {
      return const Color(0xFFF59E0B); // Amber
    }
    if (s == 'WEEK_OFF' || s == 'WEEKEND') {
      return const Color(0xFF64748B); // Slate
    }
    return const Color(0xFF94A3B8); // Safe fallback
  }
}
