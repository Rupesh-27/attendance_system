import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const Color primaryColor = Color(0xFF0F9D8A);

  bool _isLoading = true;
  List<AttendanceRecord> _records = [];

  late DateTime _currentMonth;

  late DateTime _selectedDay;

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
        'label': 'Present',
        'color': const Color(0xFF1E88E5),
        'bgColor': const Color(0xFFEBF5FB),
        'borderColor': const Color(0xFF64B5F6),
        'icon': Icons.business,
        'sessions': sessions,
        'holidayName': holidayName,
      };
    }

    if (holidayName != null) {
      return {
        'status': 'HOLIDAY',
        'label': 'Holiday',
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
        'label': 'Week Off',
        'color': const Color(0xFF455A64),
        'bgColor': const Color(0xFFF1F5F9),
        'borderColor': const Color(0xFFCFD8DC),
        'icon': Icons.local_cafe_outlined,
        'sessions': <AttendanceRecord>[],
      };
    }

    if (targetDate.isBefore(today)) {
      return {
        'status': 'ABSENT',
        'label': 'Absent',
        'color': const Color(0xFFE53935),
        'bgColor': const Color(0xFFFEECEB),
        'borderColor': const Color(0xFFFFCDD2),
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
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDateFull(DateTime dt) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$formattedHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _fetchHistory,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
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
              const Expanded(
                child: Text(
                  'Attendance Calendar',
                  style: TextStyle(
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
                    tooltip: 'Previous Month',
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
                    tooltip: 'Next Month',
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
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
                Text(
                  'GEN',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
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
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )
            else
              const SizedBox(height: 8),
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

    String firstCheckIn = 'Not marked';
    String lastCheckOut = 'Not marked';
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
        lastCheckOut = 'Active Now';
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
                              ? '$holidayName (Government Holiday)'
                              : (status == 'WEEK_OFF'
                                  ? 'Scheduled Week Off'
                                  : 'General Shift (10:00 AM - 7:00 PM)')),
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
              if (daySessions.isNotEmpty)
                InkWell(
                  onTap: () => _showSwipesBreakdownModal(
                    date: _selectedDay,
                    officeName: officeName,
                    sessions: daySessions,
                    totalWorkFormatted: totalDurationSec > 0
                        ? '${hours}hr ${mins}mins'
                        : '0hr 0mins',
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
                      children: const [
                        Icon(Icons.visibility_outlined,
                            size: 16, color: Color(0xFF0284C7)),
                        SizedBox(width: 4),
                        Text(
                          'View',
                          style: TextStyle(
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
                  title: 'Check-in',
                  timeValue: firstCheckIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeMetric(
                  icon: Icons.logout,
                  iconColor: Colors.orange,
                  title: 'Check-out',
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
                  const Text(
                    'Total Work Time: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  Text(
                    '${hours}hr ${mins}mins',
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
                      const Text(
                        'Time Log',
                        style: TextStyle(
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
                          '${sessions.length} Log Session${sessions.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Text(
                          'Total: $totalWorkFormatted',
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

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Session #${sessions.length - index}',
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
                                      child: const Text(
                                        'Active Now',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    )
                                  else
                                    Text(
                                      session.durationSeconds != null
                                          ? 'Duration: ${session.durationSeconds! ~/ 60}m ${session.durationSeconds! % 60}s'
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
                                  const Text('Check-in: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                    _formatTime(session.checkInTime),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Text(
                                    session.officeSnapshotName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              if (session.checkOutTime != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.logout,
                                        size: 18, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const Text('Check-out: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    Text(
                                      _formatTime(session.checkOutTime!),
                                      style: const TextStyle(fontSize: 13),
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            timeValue,
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
        text = 'Present';
        color = const Color(0xFF15803D);
        bg = const Color(0xFFDCFCE7);
        break;
      case 'HOLIDAY':
        text = 'Holiday';
        color = const Color(0xFF4338CA);
        bg = const Color(0xFFEEF2FF);
        break;
      case 'WEEK_OFF':
        text = 'Week Off';
        color = const Color(0xFF475569);
        bg = const Color(0xFFF1F5F9);
        break;
      case 'ABSENT':
        text = 'Absent';
        color = const Color(0xFFDC2626);
        bg = const Color(0xFFFEE2E2);
        break;
      default:
        text = 'Upcoming';
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
    return Expanded(
      child: Center(
        child: Text(
          label,
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
