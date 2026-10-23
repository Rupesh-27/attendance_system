import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_monitor_service.dart';
import 'attendance_history_screen.dart';
import 'leave_management_screen.dart';
import 'profile_screen.dart';
import '../services/language_service.dart';
import '../main.dart';

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

  static const Map<AppLanguage, List<TechQuote>> quotesByLanguage = {
    AppLanguage.english: [
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
    ],
    AppLanguage.german: [
      TechQuote(
        text: 'Phantasie ist wichtiger als Wissen, denn Wissen ist begrenzt.',
        author: 'Albert Einstein',
      ),
      TechQuote(
        text: 'Der beste Weg, die Zukunft vorauszusagen, ist, sie zu gestalten.',
        author: 'Willy Brandt',
      ),
      TechQuote(
        text: 'Erfolg hat drei Buchstaben: TUN.',
        author: 'Johann Wolfgang von Goethe',
      ),
      TechQuote(
        text: 'Die wahre Kunst ist, Komplexität in Einfachheit zu verwandeln.',
        author: 'Konrad Zuse',
      ),
      TechQuote(
        text: 'Es ist nicht genug zu wissen, man muss auch anwenden; es ist nicht genug zu wollen, man muss auch tun.',
        author: 'Johann Wolfgang von Goethe',
      ),
      TechQuote(
        text: 'Mehr als die Vergangenheit interessiert mich die Zukunft, denn in ihr gedenke ich zu leben.',
        author: 'Albert Einstein',
      ),
      TechQuote(
        text: 'Technik ist die Kunst, die Natur nach den Bedürfnissen des Menschen zu gestalten.',
        author: 'Werner von Siemens',
      ),
      TechQuote(
        text: 'Wenn die Notwendigkeit besteht, muss man das Unmögliche möglich machen.',
        author: 'Konrad Zuse',
      ),
      TechQuote(
        text: 'Zusammenkunft ist ein Anfang, Zusammenhalt ist ein Fortschritt, Zusammenarbeit ist der Erfolg.',
        author: 'Henry Ford',
      ),
      TechQuote(
        text: 'Probleme kann man niemals mit derselben Denkweise lösen, durch die sie entstanden sind.',
        author: 'Albert Einstein',
      ),
      TechQuote(
        text: 'Wer aufhört, besser werden zu wollen, hört auf, gut zu sein.',
        author: 'Marie von Ebner-Eschenbach',
      ),
      TechQuote(
        text: 'Ordnung und Disziplin sind der Schlüssel zu herausragender Produktivität.',
        author: 'Gottfried Wilhelm Leibniz',
      ),
    ],
    AppLanguage.belarusian: [
      TechQuote(
        text: 'Чалавек без працы — як дзень без сонца.',
        author: 'Якуб Колас',
      ),
      TechQuote(
        text: 'Шчасце не ў тым, каб мець усё, а ў тым, каб ствараць сваёй працай.',
        author: 'Янка Купала',
      ),
      TechQuote(
        text: 'Любіце і шануйце сваю справу, і яна адкажа вам поспехам.',
        author: 'Францыск Скарына',
      ),
      TechQuote(
        text: 'Толькі той дасягае мэты, хто не спыняецца перад цяжкасцямі.',
        author: 'Максім Багдановіч',
      ),
      TechQuote(
        text: 'Будучыня належыць тым, хто вучыцца і не баіцца новых тэхналогій.',
        author: 'Кузьма Чорны',
      ),
      TechQuote(
        text: 'Праца і навука адкрываюць дзверы ў новы свет магчымасцей.',
        author: 'Васіль Быкаў',
      ),
      TechQuote(
        text: 'Шлях да майстэрства пачынаецца з кожнага маленькага кроку.',
        author: 'Якуб Колас',
      ),
      TechQuote(
        text: 'Кожная новая тэхналогія павінна служыць дабру і развіццю чалавека.',
        author: 'Уладзімір Караткевіч',
      ),
      TechQuote(
        text: 'Сіла ў адзінстве каманды і імкненні да лепшага выніку.',
        author: 'Янка Брыль',
      ),
      TechQuote(
        text: 'Штодзённая сумленная праца — гэта фундамент вялікага поспеху.',
        author: 'Максім Гарэцкі',
      ),
    ],
  };

  static List<TechQuote> get techQuotes =>
      quotesByLanguage[LanguageService.instance.currentLanguage] ??
      quotesByLanguage[AppLanguage.english]!;

  static int _quoteIndex = 0;

  static TechQuote get currentQuote {
    final list = techQuotes;
    if (list.isEmpty) {
      return const TechQuote(
        text: 'Work with dedication and excellence.',
        author: 'BrandHRMS',
      );
    }
    return list[_quoteIndex % list.length];
  }

  static void pickNewQuote() {
    final random = math.Random();
    final list = techQuotes;
    if (list.length <= 1) {
      _quoteIndex = 0;
      return;
    }
    int newIndex;
    do {
      newIndex = random.nextInt(list.length);
    } while (newIndex == _quoteIndex % list.length);
    _quoteIndex = newIndex;
  }

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    LocationMonitorService.instance.addListener(_onLocationMonitorChanged);
    LanguageService.instance.addListener(_onLanguageChanged);
    ApiService.onSessionTerminated = _onSessionTerminated;
    DashboardScreen.pickNewQuote();
    _currentTimeString = _getRealTimeClock();
    _startLiveTimer();
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocationMonitorService.instance.removeListener(_onLocationMonitorChanged);
    LanguageService.instance.removeListener(_onLanguageChanged);
    if (ApiService.onSessionTerminated == _onSessionTerminated) {
      ApiService.onSessionTerminated = null;
    }
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LocationMonitorService.instance.refreshPermissionStatus();
      if (mounted) setState(() {});
    }
  }

  bool _isSessionTerminating = false;

  void _onSessionTerminated() {
    if (!mounted || _isSessionTerminating) return;
    _isSessionTerminating = true;
    _liveTimer?.cancel();
    LocationMonitorService.instance.stopMonitoring();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_clock, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('session_expired_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          tr('session_expired_msg'),
          style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              tr('ok'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
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
                            Text(
                              tr('notifications'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            child: Text(tr('clear_all'), style: const TextStyle(color: Colors.red)),
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
                              tr('no_new_notifications'),
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
                                tr(item.title),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 3),
                                  Text(tr(item.message), style: const TextStyle(fontSize: 12.5)),
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
      title: tr('automatic_checkout'),
      message: tr('automatic_checkout_dialog_msg'),
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
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('automatic_checkout_notice'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr('out_of_radius_banner_desc'),
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
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
            Expanded(
              child: Text(
                tr('automatic_checkout'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          tr('automatic_checkout_dialog_msg'),
          style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF334155)),
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
            child: Text(tr('understood'), style: const TextStyle(fontWeight: FontWeight.w600)),
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
    DashboardScreen.pickNewQuote();
    setState(() => _isLoading = true);

    try {

      await Future.wait([
        ApiService.getProfile(),
        ApiService.getAssignedOffice(),
        ApiService.getSettings(),
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

            if (ApiService.isLocationAttendanceRequired) {
              LocationMonitorService.instance.startMonitoring(
                onForceCheckoutCallback: _showForceCheckoutDialog,
                initialBreachTime: activeSession.initialOutOfRadiusAt,
              );
            } else {
              LocationMonitorService.instance.stopMonitoring();
            }
          } else {
            final wasCheckedInLocally = _isCheckedIn;
            _isCheckedIn = false;
            _currentSessionCheckIn = null;
            _totalWorkSeconds = _accumulatedSeconds;
            _monthlyWorkSeconds = _monthlyAccumulatedSeconds;

            LocationMonitorService.instance.stopMonitoring();

            if (wasCheckedInLocally &&
                displayTodaySessions.isNotEmpty &&
                displayTodaySessions.first.checkoutReason == 'FORCE_CHECKOUT_OUT_OF_RADIUS') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showForceCheckoutDialog();
              });
            }
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
      if (!ApiService.isLocationAttendanceRequired) {
        setState(() {
          _locationStatus = 'Off-Site';
          _locationStatusBadge = 'Remote';
          _locationStatusSubtext = 'Check-in active • Off-site verified';
          _locationStatusColor = const Color(0xFF0284C7);
          _locationStatusBg = const Color(0xFFE0F2FE);
          _locationStatusBorder = const Color(0xFF7DD3FC);
          _locationStatusIcon = Icons.share_location_rounded;
        });
        return;
      }

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
      if (!ApiService.isLocationAttendanceRequired) {
        setState(() {
          _locationStatus = 'Ready';
          _locationStatusBadge = 'Off-Site';
          _locationStatusSubtext = 'Off-site check-in enabled • Coordinates will be logged';
          _locationStatusColor = const Color(0xFF0284C7);
          _locationStatusBg = const Color(0xFFE0F2FE);
          _locationStatusBorder = const Color(0xFF7DD3FC);
          _locationStatusIcon = Icons.share_location_rounded;
        });
        return;
      }

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
    if (hour < 12) return tr('good_morning');
    if (hour < 17) return tr('good_afternoon');
    return tr('good_evening');
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
    return tr('weekday_full_${dt.weekday}');
  }

  String _formatMonthDayYear(DateTime dt) {
    final code = LanguageService.instance.currentCode;
    final monthName = tr('month_genitive_${dt.month}');
    if (code == 'de') {
      return '${dt.day}. $monthName ${dt.year}';
    } else if (code == 'be') {
      return '${dt.day} $monthName ${dt.year}';
    }
    return '${tr('month_${dt.month}')} ${dt.day}, ${dt.year}';
  }

  String _getLocalizedLocationSubtext(String officeName) {
    if (_locationStatusSubtext.contains('Location will be validated') ||
        _locationStatusSubtext.contains('validate_upon_checkin')) {
      return tr('loc_subtext_validate_upon_checkin');
    }
    if (_locationStatusSubtext.contains('Off-site verified') ||
        _locationStatusSubtext.contains('offsite_verified')) {
      return tr('loc_subtext_offsite_verified');
    }
    if (_locationStatusSubtext.contains('turned ON') ||
        _locationStatusSubtext.contains('gps_on')) {
      return tr('loc_subtext_gps_on');
    }
    if (_locationStatusSubtext.contains('Within')) {
      return '${tr('checked_in')} • $officeName';
    }
    if (_locationStatusSubtext.contains('Check in again') ||
        _locationStatusSubtext.contains('check_in_again')) {
      return tr('loc_subtext_check_in_again');
    }
    if (_locationStatusSubtext.contains('Coordinates will be logged') ||
        _locationStatusSubtext.contains('offsite_enabled')) {
      return tr('loc_subtext_offsite_enabled');
    }
    if (_locationStatusSubtext.contains('Check-in verified') ||
        _locationStatusSubtext.contains('checkin_verified')) {
      return tr('loc_subtext_checkin_verified');
    }
    if (_locationStatusSubtext.contains('Coordinates captured') ||
        _locationStatusSubtext.contains('coords_captured')) {
      return tr('loc_subtext_coords_captured');
    }
    if (_locationStatusSubtext.contains('Check-out verified') ||
        _locationStatusSubtext.contains('checkout_verified')) {
      return tr('loc_subtext_checkout_verified');
    }
    return tr(_locationStatusSubtext);
  }

  String _formatEffortHM(int totalSec) {
    if (totalSec < 0) totalSec = 0;
    final h = (totalSec ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSec % 3600) ~/ 60).toString().padLeft(2, '0');
    return '$h ${tr('unit_hr')} $m ${tr('unit_min')}';
  }

  String _formatMonthlyEffortDHM(int totalSec) {
    if (totalSec < 0) totalSec = 0;
    final d = totalSec ~/ 86400;
    final h = (totalSec % 86400) ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    return '$d ${tr('unit_day')} $h ${tr('unit_hr')} $m ${tr('unit_min')}';
  }

  String _formatSessionDurationHMS(int totalSec) {
    if (totalSec < 0) totalSec = 0;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    return '$h ${tr('unit_hr')} $m ${tr('unit_min')} $s ${tr('unit_sec')}';
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

  Future<void> _handleAttendanceAction() async {
    if (_isSubmittingAttendance) return;

    setState(() => _isSubmittingAttendance = true);

    try {

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('enable_gps_prompt')),
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
            SnackBar(
              content: Text(tr('location_permission_required')),
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

      final address = await GeocodingService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
        cityDistrictStateCountryOnly: !ApiService.isLocationAttendanceRequired,
      );

      final result = _isCheckedIn
          ? await ApiService.checkOut(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracyMeters: position.accuracy,
              address: address,
            )
          : await ApiService.checkIn(
              latitude: position.latitude,
              longitude: position.longitude,
              accuracyMeters: position.accuracy,
              address: address,
            );

      if (mounted) {
        if (result['success'] == true) {
          if (!_isCheckedIn) {
            if (ApiService.isLocationAttendanceRequired) {
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
              _checkAndPromptBackgroundPermission();
            } else {
              LocationMonitorService.instance.stopMonitoring();
              setState(() {
                _locationStatus = 'Off-Site';
                _locationStatusBadge = 'Remote';
                _locationStatusSubtext = 'Check-in recorded • Coordinates captured';
                _locationStatusColor = const Color(0xFF0284C7);
                _locationStatusBg = const Color(0xFFE0F2FE);
                _locationStatusBorder = const Color(0xFF7DD3FC);
                _locationStatusIcon = Icons.share_location_rounded;
              });
            }
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isCheckedIn ? tr('checked_out_successfully') : tr('checked_in_successfully')),
              backgroundColor: Colors.green,
            ),
          );
          _loadDashboardData();
        } else {
          final actionAttempted = _isCheckedIn ? 'Check-out' : 'Check-in';
          final rawMsg = result['message'] as String? ?? '';
          final isAccuracyError = rawMsg.toLowerCase().contains('accuracy');
          final isOutsideRadius = rawMsg.toLowerCase().contains('outside');

          setState(() {
            _locationStatus = 'Unavailable';
            _locationStatusBadge = isAccuracyError
                ? 'Weak GPS'
                : (isOutsideRadius ? 'Outside Radius' : 'Failed');
            _locationStatusSubtext =
                result['message'] ?? '$actionAttempted failed. Please verify location.';
            _locationStatusColor = const Color(0xFFDC2626);
            _locationStatusBg = const Color(0xFFFEE2E2);
            _locationStatusBorder = const Color(0xFFFCA5A5);
            _locationStatusIcon = isAccuracyError
                ? Icons.gps_not_fixed_rounded
                : Icons.location_off;
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
            content: Text('${tr('error')}: ${e.toString()}'),
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
  final GlobalKey<LeaveManagementScreenState> _leaveKey =
      GlobalKey<LeaveManagementScreenState>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F9),
          body: IndexedStack(
            index: _selectedTabIndex,
            children: [
              _buildDashboardPage(context),
              AttendanceHistoryScreen(key: _historyKey),
              LeaveManagementScreen(key: _leaveKey),
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
          } else if (index == 2) {
            _leaveKey.currentState?.refreshData();
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: tr('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.access_time_outlined),
            selectedIcon: const Icon(Icons.access_time),
            label: tr('attendance'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: tr('leaves'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: tr('profile'),
          ),
        ],
      ),
    );
  },
);
}

  Widget _buildDashboardPage(BuildContext context) {
    final employeeName = ApiService.currentEmployee?.fullName ?? 'Employee';
    final officeName = ApiService.assignedOffice?.name ?? 'BrandCrock Office';
    final quote = DashboardScreen.currentQuote;

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
            tooltip: tr('refresh'),
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
                tooltip: tr('notifications'),
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
                      Text(
                        tr('out_of_office_radius'),
                        style: const TextStyle(
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
                    '${tr('current_distance')}: ${dist.toStringAsFixed(1)} ${tr('meters')} (${tr('allowed')}: ${radius.toStringAsFixed(0)} ${tr('meters')}). ${tr('breach_warning_return_prompt')}',
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
                monitor.lastError != null
                    ? tr(monitor.lastError!)
                    : tr('gps_disabled_banner'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onPressed: () async {
                await LocationMonitorService.openLocationSettings();
                await LocationMonitorService.instance.refreshPermissionStatus();
                if (mounted) setState(() {});
              },
              child: Text(
                tr('open_settings'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
              ),
            ),
          ],
        ),
      );
    } else if (_isCheckedIn && !monitor.hasBackgroundPermission) {
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
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('background_restricted_warning'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onPressed: () async {
                await LocationMonitorService.openAppSettings();
                await LocationMonitorService.instance.refreshPermissionStatus();
                if (mounted) setState(() {});
              },
              child: Text(
                tr('open_settings'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _checkAndPromptBackgroundPermission() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse) {
        if (!mounted) return;
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.location_on, color: primaryColor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr('background_location_title'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              tr('background_location_desc'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('grant_permission')),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          final granted = await LocationMonitorService.requestBackgroundPermission();
          if (!granted && mounted) {
            await LocationMonitorService.openAppSettings();
          }
          if (mounted) {
            await LocationMonitorService.instance.refreshPermissionStatus();
            setState(() {});
          }
        }
      }
    } catch (_) {}
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
              Text(
                tr('actions'),
                style: const TextStyle(
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
                          '$hours ${tr('unit_hr')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6565),
                          ),
                        ),
                        Text(
                          '$mins ${tr('unit_min')}',
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
                          _isCheckedIn ? tr('checked_in') : tr('not_checked_in'),
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
            height: 48,
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
                    ? tr('verifying_location')
                    : (_isCheckedIn ? tr('check_out') : tr('check_in')),
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
            title: tr('daily_effort'),
            value: _formatEffortHM(_totalWorkSeconds),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _effortCard(
            icon: Icons.calendar_month_outlined,
            iconColor: const Color(0xFF1E88E5),
            iconBg: const Color(0xFFE3F2FD),
            title: tr('monthly_effort'),
            value: _formatMonthlyEffortDHM(_monthlyWorkSeconds),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _effortCard(
            icon: Icons.local_cafe_outlined,
            iconColor: const Color(0xFFFF5252),
            iconBg: const Color(0xFFFFEBEE),
            title: tr('total_break_hours'),
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
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
                Text(tr('assigned_office'), style: const TextStyle(color: Colors.grey)),
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
                Text(
                  tr('geofence_status'),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      LanguageService.localizeAttendanceStatus(_locationStatus),
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
                        tr(_locationStatusBadge),
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
                    _getLocalizedLocationSubtext(ApiService.assignedOffice?.name ?? 'Office'),
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
                        Text(
                          tr('today_login_status'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isCarriedOver
                              ? '${tr('carried_over_shift_from')} $_attendanceDay'
                              : (_todaySessions.isEmpty
                                  ? tr('tap_to_view_logs')
                                  : '${_todaySessions.length} ${_todaySessions.length > 1 ? tr('logs_recorded_today') : tr('log_recorded_today')}'),
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
                        tr('no_logs_today'),
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
                            "${tr('session')} #${_todaySessions.length - index}",
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
                                    ? tr('carried_over_shift')
                                    : tr('active_now'),
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
                                  ? "${tr('duration')}: ${_formatSessionDurationHMS(session.durationSeconds!)}"
                                  : '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Check-in info
                      () {
                        final inLoc = _formatSessionLocation(
                          session.checkInAddress,
                          session.officeSnapshotName,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.login,
                                    size: 16, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  "${tr('check_in')}: ",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                Text(
                                  _formatTime(session.checkInTime),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            if (inLoc.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const SizedBox(width: 22),
                                  Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      inLoc,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        );
                      }(),
                      if (session.checkOutTime != null) ...[
                        const SizedBox(height: 4),
                        () {
                          final outLoc = _formatSessionLocation(
                            session.checkOutAddress,
                            session.officeSnapshotName,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.logout,
                                      size: 16, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${tr('check_out')}: ",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  Text(
                                    _formatTime(session.checkOutTime!),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              if (outLoc.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const SizedBox(width: 22),
                                    Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        outLoc,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        }(),
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
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
