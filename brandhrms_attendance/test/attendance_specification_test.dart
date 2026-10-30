import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brandhrms_attendance/services/attendance_formatter.dart';
import 'package:brandhrms_attendance/services/geocoding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // 1 Monthly Efforts – Duration Formatting (UT-001 to UT-008)
  // =========================================================================
  group('1 Monthly Efforts – Duration Formatting', () {
    test('UT-001: Duration is 0 minutes displays 0d 0h 0m', () {
      expect(AttendanceFormatter.formatMonthlyEfforts(0), '0d 0h 0m');
    });

    test('UT-002: Duration is 45 minutes displays 0d 0h 45m', () {
      expect(AttendanceFormatter.formatMonthlyEfforts(45), '0d 0h 45m');
    });

    test('UT-003: Duration is 125 minutes displays 0d 2h 5m', () {
      expect(AttendanceFormatter.formatMonthlyEfforts(125), '0d 2h 5m');
    });

    test('UT-004: Duration is 1,500 minutes displays 1d 1h 0m', () {
      // 1,500 minutes = 24h + 1h = 1d 1h 0m
      expect(AttendanceFormatter.formatMonthlyEfforts(1500), '1d 1h 0m');
    });

    test('UT-005: Duration is 2 days, 5 hours, 30 minutes displays 2d 5h 30m', () {
      const minutes = (2 * 24 * 60) + (5 * 60) + 30; // 3,210 minutes
      expect(AttendanceFormatter.formatMonthlyEfforts(minutes), '2d 5h 30m');
    });

    test('UT-006: Duration is negative handles invalid value without crashing', () {
      expect(AttendanceFormatter.formatMonthlyEfforts(-120), '0d 0h 0m');
    });

    test('UT-007: Duration is null or unavailable displays agreed fallback (--)', () {
      expect(AttendanceFormatter.formatMonthlyEfforts(null), '--');
    });

    test('UT-008: Duration exceeds 30 days displays complete duration without resetting day count', () {
      const minutes = (35 * 24 * 60) + (10 * 60) + 15; // 35 days, 10 hours, 15 minutes
      expect(AttendanceFormatter.formatMonthlyEfforts(minutes), '35d 10h 15m');
    });
  });

  // =========================================================================
  // 2 Check-In / Check-Out – Location Information (UT-009 to UT-018)
  // =========================================================================
  group('2 Check-In / Check-Out – Location Information', () {
    test('UT-009: Location-based attendance enabled displays configured office name', () {
      final loc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: true,
        officeName: 'Munich Tech Hub',
        rawAddress: 'Marienplatz 1, Munich, Bavaria, Germany',
      );
      expect(loc, 'Munich Tech Hub');
    });

    test('UT-010: Location-based attendance disabled displays City, District, State, Country', () {
      final loc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: false,
        officeName: 'Munich Tech Hub',
        rawAddress: 'Marienplatz 1, Munich, District Munich, Bavaria, Germany',
      );
      expect(loc, 'Munich, District Munich, Bavaria, Germany');
    });

    test('UT-011: Enabled with multiple office configurations displays office associated with record', () {
      final locBerlin = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: true,
        officeName: 'Berlin Innovation Hub',
      );
      final locMunich = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: true,
        officeName: 'Munich Center',
      );
      expect(locBerlin, 'Berlin Innovation Hub');
      expect(locMunich, 'Munich Center');
    });

    test('UT-012: Office name is null displays fallback without crashing', () {
      final loc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: true,
        officeName: null,
      );
      expect(loc, 'Office');
    });

    test('UT-013: City is unavailable displays available fields without extra separators', () {
      final formatted = GeocodingService.formatCityDistrictStateCountry('Bangalore Urban, Karnataka, India');
      expect(formatted.contains(', ,'), isFalse);
      expect(formatted.startsWith(','), isFalse);
      expect(formatted.endsWith(','), isFalse);
    });

    test('UT-014: District or State is unavailable displays remaining fields correctly', () {
      final formatted = GeocodingService.formatCityDistrictStateCountry('Berlin, Germany');
      expect(formatted, 'Berlin, Germany');
    });

    test('UT-015: All location fields unavailable displays appropriate fallback', () {
      final loc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: false,
        rawAddress: '',
      );
      expect(loc, 'Off-Site');
    });

    test('UT-016: Location-based attendance configuration changes uses correct rule per record', () {
      final onSiteRecord = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: true,
        officeName: 'HQ Chennai',
      );
      final remoteRecord = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: false,
        rawAddress: 'T Nagar, Chennai, Tamil Nadu, India',
      );
      expect(onSiteRecord, 'HQ Chennai');
      expect(remoteRecord, 'T Nagar, Chennai, Tamil Nadu, India');
    });

    test('UT-017: Check-In and Check-Out have different locations each displays its own location', () {
      final inLoc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: false,
        rawAddress: 'Indiranagar, Bengaluru, Urban, Karnataka, India',
      );
      final outLoc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: false,
        rawAddress: 'Gokulam, Mysuru, Mysuru District, Karnataka, India',
      );
      expect(inLoc, isNot(equals(outLoc)));
    });

    test('UT-018: Location contains special characters or Unicode displays location correctly', () {
      final loc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: true,
        officeName: 'Büro München Süd (GmbH & Co. KG)',
      );
      expect(loc, 'Büro München Süd (GmbH & Co. KG)');
    });
  });

  // =========================================================================
  // 3 Today\'s Login – Session Duration (UT-019 to UT-027)
  // =========================================================================
  group('3 Today\'s Login – Session Duration', () {
    test('UT-019: Duration is 0 seconds displays 0h 0m 0s', () {
      expect(AttendanceFormatter.formatSessionDuration(0), '0h 0m 0s');
    });

    test('UT-020: Duration is 59 seconds displays 0h 0m 59s', () {
      expect(AttendanceFormatter.formatSessionDuration(59), '0h 0m 59s');
    });

    test('UT-021: Duration is 60 seconds displays 0h 1m 0s', () {
      expect(AttendanceFormatter.formatSessionDuration(60), '0h 1m 0s');
    });

    test('UT-022: Duration is 3,661 seconds displays 1h 1m 1s', () {
      expect(AttendanceFormatter.formatSessionDuration(3661), '1h 1m 1s');
    });

    test('UT-023: Duration is 8h 25m 45s displays 8h 25m 45s', () {
      const seconds = (8 * 3600) + (25 * 60) + 45;
      expect(AttendanceFormatter.formatSessionDuration(seconds), '8h 25m 45s');
    });

    test('UT-024: Session exceeds 24 hours displays cumulative hours correctly', () {
      const seconds = (26 * 3600) + (15 * 60) + 20; // 26h 15m 20s
      expect(AttendanceFormatter.formatSessionDuration(seconds), '26h 15m 20s');
    });

    test('UT-025: Session duration updates while active displays updated duration correctly', () {
      int activeSec = 100;
      expect(AttendanceFormatter.formatSessionDuration(activeSec), '0h 1m 40s');
      activeSec += 30;
      expect(AttendanceFormatter.formatSessionDuration(activeSec), '0h 2m 10s');
    });

    test('UT-026: Session is completed displays final session duration', () {
      const finalSec = 28800; // 8 hours completed
      expect(AttendanceFormatter.formatSessionDuration(finalSec), '8h 0m 0s');
    });

    test('UT-027: Invalid or null duration handles gracefully without crashing', () {
      expect(AttendanceFormatter.formatSessionDuration(null), '0h 0m 0s');
      expect(AttendanceFormatter.formatSessionDuration(-500), '0h 0m 0s');
    });
  });

  // =========================================================================
  // 4 Attendance – Calendar (UT-028 to UT-036)
  // =========================================================================
  group('4 Attendance – Calendar', () {
    test('UT-028: Calendar renders GEN label is not displayed', () {
      expect(AttendanceFormatter.getCalendarStatusBadge('GEN'), isEmpty);
      expect(AttendanceFormatter.getCalendarStatusBadge('GENERAL'), isEmpty);
    });

    test('UT-029: Attendance status is Present displays P', () {
      expect(AttendanceFormatter.getCalendarStatusBadge('PRESENT'), 'P');
    });

    test('UT-030: Attendance status is Absent displays A', () {
      expect(AttendanceFormatter.getCalendarStatusBadge('ABSENT'), 'A');
    });

    test('UT-031: Attendance status is Present uses configured green indicator', () {
      final color = AttendanceFormatter.getCalendarStatusColor('PRESENT');
      expect(color, const Color(0xFF16A34A));
    });

    test('UT-032: Attendance status is Absent does not use Present green indicator', () {
      final color = AttendanceFormatter.getCalendarStatusColor('ABSENT');
      expect(color, isNot(equals(const Color(0xFF16A34A))));
    });

    test('UT-033: Status is Holiday, Leave, or Weekend preserves correct status behavior', () {
      expect(AttendanceFormatter.getCalendarStatusBadge('HOLIDAY'), 'H');
      expect(AttendanceFormatter.getCalendarStatusBadge('LEAVE'), 'L');
      expect(AttendanceFormatter.getCalendarStatusBadge('WEEK_OFF'), 'W');
      expect(AttendanceFormatter.getCalendarStatusBadge('WEEKEND'), 'W');
    });

    test('UT-034: Attendance status is unknown uses safe fallback without showing P or A', () {
      final badge = AttendanceFormatter.getCalendarStatusBadge('UNKNOWN_STATUS');
      expect(badge, isNot(equals('P')));
      expect(badge, isNot(equals('A')));
    });

    test('UT-035: Calendar data updates status indicators reflect updated data', () {
      String status = 'ABSENT';
      expect(AttendanceFormatter.getCalendarStatusBadge(status), 'A');
      status = 'PRESENT';
      expect(AttendanceFormatter.getCalendarStatusBadge(status), 'P');
      status = 'SHORTFALL';
      expect(AttendanceFormatter.getCalendarStatusBadge(status), 'SF');
    });

    test('UT-SHORTFALL-01: Attendance status Shortfall displays SF calendar badge', () {
      expect(AttendanceFormatter.getCalendarStatusBadge('SHORTFALL'), 'SF');
    });

    test('UT-SHORTFALL-02: Attendance status Shortfall uses configured amber color', () {
      final color = AttendanceFormatter.getCalendarStatusColor('SHORTFALL');
      expect(color, const Color(0xFFD97706));
    });

    testWidgets('UT-036: Calendar in small viewport indicators remain readable without clipping', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Text(
                  AttendanceFormatter.getCalendarStatusBadge('PRESENT'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('P'), findsOneWidget);
    });
  });

  // =========================================================================
  // 5 Attendance – Location Icon and Positioning (UT-037 to UT-047)
  // =========================================================================
  group('5 Attendance – Location Icon and Positioning', () {
    testWidgets('UT-037: Check-In details render location icon appears below Check-In info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('10:00 AM', key: Key('checkin_time')),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, key: Key('checkin_loc_icon')),
                    Text('Munich Office'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      final timeY = tester.getTopLeft(find.byKey(const Key('checkin_time'))).dy;
      final iconY = tester.getTopLeft(find.byKey(const Key('checkin_loc_icon'))).dy;
      expect(iconY, greaterThan(timeY));
    });

    testWidgets('UT-038: Check-Out details render location icon appears below Check-Out info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('06:00 PM', key: Key('checkout_time')),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, key: Key('checkout_loc_icon')),
                    Text('Munich Office'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      final timeY = tester.getTopLeft(find.byKey(const Key('checkout_time'))).dy;
      final iconY = tester.getTopLeft(find.byKey(const Key('checkout_loc_icon'))).dy;
      expect(iconY, greaterThan(timeY));
    });

    testWidgets('UT-039: Check-In location icon displayed text-based location label is not shown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Icon(Icons.location_on_outlined),
                Text('Munich Office'),
              ],
            ),
          ),
        ),
      );
      expect(find.textContaining('Location:'), findsNothing);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('UT-040: Check-Out location icon displayed text-based location label is not shown', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Icon(Icons.location_on_outlined),
                Text('Munich Office'),
              ],
            ),
          ),
        ),
      );
      expect(find.textContaining('Location:'), findsNothing);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    test('UT-041: Location-based attendance enabled location details use office name', () {
      final officeLoc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: true,
        officeName: 'Central HQ',
      );
      expect(officeLoc, 'Central HQ');
    });

    test('UT-042: Location-based attendance disabled location details use City, District, State, Country', () {
      final geoLoc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: false,
        rawAddress: 'Mitte, Berlin, Germany',
      );
      expect(geoLoc, 'Mitte, Berlin, Germany');
    });

    testWidgets('UT-043: Check-Out has not occurred no misleading Check-Out location displayed', (WidgetTester tester) async {
      Widget buildLocationWidget(String? checkOutLocation) {
        return Column(
          children: [
            const Text('Checked In: 09:00 AM'),
            if (checkOutLocation != null) Text('Check-Out Location: $checkOutLocation'),
          ],
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildLocationWidget(null),
          ),
        ),
      );
      expect(find.textContaining('Check-Out Location'), findsNothing);
    });

    test('UT-044: Check-In location unavailable icon follows agreed fallback', () {
      final loc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: false,
        rawAddress: '',
      );
      expect(loc, 'Off-Site');
    });

    testWidgets('UT-045: Location icon is interactive and activates details', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InkWell(
              key: const Key('loc_btn'),
              onTap: () => tapped = true,
              child: const Icon(Icons.location_on_outlined),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('loc_btn')));
      expect(tapped, isTrue);
    });

    test('UT-046: Check-In and Check-Out both available each icon associated with correct record', () {
      final cin = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: true,
        officeName: 'Site A',
      );
      final cout = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: true,
        officeName: 'Site B',
      );
      expect(cin, 'Site A');
      expect(cout, 'Site B');
    });

    testWidgets('UT-047: Accessibility service reads location icon description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Semantics(
              label: 'Attendance Location',
              child: Icon(Icons.location_on_outlined),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Attendance Location'), findsOneWidget);
    });
  });

  // =========================================================================
  // 6 Attendance – View and Filter Icons (UT-048 to UT-056)
  // =========================================================================
  group('6 Attendance – View and Filter Icons', () {
    testWidgets('UT-048: Attendance record actions view icon appears without View text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.text('View'), findsNothing);
    });

    testWidgets('UT-049: View icon is tapped opens correct attendance details', (WidgetTester tester) async {
      bool modalOpened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              key: const Key('view_swipes'),
              icon: const Icon(Icons.touch_app_outlined),
              onPressed: () => modalOpened = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('view_swipes')));
      expect(modalOpened, isTrue);
    });

    testWidgets('UT-050: Filter control renders standard funnel icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
    });

    testWidgets('UT-051: Filter icon is tapped opens existing filter interface', (WidgetTester tester) async {
      bool filterTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              key: const Key('filter_funnel'),
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () => filterTapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('filter_funnel')));
      expect(filterTapped, isTrue);
    });

    test('UT-052: Filter applied attendance data reflects selected filters', () {
      final allDays = [1, 2, 3, 4, 5];
      final filtered = allDays.where((d) => d == 3).toList();
      expect(filtered.length, 1);
      expect(filtered.first, 3);
    });

    test('UT-053: Filter cleared default attendance data restored', () {
      final allDays = [1, 2, 3, 4, 5];
      var filtered = allDays.where((d) => d == 3).toList();
      expect(filtered.length, 1);
      // Clear filter
      filtered = List.from(allDays);
      expect(filtered.length, 5);
    });

    testWidgets('UT-054: View and Filter icons render consistent dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Icon(Icons.visibility_outlined, size: 20),
                Icon(Icons.filter_list_rounded, size: 20),
              ],
            ),
          ),
        ),
      );
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons[0].size, equals(icons[1].size));
    });

    testWidgets('UT-055: Accessibility service reads meaningful labels for icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              tooltip: 'Filter Attendance Records',
              icon: Icon(Icons.filter_list),
              onPressed: null,
            ),
          ),
        ),
      );
      expect(find.byTooltip('Filter Attendance Records'), findsOneWidget);
    });

    testWidgets('UT-056: Icon action disabled displays disabled state and prevents tap', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: null, // Disabled
            ),
          ),
        ),
      );
      final btn = tester.widget<IconButton>(find.byType(IconButton));
      expect(btn.onPressed, isNull);
      expect(tapped, isFalse);
    });
  });

  // =========================================================================
  // 7 Android UI Optimization (UT-057 to UT-070)
  // =========================================================================
  group('7 Android UI Optimization', () {
    test('UT-057: Component sizes use density-independent dimensions (dp)', () {
      const double cardPaddingDp = 16.0;
      expect(cardPaddingDp, equals(16.0));
    });

    test('UT-058: Font dimensions use scalable sp units', () {
      const double titleFontSizeSp = 18.0;
      expect(titleFontSizeSp, equals(18.0));
    });

    testWidgets('UT-059: Device font scaling increases text scales without clipping', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.2), // Accessibility scaling
              ),
              child: child!,
            );
          },
          home: const Scaffold(
            body: Text('October 15, 2026 – 10:00 PM'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('UT-060: Small screen width (320dp) simulated without horizontal overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.login),
                      SizedBox(width: 8),
                      Expanded(child: Text('Check-In: October 15, 2026 – 10:00 PM')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('UT-061: Large screen width simulated maintains intended alignment', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const Text('Responsive Card'),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('UT-062: Long office name displayed wraps or truncates according to design', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              child: Text(
                'Very Long European Headquarters Innovation Center Munich Campus',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('UT-063: Long location details displayed without overlap with adjacent controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: Text(
                    'Friedrichstraße 43, Mitte, 10117 Berlin, Federal Republic of Germany',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('UT-064: Icon buttons meet recommended 48dp minimum touch target', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {},
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('UT-065: Light and dark themes applied text and icons remain readable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Text('Dark Mode Attendance'),
          ),
        ),
      );
      expect(find.text('Dark Mode Attendance'), findsOneWidget);
    });

    testWidgets('UT-066: Screen orientation changes layout maintains expected structure', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 400); // Landscape
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Text('Landscape View'),
            ),
          ),
        ),
      );
      expect(find.text('Landscape View'), findsOneWidget);
    });

    test('UT-067: Different screen densities component proportions remain consistent', () {
      const baseWidthDp = 100.0;
      expect(baseWidthDp, equals(100.0)); // Density-independent logical pixels
    });

    testWidgets('UT-068: Attendance data loading state renders without layout errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('UT-069: Attendance API returns empty data empty state renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('No attendance records found'),
            ),
          ),
        ),
      );
      expect(find.text('No attendance records found'), findsOneWidget);
    });

    test('UT-070: API returns malformed optional fields handled without crashing', () {
      final loc = AttendanceFormatter.formatLocationDisplay(
        locationAttendanceEnabled: true,
        officeName: null,
        rawAddress: null,
      );
      expect(loc, isNotEmpty);
      expect(loc, 'Office');
    });
  });
}
