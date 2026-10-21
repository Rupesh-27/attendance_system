import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/geocoding_service.dart';
import '../services/language_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      AttendanceHistoryScreenState();
}

class AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const Color primaryColor = Color(0xFF0F9D8A);

  bool _isLoading = true;
  List<AttendanceRecord> _records = [];

  late DateTime _currentMonth;

  late DateTime _selectedDay;

  void fetchHistory() {
    _fetchHistory();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);

    try {
      final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final daysInMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
      final endOfMonth =
          DateTime(_currentMonth.year, _currentMonth.month, daysInMonth);

      final from =
          '${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-01';
      final to =
          '${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}';

      final records = await ApiService.getHistory(from: from, to: to);

      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      final daysInNewMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
      final targetDay = _selectedDay.day.clamp(1, daysInNewMonth);
      _selectedDay =
          DateTime(_currentMonth.year, _currentMonth.month, targetDay);
    });
    _fetchHistory();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      final daysInNewMonth =
          DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
      final targetDay = _selectedDay.day.clamp(1, daysInNewMonth);
      _selectedDay =
          DateTime(_currentMonth.year, _currentMonth.month, targetDay);
    });
    _fetchHistory();
  }

  List<AttendanceRecord> _getRecordsForDay(DateTime day) {
    final dayStr =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _records.where((r) {
      if (r.attendanceDay != null && r.attendanceDay!.isNotEmpty) {
        return r.attendanceDay == dayStr;
      }
      final local = r.checkInTime.toLocal();
      return local.year == day.year &&
          local.month == day.month &&
          local.day == day.day;
    }).toList();
  }

  static const Map<String, String> _govtHolidays = {

    '2026-01-01': "New Year's Day",
    '2026-01-14': 'Pongal',
    '2026-01-15': 'Thiruvalluvar Day',
    '2026-01-16': 'Uzhavar Thirunal',
    '2026-01-26': 'Republic Day',
    '2026-03-20': 'Ramzan (Id-ul-Fitr)',
    '2026-04-03': 'Good Friday',
    '2026-04-14': 'Tamil New Year / Dr. B.R. Ambedkar Jayanti',
    '2026-05-01': 'May Day',
    '2026-05-27': 'Bakrid (Eid al-Adha)',
    '2026-06-26': 'Muharram',
    '2026-08-15': 'Independence Day',
    '2026-09-04': 'Milad-un-Nabi',
    '2026-09-14': 'Vinayakar Chathurthi',
    '2026-10-02': 'Gandhi Jayanti',
    '2026-10-19': 'Ayutha Pooja',
    '2026-10-20': 'Vijaya Dasami',
    '2026-11-08': 'Deepavali',
    '2026-12-25': 'Christmas',

    '2025-01-01': "New Year's Day",
    '2025-01-14': 'Pongal',
    '2025-01-15': 'Thiruvalluvar Day',
    '2025-01-16': 'Uzhavar Thirunal',
    '2025-01-26': 'Republic Day',
    '2025-03-31': 'Ramzan (Id-ul-Fitr)',
    '2025-04-14': 'Tamil New Year / Dr. Ambedkar Jayanti',
    '2025-04-18': 'Good Friday',
    '2025-05-01': 'May Day',
    '2025-06-07': 'Bakrid',
    '2025-08-15': 'Independence Day',
    '2025-08-27': 'Vinayakar Chathurthi',
    '2025-10-02': 'Gandhi Jayanti',
    '2025-10-20': 'Ayutha Pooja',
    '2025-10-21': 'Vijaya Dasami',
    '2025-11-01': 'Deepavali',
    '2025-12-25': 'Christmas',

    '2027-01-01': "New Year's Day",
    '2027-01-14': 'Pongal',
    '2027-01-15': 'Thiruvalluvar Day',
    '2027-01-26': 'Republic Day',
    '2027-04-14': 'Tamil New Year',
    '2027-05-01': 'May Day',
    '2027-08-15': 'Independence Day',
    '2027-10-02': 'Gandhi Jayanti',
    '2027-12-25': 'Christmas',
  };

  Map<String, dynamic> _getDayStatus(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final holidayName = _govtHolidays[dateKey];

    final sessions = _getRecordsForDay(date);
    if (sessions.isNotEmpty) {
      return {
        'status': 'PRESENT',
        'label': 'P',
        'color': const Color(0xFF16A34A),
        'bgColor': const Color(0xFFF0FDF4),
        'borderColor': const Color(0xFF86EFAC),
        'icon': Icons.business,
        'sessions': sessions,
        'holidayName': holidayName,
      };
    }

    if (holidayName != null) {
      return {
        'status': 'HOLIDAY',
        'label': 'H',
        'holidayName': holidayName,
        'color': const Color(0xFF4338CA),
        'bgColor': const Color(0xFFEEF2FF),
        'borderColor': const Color(0xFFC7D2FE),
        'icon': Icons.ac_unit,
        'sessions': <AttendanceRecord>[],
      };
    }

    final isWeekend = date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
    if (isWeekend) {
      return {
        'status': 'WEEK_OFF',
        'label': 'WO',
        'color': const Color(0xFF475569),
        'bgColor': const Color(0xFFF1F5F9),
        'borderColor': const Color(0xFFCFD8DC),
        'icon': Icons.local_cafe_outlined,
        'sessions': <AttendanceRecord>[],
      };
    }

    if (targetDate.isBefore(today)) {
      return {
        'status': 'ABSENT',
        'label': 'A',
        'color': const Color(0xFFDC2626),
        'bgColor': const Color(0xFFFEF2F2),
        'borderColor': const Color(0xFFFECACA),
        'icon': Icons.cancel_outlined,
        'sessions': <AttendanceRecord>[],
      };
    }

    return {
      'status': 'UPCOMING',
      'label': '',
      'color': Colors.grey,
      'bgColor': Colors.white,
      'borderColor': const Color(0xFFE2E8F0),
      'icon': null,
      'sessions': <AttendanceRecord>[],
    };
  }

  String _formatMonthYear(DateTime dt) {
    final monthName = tr('month_full_${dt.month}');
    return '$monthName ${dt.year}';
  }

  String _formatDateFull(DateTime dt) {
    final weekdayName = tr('weekday_full_${dt.weekday}');
    final monthName = tr('month_genitive_${dt.month}');
    final code = LanguageService.instance.currentCode;
    if (code == 'de') {
      return '$weekdayName, ${dt.day}. $monthName ${dt.year}';
    }
    return '$weekdayName, ${dt.day} $monthName ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$formattedHour:$minute $period';
  }

  String _formatDuration(int seconds) {
    if (seconds < 0) seconds = 0;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h}h ${m}m ${s}s';
  }

  String _formatSessionLocation(String? address, String officeSnapshotName) {
    if (ApiService.isLocationAttendanceRequired) {
      if (officeSnapshotName.isNotEmpty) {
        return officeSnapshotName;
      }
      return ApiService.assignedOffice?.name ?? tr('office');
    } else {
      if (address != null && address.trim().isNotEmpty) {
        return GeocodingService.formatCityDistrictStateCountry(address);
      }
      return tr('off_site');
    }
  }

  String _formatWorkHours(int hours, int mins) {
    if (hours > 0) {
      return '$hours ${tr('unit_hr')} $mins ${tr('unit_min')}';
    }
    return '$mins ${tr('unit_min')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          tr('attendance'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _fetchHistory,
            icon: const Icon(Icons.refresh),
            tooltip: tr('refresh'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildCalendarCard(),

              const SizedBox(height: 16),

              _buildDateDetailsCard(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  },
);
}

  Widget _buildCalendarCard() {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);

    final startingOffset = firstDayOfMonth.weekday % 7;
    final totalGridCells = startingOffset + daysInMonth;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Expanded(
                child: Text(
                  tr('attendance_calendar'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: _previousMonth,
                    tooltip: tr('previous_month'),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatMonthYear(_currentMonth),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    onPressed: _nextMonth,
                    tooltip: tr('next_month'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFECEFF1)),
          const SizedBox(height: 12),

          Row(
            children: const [
              _WeekdayHeader('SUN'),
              _WeekdayHeader('MON'),
              _WeekdayHeader('TUE'),
              _WeekdayHeader('WED'),
              _WeekdayHeader('THU'),
              _WeekdayHeader('FRI'),
              _WeekdayHeader('SAT'),
            ],
          ),

          const SizedBox(height: 10),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalGridCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 6,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {

                if (index < startingOffset) {
                  return const SizedBox.shrink();
                }

                final dayNumber = index - startingOffset + 1;
                final cellDate = DateTime(
                  _currentMonth.year,
                  _currentMonth.month,
                  dayNumber,
                );

                final isSelected = cellDate.year == _selectedDay.year &&
                    cellDate.month == _selectedDay.month &&
                    cellDate.day == _selectedDay.day;

                final now = DateTime.now();
                final isToday = cellDate.year == now.year &&
                    cellDate.month == now.month &&
                    cellDate.day == now.day;

                final dayStatus = _getDayStatus(cellDate);

                return _buildCalendarDayCell(
                  date: cellDate,
                  dayNumber: dayNumber,
                  statusInfo: dayStatus,
                  isSelected: isSelected,
                  isToday: isToday,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarDayCell({
    required DateTime date,
    required int dayNumber,
    required Map<String, dynamic> statusInfo,
    required bool isSelected,
    required bool isToday,
  }) {
    final label = statusInfo['label'] as String;
    final icon = statusInfo['icon'] as IconData?;
    final color = statusInfo['color'] as Color;
    final bgColor = statusInfo['bgColor'] as Color;
    final borderColor = statusInfo['borderColor'] as Color;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _selectedDay = date;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isToday ? primaryColor : borderColor),
            width: isSelected ? 2.0 : (isToday ? 1.5 : 0.8),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Align(
              alignment: Alignment.topLeft,
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF1D4ED8)
                      : (isToday ? primaryColor : const Color(0xFF1E293B)),
                ),
              ),
            ),

            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: color,
              )
            else
              const SizedBox(height: 16),

            if (label.isNotEmpty)
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )
            else
              const SizedBox(height: 11),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDetailsCard() {
    final statusInfo = _getDayStatus(_selectedDay);
    final List<AttendanceRecord> daySessions =
        statusInfo['sessions'] as List<AttendanceRecord>;
    final status = statusInfo['status'] as String;
    final holidayName = statusInfo['holidayName'] as String?;

    String firstCheckIn = tr('not_marked');
    String lastCheckOut = tr('not_marked');
    String officeName = '';
    int totalDurationSec = 0;

    if (daySessions.isNotEmpty) {

      final earliest = daySessions.last;
      firstCheckIn = _formatTime(earliest.checkInTime);
      officeName = earliest.officeSnapshotName;

      final latestCheckoutSession = daySessions.firstWhere(
        (s) => s.checkOutTime != null,
        orElse: () => earliest,
      );

      if (latestCheckoutSession.checkOutTime != null) {
        lastCheckOut = _formatTime(latestCheckoutSession.checkOutTime!);
      } else if (latestCheckoutSession.status == 'CHECKED_IN') {
        lastCheckOut = tr('active_now');
      }

      for (final s in daySessions) {
        if (s.durationSeconds != null && s.durationSeconds! > 0) {
          totalDurationSec += s.durationSeconds!;
        } else if (s.checkOutTime != null) {
          totalDurationSec +=
              s.checkOutTime!.difference(s.checkInTime).inSeconds;
        }
      }
    }

    final hours = totalDurationSec ~/ 3600;
    final mins = (totalDurationSec % 3600) ~/ 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDateFull(_selectedDay),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      officeName.isNotEmpty
                          ? officeName
                          : (holidayName != null
                              ? '$holidayName (${tr('govt_holiday')})'
                              : (status == 'WEEK_OFF'
                                  ? tr('scheduled_week_off')
                                  : tr('general_shift'))),
                      style: TextStyle(
                        fontSize: 12,
                        color: holidayName != null
                            ? const Color(0xFF4338CA)
                            : Colors.grey.shade600,
                        fontWeight: holidayName != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (daySessions.isNotEmpty)
                    InkWell(
                      onTap: () => _showSwipesBreakdownModal(
                        date: _selectedDay,
                        officeName: officeName,
                        sessions: daySessions,
                        totalWorkFormatted: totalDurationSec > 0
                            ? _formatDuration(totalDurationSec)
                            : '0 ${tr('unit_min')}',
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF7DD3FC)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility_outlined,
                                size: 16, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text(
                              tr('view'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildBadge(status),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _showMonthFilterPicker,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF334155)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFECEFF1)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTimeMetric(
                  icon: Icons.login,
                  iconColor: Colors.green,
                  title: tr('check_in'),
                  timeValue: firstCheckIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeMetric(
                  icon: Icons.logout,
                  iconColor: Colors.orange,
                  title: tr('check_out'),
                  timeValue: lastCheckOut,
                ),
              ),
            ],
          ),

          if (totalDurationSec > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 20, color: Color(0xFF475569)),
                  const SizedBox(width: 10),
                  Text(
                    '${tr('total_work_time')}: ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  Text(
                    _formatWorkHours(hours, mins),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSwipesBreakdownModal({
    required DateTime date,
    required String officeName,
    required List<AttendanceRecord> sessions,
    required String totalWorkFormatted,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.60,
          minChildSize: 0.35,
          maxChildSize: 0.88,
          builder: (context, scrollController) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('time_log'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDateFull(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (officeName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      officeName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${sessions.length} ${sessions.length > 1 ? tr('log_sessions') : tr('log_session')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Text(
                          '${tr('total')}: $totalWorkFormatted',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: sessions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 14),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isCurrent = session.status == 'CHECKED_IN' &&
                            session.checkOutTime == null;
                        final inLoc = _formatSessionLocation(
                          session.checkInAddress,
                          session.officeSnapshotName,
                        );
                        final outLoc = _formatSessionLocation(
                          session.checkOutAddress,
                          session.officeSnapshotName,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${tr('session')} #${sessions.length - index}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.green.shade300),
                                      ),
                                      child: Text(
                                        tr('active_now'),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      session.durationSeconds != null
                                          ? '${tr('duration')}: ${_formatDuration(session.durationSeconds!)}'
                                          : '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                               Row(
                                children: [
                                  const Icon(Icons.login,
                                      size: 18, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text('${tr('check_in')}: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                    _formatTime(session.checkInTime),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  if (ApiService.isLocationAttendanceRequired && session.officeSnapshotName.isNotEmpty) ...[
                                    const Spacer(),
                                    Text(
                                      session.officeSnapshotName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (session.checkOutTime != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.logout,
                                        size: 18, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text('${tr('check_out')}: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    Text(
                                      _formatTime(session.checkOutTime!),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    if (session.checkoutReason == 'FORCE_CHECKOUT_OUT_OF_RADIUS') ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Text(
                                          tr('out_of_radius'),
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              if (inLoc.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 16, color: primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${tr('check_in_location')}: ',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        inLoc,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (session.checkOutTime != null && outLoc.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 16, color: Colors.orange.shade700),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${tr('check_out_location')}: ',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        outLoc,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMonthFilterPicker() {
    int selectedYear = _currentMonth.year;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final now = DateTime.now();
            final months = [
              tr('month_1'), tr('month_2'), tr('month_3'), tr('month_4'),
              tr('month_5'), tr('month_6'), tr('month_7'), tr('month_8'),
              tr('month_9'), tr('month_10'), tr('month_11'), tr('month_12')
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('select_month'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr('view_full_records_desc'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 22),
                          onPressed: () {
                            setModalState(() => selectedYear--);
                          },
                        ),
                        Text(
                          '$selectedYear',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 22),
                          onPressed: () {
                            setModalState(() => selectedYear++);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthNum = index + 1;
                      final isSelected = selectedYear == _currentMonth.year &&
                          monthNum == _currentMonth.month;
                      final isCurrentActualMonth = selectedYear == now.year &&
                          monthNum == now.month;

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _loadAndShowMonthlyDetails(DateTime(selectedYear, monthNum, 1));
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : (isCurrentActualMonth
                                    ? const Color(0xFFE0F2FE)
                                    : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (isCurrentActualMonth
                                      ? const Color(0xFF7DD3FC)
                                      : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          child: Text(
                            months[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isCurrentActualMonth
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadAndShowMonthlyDetails(DateTime targetMonth) async {
    if (_currentMonth.year == targetMonth.year &&
        _currentMonth.month == targetMonth.month &&
        _records.isNotEmpty) {
      _showMonthlyAttendanceModal(targetMonth, _records);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
    );

    try {
      final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
      final daysInMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
      final endOfMonth = DateTime(targetMonth.year, targetMonth.month, daysInMonth);

      final from = '${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-01';
      final to = '${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}';

      final records = await ApiService.getHistory(from: from, to: to);

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _currentMonth = targetMonth;
          _records = records;
          final targetDay = _selectedDay.day.clamp(1, daysInMonth);
          _selectedDay = DateTime(targetMonth.year, targetMonth.month, targetDay);
        });
        _showMonthlyAttendanceModal(targetMonth, records);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load attendance records for selected month')),
        );
      }
    }
  }

  void _showMonthlyAttendanceModal(DateTime month, List<AttendanceRecord> records) {
    final Map<String, List<AttendanceRecord>> groupedByDay = {};
    int totalWorkSec = 0;

    for (final r in records) {
      final dateKey = (r.attendanceDay != null && r.attendanceDay!.isNotEmpty)
          ? r.attendanceDay!
          : '${r.checkInTime.toLocal().year}-${r.checkInTime.toLocal().month.toString().padLeft(2, '0')}-${r.checkInTime.toLocal().day.toString().padLeft(2, '0')}';
      groupedByDay.putIfAbsent(dateKey, () => []).add(r);

      if (r.durationSeconds != null && r.durationSeconds! > 0) {
        totalWorkSec += r.durationSeconds!;
      } else if (r.checkOutTime != null) {
        totalWorkSec += r.checkOutTime!.difference(r.checkInTime).inSeconds;
      }
    }

    final sortedDays = groupedByDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final totalHours = totalWorkSec ~/ 3600;
    final totalMins = (totalWorkSec % 3600) ~/ 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('monthly_attendance_log'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatMonthYear(month),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Summary metrics card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                tr('present_days'),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${groupedByDay.keys.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F9D8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 24, width: 1, color: const Color(0xFFCBD5E1)),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                tr('total_sessions'),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${records.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 24, width: 1, color: const Color(0xFFCBD5E1)),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                tr('total_work'),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                totalHours > 0 ? '$totalHours ${tr('unit_hr')} $totalMins ${tr('unit_min')}' : '0 ${tr('unit_min')}',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  Expanded(
                    child: records.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  '${tr('no_attendance_records')} ${_formatMonthYear(month)}',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: sortedDays.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, dayIdx) {
                              final dayKey = sortedDays[dayIdx];
                              final daySessions = groupedByDay[dayKey] ?? [];

                              int dayWorkSec = 0;
                              for (final s in daySessions) {
                                if (s.durationSeconds != null && s.durationSeconds! > 0) {
                                  dayWorkSec += s.durationSeconds!;
                                } else if (s.checkOutTime != null) {
                                  dayWorkSec += s.checkOutTime!.difference(s.checkInTime).inSeconds;
                                }
                              }
                              final dayH = dayWorkSec ~/ 3600;
                              final dayM = (dayWorkSec % 3600) ~/ 60;
                              final parsedDate = DateTime.tryParse(dayKey) ?? daySessions.first.checkInTime.toLocal();

                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Day header
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF0284C7)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _formatDateFull(parsedDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${daySessions.length} ${daySessions.length > 1 ? tr('log_sessions') : tr('log_session')}${dayWorkSec > 0 ? ' • ${_formatWorkHours(dayH, dayM)}' : ''}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                    const SizedBox(height: 8),

                                    // Sessions list for this day
                                    ...daySessions.asMap().entries.map((entry) {
                                      final sIndex = entry.key;
                                      final session = entry.value;
                                      final isCurrent = session.status == 'CHECKED_IN' && session.checkOutTime == null;
                                      final inLoc = _formatSessionLocation(
                                        session.checkInAddress,
                                        session.officeSnapshotName,
                                      );
                                      final outLoc = _formatSessionLocation(
                                        session.checkOutAddress,
                                        session.officeSnapshotName,
                                      );

                                      return Container(
                                        margin: EdgeInsets.only(top: sIndex > 0 ? 10 : 0),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFFECEFF1)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${tr('session')} #${daySessions.length - sIndex}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                const Spacer(),
                                                if (isCurrent)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade50,
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: Colors.green.shade300),
                                                    ),
                                                    child: Text(
                                                      tr('active_now'),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  )
                                                else if (session.checkoutReason == 'FORCE_CHECKOUT_OUT_OF_RADIUS')
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.shade50,
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: Colors.red.shade200),
                                                    ),
                                                    child: Text(
                                                      tr('out_of_radius'),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  )
                                                else if (session.durationSeconds != null)
                                                  Text(
                                                    _formatDuration(session.durationSeconds!),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade600,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            // Check-in time & address
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.login, size: 15, color: Colors.green),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${tr('check_in')}: ',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                                Text(
                                                  _formatTime(session.checkInTime),
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            if (inLoc.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 21),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(Icons.location_on_outlined, size: 14, color: primaryColor),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        inLoc,
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          color: Colors.grey.shade800,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            // Check-out time & address
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(Icons.logout, size: 15, color: Colors.orange),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${tr('check_out')}: ',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                ),
                                                Text(
                                                  session.checkOutTime != null
                                                      ? _formatTime(session.checkOutTime!)
                                                      : tr('active_not_checked_out'),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: session.checkOutTime != null ? Colors.black87 : Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (session.checkOutTime != null && outLoc.isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 21),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(Icons.location_on_outlined, size: 14, color: Colors.orange.shade700),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        outLoc,
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          color: Colors.grey.shade800,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeMetric({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String timeValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            timeValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String status) {
    String text;
    Color color;
    Color bg;

    switch (status) {
      case 'PRESENT':
        text = tr('present');
        color = const Color(0xFF15803D);
        bg = const Color(0xFFDCFCE7);
        break;
      case 'HOLIDAY':
        text = tr('holiday');
        color = const Color(0xFF4338CA);
        bg = const Color(0xFFEEF2FF);
        break;
      case 'WEEK_OFF':
        text = tr('week_off');
        color = const Color(0xFF475569);
        bg = const Color(0xFFF1F5F9);
        break;
      case 'ABSENT':
        text = tr('absent');
        color = const Color(0xFFDC2626);
        bg = const Color(0xFFFEE2E2);
        break;
      default:
        text = tr('upcoming');
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF8FAFC);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final isWeekend = label == 'SUN' || label == 'SAT';
    final translatedLabel = tr(label);
    return Expanded(
      child: Center(
        child: Text(
          translatedLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isWeekend
                ? const Color(0xFF64748B)
                : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
