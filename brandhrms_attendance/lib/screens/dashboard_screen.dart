import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';
import '../services/location_monitor_service.dart';
import 'attendance_history_screen.dart';
import 'profile_screen.dart';

class TechQuote {
  final String text;
  final String author;

  const TechQuote({required this.text, required this.author});
}

class InAppNotificationItem {
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  InAppNotificationItem({
    required this.title,
    required this.message,
    required this.timestamp,
    this.icon = Icons.notifications,
    this.color = const Color(0xFFDC2626),
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const List<TechQuote> techQuotes = [
    TechQuote(
      text: 'Any sufficiently advanced technology is indistinguishable from magic.',
      author: 'Arthur C. Clarke',
    ),
    TechQuote(
      text: 'Part of the inhumanity of the computer is that, once it is competently programmed, it is completely honest.',
      author: 'Isaac Asimov',
    ),
    TechQuote(
      text: 'The sky above the port was the color of television, tuned to a dead channel.',
      author: 'William Gibson',
    ),
    TechQuote(
      text: 'Once men turned their thinking over to machines in the hope that this would set them free.',
      author: 'Frank Herbert',
    ),
    TechQuote(
      text: 'We are stuck with technology when what we really want is just stuff that works.',
      author: 'Douglas Adams',
    ),
    TechQuote(
      text: 'The computer communicates with him into a computer-generated universe.',
      author: 'Neal Stephenson',
    ),
    TechQuote(
      text: 'Never let your sense of morals prevent you from doing what is right.',
      author: 'Isaac Asimov',
    ),
    TechQuote(
      text: 'A common mistake people make designing something foolproof is underestimating the ingenuity of fools.',
      author: 'Douglas Adams',
    ),
    TechQuote(
      text: 'The real problem is not whether machines think, but whether men do.',
      author: 'B. F. Skinner',
    ),
    TechQuote(
      text: 'The future is already here — it\'s just not evenly distributed.',
      author: 'William Gibson',
    ),
    TechQuote(
      text: 'Technology is a useful servant but a dangerous master.',
      author: 'Christian Lous Lange',
    ),
    TechQuote(
      text: 'How dangerous is the acquirement of knowledge, and how much happier is he who aspires within bounds.',
      author: 'Mary Shelley',
    ),
    TechQuote(
      text: 'Technological power is always the result of hardware, someone else\'s work, easily bought.',
      author: 'Michael Crichton',
    ),
    TechQuote(
      text: 'Machines who think? They\'re almost as terrifying as men who don\'t.',
      author: 'Isaac Asimov',
    ),
    TechQuote(
      text: 'We need not to be let alone. We need to be really bothered once in a while about something real.',
      author: 'Ray Bradbury',
    ),
  ];

  static TechQuote? currentQuote;

  static void pickNewQuote() {
    final random = math.Random();
    int newIndex;
    do {
      newIndex = random.nextInt(techQuotes.length);
    } while (techQuotes.length > 1 && techQuotes[newIndex] == currentQuote);
    currentQuote = techQuotes[newIndex];
  }

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color primaryColor = Color(0xFF0F9D8A);

  final List<InAppNotificationItem> _notifications = [];
  int _unreadNotifications = 0;

  bool _isLoading = true;
  bool _isCheckedIn = false;
  bool _isSubmittingAttendance = false;
  bool _isTodayLogExpanded = false;

  String _locationStatus = 'Not Checked In';
  String _locationStatusBadge = 'Pending';
  String _locationStatusSubtext = 'Location will be validated upon Check-in';
  Color _locationStatusColor = const Color(0xFF64748B);
  Color _locationStatusBg = const Color(0xFFF1F5F9);
  Color _locationStatusBorder = const Color(0xFFCBD5E1);
  IconData _locationStatusIcon = Icons.location_on_outlined;

  Timer? _liveTimer;
  String _currentTimeString = '00:00:00';

  int _accumulatedSeconds = 0;
  int _totalWorkSeconds = 0;
  DateTime? _currentSessionCheckIn;

  int _monthlyWorkSeconds = 0;
  int _monthlyAccumulatedSeconds = 0;
  int _totalBreakSeconds = 0;
  int _completedBreakSeconds = 0;
  DateTime? _lastCheckOutTime;

  List<AttendanceRecord> _todaySessions = [];
  bool _isCarriedOver = false;
  String _attendanceDay = '';

  @override
  void initState() {
    super.initState();
    LocationMonitorService.instance.addListener(_onLocationMonitorChanged);
    if (DashboardScreen.currentQuote == null) {
      DashboardScreen.pickNewQuote();
    }
    _currentTimeString = _getRealTimeClock();
    _startLiveTimer();
    _loadDashboardData();
  }

  @override
  void dispose() {
    LocationMonitorService.instance.removeListener(_onLocationMonitorChanged);
    _liveTimer?.cancel();
    super.dispose();
  }

  void _onLocationMonitorChanged() {
    if (!mounted) return;
    _syncLocationStatusWithSession();
  }

  void _showNotificationsTray() {
    setState(() {
      _unreadNotifications = 0;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active, color: primaryColor, size: 22),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Notifications',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (_notifications.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _notifications.clear();
                              });
                              setSheetState(() {});
                              Navigator.pop(ctx);
                            },
                            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_notifications.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No new notifications',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _notifications.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _notifications[index];
                            final timeStr = _formatTime(item.timestamp);
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              leading: CircleAvatar(
                                backgroundColor: item.color.withValues(alpha: 0.12),
                                child: Icon(item.icon, color: item.color, size: 20),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3),
                                  Text(item.message, style: const TextStyle(fontSize: 12.5)),
                                  const SizedBox(height: 4),
                                  Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showForceCheckoutDialog() {
    if (!mounted) return;

    final notice = InAppNotificationItem(
      title: 'Automatic Check-Out',
      message: 'You were automatically checked out because your GPS remained outside the office boundary for over 2 minutes.',
      timestamp: DateTime.now(),
      icon: Icons.exit_to_app_rounded,
      color: const Color(0xFFDC2626),
    );

    setState(() {
      _notifications.insert(0, notice);
      _unreadNotifications++;
      _isCheckedIn = false;
      _currentSessionCheckIn = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        margin: const EdgeInsets.only(top: 10, left: 16, right: 16, bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: Colors.amberAccent, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automatic Check-Out Notice',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Outside office radius > 2 mins. Tap bell icon for details.',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Automatic Check-Out',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your current GPS location is outside the configured office radius. Therefore, the system has automatically checked you out. Please retry check-in once you are within the office radius. For further assistance, please contact HR or your reporting in-charge.',
          style: TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF334155)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _loadDashboardData();
            },
            child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _getRealTimeClock() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {

          _currentTimeString = _getRealTimeClock();

          if (_isCheckedIn && _currentSessionCheckIn != null) {
            final currentElapsed =
                DateTime.now().difference(_currentSessionCheckIn!).inSeconds;
            final activeSec = currentElapsed > 0 ? currentElapsed : 0;
            _totalWorkSeconds = _accumulatedSeconds + activeSec;
            _monthlyWorkSeconds = _monthlyAccumulatedSeconds + activeSec;
          } else if (!_isCheckedIn && _lastCheckOutTime != null) {
            final ongoingBreak =
                DateTime.now().difference(_lastCheckOutTime!).inSeconds;
            _totalBreakSeconds =
                _completedBreakSeconds + (ongoingBreak > 0 ? ongoingBreak : 0);
          }
        });
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {

      await Future.wait([
        ApiService.getProfile(),
        ApiService.getAssignedOffice(),
      ]);

      final results = await Future.wait([
        ApiService.getTodayStatus(),
        ApiService.getHistory(),
      ]);

      final todayStatus = results[0] as TodayStatusResult?;
      final history = (results[1] as List<AttendanceRecord>?) ?? [];

      final now = DateTime.now();
      List<AttendanceRecord> todaySessions = [];
      int accumulatedSec = 0;
      AttendanceRecord? activeSession;
      bool isCarriedOver = false;
      String attendanceDay = '';

      int monthlyAccumulated = 0;

      if (todayStatus != null) {

        todaySessions = todayStatus.todaySessions;
        activeSession = todayStatus.activeSession;
        isCarriedOver = todayStatus.isCarriedOver;
        attendanceDay = todayStatus.attendanceDay;

        for (final r in todaySessions) {
          if (r.checkOutTime != null) {
            if (r.durationSeconds != null && r.durationSeconds! > 0) {
              accumulatedSec += r.durationSeconds!;
            } else {
              accumulatedSec +=
                  r.checkOutTime!.difference(r.checkInTime).inSeconds;
            }
          }
        }
      } else {

        for (final r in history) {
          final d = r.checkInTime.toLocal();
          if (d.year == now.year && d.month == now.month && d.day == now.day) {
            todaySessions.add(r);

            if ((r.status == 'CHECKED_IN' || r.status == 'CARRIED_OVER') &&
                r.checkOutTime == null) {
              activeSession = r;
            } else if (r.status == 'CHECKED_OUT' || r.checkOutTime != null) {
              if (r.durationSeconds != null && r.durationSeconds! > 0) {
                accumulatedSec += r.durationSeconds!;
              } else if (r.checkOutTime != null) {
                accumulatedSec +=
                    r.checkOutTime!.difference(r.checkInTime).inSeconds;
              }
            }
          }
        }
      }

      for (final r in history) {
        final d = r.checkInTime.toLocal();
        if (d.year == now.year && d.month == now.month) {
          if (r.durationSeconds != null && r.durationSeconds! > 0) {
            monthlyAccumulated += r.durationSeconds!;
          } else if (r.checkOutTime != null) {
            monthlyAccumulated +=
                r.checkOutTime!.difference(r.checkInTime).inSeconds;
          }
        }
      }

      final sortedToday = List<AttendanceRecord>.from(todaySessions)
        ..sort((a, b) => a.checkInTime.compareTo(b.checkInTime));

      int completedBreak = 0;
      DateTime? latestCheckOut;

      for (int i = 0; i < sortedToday.length - 1; i++) {
        final currentOut = sortedToday[i].checkOutTime;
        final nextIn = sortedToday[i + 1].checkInTime;
        if (currentOut != null) {
          final gap = nextIn.difference(currentOut).inSeconds;
          if (gap > 0) {
            completedBreak += gap;
          }
        }
      }

      if (sortedToday.isNotEmpty && sortedToday.last.checkOutTime != null) {
        latestCheckOut = sortedToday.last.checkOutTime!.toLocal();
      }

      int totalBreak = completedBreak;
      if (activeSession == null && latestCheckOut != null) {
        final ongoing = now.difference(latestCheckOut).inSeconds;
        if (ongoing > 0) {
          totalBreak += ongoing;
        }
      }

      final displayTodaySessions = List<AttendanceRecord>.from(todaySessions)
        ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

      if (mounted) {
        setState(() {
          _todaySessions = displayTodaySessions;
          _accumulatedSeconds = accumulatedSec;
          _monthlyAccumulatedSeconds = monthlyAccumulated;
          _completedBreakSeconds = completedBreak;
          _lastCheckOutTime = latestCheckOut;
          _totalBreakSeconds = totalBreak;
          _isCarriedOver = isCarriedOver;
          _attendanceDay = attendanceDay;

          if (activeSession != null) {
            _isCheckedIn = true;
            _currentSessionCheckIn = activeSession.checkInTime.toLocal();
            final currentElapsed =
                DateTime.now().difference(_currentSessionCheckIn!).inSeconds;
            final activeSec = currentElapsed > 0 ? currentElapsed : 0;
            _totalWorkSeconds = _accumulatedSeconds + activeSec;
            _monthlyWorkSeconds = _monthlyAccumulatedSeconds + activeSec;

            LocationMonitorService.instance.startMonitoring(
              onForceCheckoutCallback: _showForceCheckoutDialog,
              initialBreachTime: activeSession.initialOutOfRadiusAt,
            );
          } else {
            _isCheckedIn = false;
            _currentSessionCheckIn = null;
            _totalWorkSeconds = _accumulatedSeconds;
            _monthlyWorkSeconds = _monthlyAccumulatedSeconds;

            LocationMonitorService.instance.stopMonitoring();
          }

          _isLoading = false;
        });
      }

      _syncLocationStatusWithSession();
    } catch (_) {

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _syncLocationStatusWithSession() {
    final office = ApiService.assignedOffice;
    final officeName = office?.name ?? 'Assigned Office';
    final monitor = LocationMonitorService.instance;

    if (_isCheckedIn) {
      if (monitor.state == BreachState.warning) {
        final dist = monitor.lastDistanceMeters ?? 0.0;
        final rad = monitor.allowedRadiusMeters ?? 10.0;
        setState(() {
          _locationStatus = 'Warning';
          _locationStatusBadge = 'Outside Radius';
          _locationStatusSubtext =
              'Outside boundary (${dist.toStringAsFixed(1)}m / ${rad.toStringAsFixed(0)}m) • Auto-checkout in ${monitor.formattedCountdown}';
          _locationStatusColor = const Color(0xFFDC2626);
          _locationStatusBg = const Color(0xFFFEE2E2);
          _locationStatusBorder = const Color(0xFFFCA5A5);
          _locationStatusIcon = Icons.warning_amber_rounded;
        });
        return;
      } else if (monitor.state == BreachState.gpsDisabled) {
        setState(() {
          _locationStatus = 'GPS Lost';
          _locationStatusBadge = 'GPS Off';
          _locationStatusSubtext = 'Please ensure Location / GPS is turned ON';
          _locationStatusColor = const Color(0xFFD97706);
          _locationStatusBg = const Color(0xFFFFFBEB);
          _locationStatusBorder = const Color(0xFFFCD34D);
          _locationStatusIcon = Icons.location_disabled_rounded;
        });
        return;
      }

      setState(() {
        _locationStatus = 'Available';
        _locationStatusBadge = 'In Office';
        _locationStatusSubtext = 'Checked in • Within $officeName';
        _locationStatusColor = const Color(0xFF15803D);
        _locationStatusBg = const Color(0xFFDCFCE7);
        _locationStatusBorder = const Color(0xFF86EFAC);
        _locationStatusIcon = Icons.location_on;
      });
    } else if (_todaySessions.isNotEmpty &&
        _todaySessions.any((s) => s.checkOutTime != null)) {

      setState(() {
        _locationStatus = 'Checked Out';
        _locationStatusBadge = 'Completed';
        _locationStatusSubtext = 'Check in again to validate location';
        _locationStatusColor = const Color(0xFF475569);
        _locationStatusBg = const Color(0xFFF1F5F9);
        _locationStatusBorder = const Color(0xFFCBD5E1);
        _locationStatusIcon = Icons.logout;
      });
    } else {

      setState(() {
        _locationStatus = 'Not Checked In';
        _locationStatusBadge = 'Pending';
        _locationStatusSubtext = 'Location will be validated upon Check-in';
        _locationStatusColor = const Color(0xFF64748B);
        _locationStatusBg = const Color(0xFFF1F5F9);
        _locationStatusBorder = const Color(0xFFCBD5E1);
        _locationStatusIcon = Icons.location_on_outlined;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$formattedHour:$minute $period';
  }

  String _getDayName(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[dt.weekday - 1];
  }

  String _formatMonthDayYear(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatEffortHM(int totalSec) {
    if (totalSec < 0) totalSec = 0;
    final h = (totalSec ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSec % 3600) ~/ 60).toString().padLeft(2, '0');
    return '${h}h ${m}m';
  }

  Future<void> _handleAttendanceAction() async {
    if (_isSubmittingAttendance) return;

    setState(() => _isSubmittingAttendance = true);

    try {

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable GPS / Location services on your phone.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isSubmittingAttendance = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required for attendance.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isSubmittingAttendance = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final result = _isCheckedIn
          ? await ApiService.checkOut(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracyMeters: position.accuracy,
            )
          : await ApiService.checkIn(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracyMeters: position.accuracy,
            );

      if (mounted) {
        if (result['success'] == true) {
          if (!_isCheckedIn) {
            LocationMonitorService.instance.startMonitoring(
              onForceCheckoutCallback: _showForceCheckoutDialog,
            );
            setState(() {
              _locationStatus = 'Available';
              _locationStatusBadge = 'In Office';
              _locationStatusSubtext = 'Check-in verified by server';
              _locationStatusColor = const Color(0xFF15803D);
              _locationStatusBg = const Color(0xFFDCFCE7);
              _locationStatusBorder = const Color(0xFF86EFAC);
              _locationStatusIcon = Icons.location_on;
            });
          } else {
            LocationMonitorService.instance.stopMonitoring();
            setState(() {
              _locationStatus = 'Checked Out';
              _locationStatusBadge = 'Completed';
              _locationStatusSubtext = 'Check-out verified by server';
              _locationStatusColor = const Color(0xFF475569);
              _locationStatusBg = const Color(0xFFF1F5F9);
              _locationStatusBorder = const Color(0xFFCBD5E1);
              _locationStatusIcon = Icons.logout;
            });
          }

          final actionName = _isCheckedIn ? 'Checked out' : 'Checked in';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$actionName successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDashboardData();
        } else {
          final actionAttempted = _isCheckedIn ? 'Check-out' : 'Check-in';

          setState(() {
            _locationStatus = 'Unavailable';
            _locationStatusBadge = 'Outside Radius';
            _locationStatusSubtext =
                result['message'] ?? '$actionAttempted rejected: Outside office radius';
            _locationStatusColor = const Color(0xFFDC2626);
            _locationStatusBg = const Color(0xFFFEE2E2);
            _locationStatusBorder = const Color(0xFFFCA5A5);
            _locationStatusIcon = Icons.location_off;
          });

          final errorMsg =
              result['message'] ?? '$actionAttempted verification failed.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingAttendance = false);
      }
    }
  }

  int _selectedTabIndex = 0;
  final GlobalKey<AttendanceHistoryScreenState> _historyKey =
      GlobalKey<AttendanceHistoryScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          _buildDashboardPage(context),
          AttendanceHistoryScreen(key: _historyKey),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
          if (index == 0) {
            _loadDashboardData();
          } else if (index == 1) {
            _historyKey.currentState?.fetchHistory();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPage(BuildContext context) {
    final employeeName = ApiService.currentEmployee?.fullName ?? 'Employee';
    final officeName = ApiService.assignedOffice?.name ?? 'BrandCrock Office';
    final quote = DashboardScreen.currentQuote ?? DashboardScreen.techQuotes.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'BrandHRMS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDashboardData,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: _showNotificationsTray,
                icon: Icon(
                  _unreadNotifications > 0 ? Icons.notifications_active : Icons.notifications_none,
                  color: _unreadNotifications > 0 ? Colors.amberAccent : Colors.white,
                ),
                tooltip: 'Notifications',
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, $employeeName',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '“${quote.text}” ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                        height: 1.25,
                      ),
                    ),
                    TextSpan(
                      text: '— ${quote.author}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildLocationBreachWarningBanner(context),
              _attendanceCard(context),
              const SizedBox(height: 12),
              _effortMetricsRow(),
              const SizedBox(height: 14),
              _officeCard(officeName),
              const SizedBox(height: 14),
              _locationCard(),
              const SizedBox(height: 14),
              _todayAttendanceLogCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBreachWarningBanner(BuildContext context) {
    final monitor = LocationMonitorService.instance;
    if (monitor.state == BreachState.warning) {
      final dist = monitor.lastDistanceMeters ?? 0.0;
      final radius = monitor.allowedRadiusMeters ?? 10.0;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF87171), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Out of Office Radius!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          monitor.formattedCountdown,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current distance: ${dist.toStringAsFixed(1)}m (Allowed: ${radius.toStringAsFixed(0)}m). Please return within the office boundary to avoid automatic checkout.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7F1D1D),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (monitor.state == BreachState.gpsDisabled) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_disabled_rounded, color: Color(0xFFD97706), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                monitor.lastError ?? 'GPS location disabled. Please ensure Location is enabled on your device.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _attendanceCard(BuildContext context) {
    final now = DateTime.now();
    final dayName = _getDayName(now);
    final dateStr = _formatMonthDayYear(now);

    final hours = _totalWorkSeconds ~/ 3600;
    final mins = (_totalWorkSeconds % 3600) ~/ 60;

    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actions',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '$dayName | $dateStr',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFECEFF1)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(88, 88),
                      painter: RadialTicksPainter(
                        activeRatio:
                            (_totalWorkSeconds / (9 * 3600)).clamp(0.0, 1.0),
                        activeColor: const Color(0xFFFF6565),
                        inactiveColor: const Color(0xFFCFD8DC),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${hours}hr',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6565),
                          ),
                        ),
                        Text(
                          '$mins mins',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: 58,
                width: 1,
                color: const Color(0xFFECEFF1),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentTimeString,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule,
                          size: 13, color: Colors.blueGrey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Asia/Calcutta',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: _isCheckedIn
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isCheckedIn
                            ? const Color(0xFFA5D6A7)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isCheckedIn
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 11,
                          color: _isCheckedIn
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isCheckedIn ? 'Checked In' : 'Not Checked In',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _isCheckedIn
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed:
                  _isSubmittingAttendance ? null : _handleAttendanceAction,
              icon: _isSubmittingAttendance
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isCheckedIn ? Icons.logout : Icons.login,
                      size: 19,
                    ),
              label: Text(
                _isSubmittingAttendance
                    ? 'Verifying Location...'
                    : (_isCheckedIn ? 'Check-out' : 'Check-in'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _isCheckedIn
                    ? const Color(0xFFE53935)
                    : const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _effortMetricsRow() {
    return Row(
      children: [
        Expanded(
          child: _effortCard(
            icon: Icons.access_time_outlined,
            iconColor: const Color(0xFF00BFA5),
            iconBg: const Color(0xFFE0F7F4),
            title: 'Daily Effort',
            value: _formatEffortHM(_totalWorkSeconds),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _effortCard(
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFF1E88E5),
            iconBg: const Color(0xFFE3F2FD),
            title: 'Monthly Effort',
            value: _formatEffortHM(_monthlyWorkSeconds),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _effortCard(
            icon: Icons.local_cafe_outlined,
            iconColor: const Color(0xFFFF5252),
            iconBg: const Color(0xFFFFEBEE),
            title: 'Total Break Hours',
            value: _formatEffortHM(_totalBreakSeconds),
          ),
        ),
      ],
    );
  }

  Widget _effortCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 13, color: iconColor),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _officeCard(String officeName) {
    return _card(
      child: Row(
        children: [
          const Icon(Icons.business, color: primaryColor, size: 35),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assigned Office', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  officeName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard() {
    return _card(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _locationStatusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _locationStatusIcon,
              color: _locationStatusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location Status',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _locationStatus,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _locationStatusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _locationStatusBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _locationStatusBorder,
                        ),
                      ),
                      child: Text(
                        _locationStatusBadge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _locationStatusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_locationStatusSubtext.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _locationStatusSubtext,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayAttendanceLogCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _isTodayLogExpanded = !_isTodayLogExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.event_note, color: primaryColor, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today Login Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isCarriedOver
                              ? 'Active overnight shift carried over from $_attendanceDay'
                              : (_todaySessions.isEmpty
                                  ? 'Tap to view today\'s Logs'
                                  : '${_todaySessions.length} Log${_todaySessions.length > 1 ? 's' : ''} recorded today'),
                          style: TextStyle(
                            fontSize: 12,
                            color: _isCarriedOver
                                ? Colors.amber.shade900
                                : Colors.grey.shade600,
                            fontWeight: _isCarriedOver
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isTodayLogExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade700,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
          if (_isTodayLogExpanded) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (_todaySessions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history,
                          size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 6),
                      Text(
                        'No Logs recorded today yet.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _todaySessions.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 16),
                itemBuilder: (context, index) {
                  final session = _todaySessions[index];
                  final isCurrent = (session.status == 'CHECKED_IN' ||
                          session.status == 'CARRIED_OVER') &&
                      session.checkOutTime == null;
                  final isSessionCarriedOver =
                      session.status == 'CARRIED_OVER' ||
                          (isCurrent && _isCarriedOver);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Session #${_todaySessions.length - index}',
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
                                color: isSessionCarriedOver
                                    ? Colors.amber.shade50
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSessionCarriedOver
                                      ? Colors.amber.shade400
                                      : Colors.green.shade300,
                                ),
                              ),
                              child: Text(
                                isSessionCarriedOver
                                    ? 'Carried Over Shift'
                                    : 'Active Now',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSessionCarriedOver
                                      ? Colors.amber.shade900
                                      : Colors.green,
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.login,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 6),
                          const Text(
                            'Check-in: ',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.logout,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 6),
                            const Text(
                              'Check-out: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              _formatTime(session.checkOutTime!),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class RadialTicksPainter extends CustomPainter {
  final double activeRatio;
  final Color activeColor;
  final Color inactiveColor;

  RadialTicksPainter({
    required this.activeRatio,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const totalTicks = 40;
    final activeTicks = (activeRatio * totalTicks).round();

    final paint = Paint()
      ..strokeWidth = (radius / 22).clamp(1.6, 2.4)
      ..strokeCap = StrokeCap.round;

    final tickLength = radius * 0.22;

    for (int i = 0; i < totalTicks; i++) {
      final angle = (i * 2 * math.pi / totalTicks) - (math.pi / 2);
      final isTickActive = i < activeTicks;
      paint.color = isTickActive ? activeColor : inactiveColor;

      final innerPoint = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      final outerPoint = Offset(
        center.dx + (radius - 2) * math.cos(angle),
        center.dy + (radius - 2) * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RadialTicksPainter oldDelegate) {
    return oldDelegate.activeRatio != activeRatio ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
