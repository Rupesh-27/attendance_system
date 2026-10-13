import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'api_service.dart';

enum BreachState {
  normal,
  warning,
  forceCheckedOut,
  gpsDisabled,
}

class LocationMonitorService extends ChangeNotifier {
  static final LocationMonitorService instance = LocationMonitorService._();
  LocationMonitorService._();

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _countdownTimer;

  bool _isMonitoring = false;
  BreachState _state = BreachState.normal;
  int _totalGraceSeconds = 120;
  int _countdownSeconds = 120;
  DateTime? _breachStartTime;
  double? _lastDistanceMeters;
  double? _allowedRadiusMeters;
  String? _lastError;

  VoidCallback? onForceCheckout;

  bool get isMonitoring => _isMonitoring;
  BreachState get state => _state;
  int get countdownSeconds => _countdownSeconds;
  DateTime? get breachStartTime => _breachStartTime;
  double? get lastDistanceMeters => _lastDistanceMeters;
  double? get allowedRadiusMeters => _allowedRadiusMeters;
  String? get lastError => _lastError;

  String get formattedCountdown {
    final m = _countdownSeconds ~/ 60;
    final s = _countdownSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> startMonitoring({
    VoidCallback? onForceCheckoutCallback,
    DateTime? initialBreachTime,
  }) async {
    if (_isMonitoring) return;

    onForceCheckout = onForceCheckoutCallback;
    _isMonitoring = true;
    _totalGraceSeconds = 120;
    _countdownSeconds = 120;
    _lastError = null;

    if (!ApiService.isLocationAttendanceRequired) {
      _isMonitoring = false;
      _state = BreachState.normal;
      _breachStartTime = null;
      notifyListeners();
      return;
    }

    final office = ApiService.assignedOffice;
    if (office != null) {
      _allowedRadiusMeters = office.radiusMeters;
    }

    // Fetch dynamic system settings if available
    try {
      final settings = await ApiService.getSettings();
      if (settings != null) {
        if (!ApiService.isLocationAttendanceRequired) {
          _isMonitoring = false;
          _state = BreachState.normal;
          _breachStartTime = null;
          notifyListeners();
          return;
        }
        if (settings.retryIntervalMinutes > 0) {
          _totalGraceSeconds = settings.retryIntervalMinutes * 60;
          _countdownSeconds = _totalGraceSeconds;
        }
      }
    } catch (_) {}

    // Check if an existing breach timestamp is active from the session
    if (initialBreachTime != null) {
      final elapsed = DateTime.now().toUtc().difference(initialBreachTime.toUtc()).inSeconds;
      if (elapsed >= _totalGraceSeconds) {
        // Full grace period already elapsed while phone screen was off or app was closed!
        _state = BreachState.warning;
        _breachStartTime = initialBreachTime;
        _countdownSeconds = 0;
        notifyListeners();
        _executeRetryCheck();
        return;
      } else if (elapsed > 0) {
        // Resume remaining countdown based on real wall-clock elapsed time
        _state = BreachState.warning;
        _breachStartTime = initialBreachTime;
        _countdownSeconds = _totalGraceSeconds - elapsed;
        _startTimerTicker();
      } else {
        _state = BreachState.normal;
        _breachStartTime = null;
        _countdownSeconds = _totalGraceSeconds;
      }
    } else {
      _state = BreachState.normal;
      _breachStartTime = null;
      _countdownSeconds = _totalGraceSeconds;
    }

    notifyListeners();

    // Verify location services and permissions before starting stream
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _state = BreachState.gpsDisabled;
      _lastError = 'Location service is disabled';
      notifyListeners();
      return;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _state = BreachState.gpsDisabled;
      _lastError = 'Location permission is not granted';
      notifyListeners();
      return;
    }

    _startPositionStream();
  }

  void _startPositionStream() {
    _positionStreamSubscription?.cancel();

    LocationSettings locationSettings;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 15),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'BrandHRMS',
          notificationText: 'Checked in • Shift in progress',
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    // Grab quick initial position for instantaneous UI display
    Geolocator.getLastKnownPosition().then((pos) {
      if (pos != null && _isMonitoring) {
        _processPosition(pos);
      }
    }).catchError((_) {});

    // Listen to continuous position stream with persistent foreground service
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _processPosition(position);
      },
      onError: (dynamic error) {
        _handleLocationError(error);
      },
    );
  }

  void stopMonitoring() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isMonitoring = false;
    _breachStartTime = null;
    notifyListeners();
  }

  void reset() {
    stopMonitoring();
    _state = BreachState.normal;
    _countdownSeconds = 120;
    _lastDistanceMeters = null;
    _lastError = null;
    notifyListeners();
  }

  void _processPosition(Position position) {
    if (!_isMonitoring) return;
    if (!ApiService.isLocationAttendanceRequired) return;

    final office = ApiService.assignedOffice;
    if (office == null) return;
    _allowedRadiusMeters = office.radiusMeters;

    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      office.latitude,
      office.longitude,
    );

    _lastDistanceMeters = distance;
    _lastError = null;

    if (distance <= office.radiusMeters) {
      // Inside allowed radius
      if (_state == BreachState.warning) {
        _cancelWarning();
      } else if (_state == BreachState.gpsDisabled) {
        _state = BreachState.normal;
        notifyListeners();
      } else {
        notifyListeners();
      }
    } else {
      // Outside allowed radius (distance > office.radiusMeters)
      if (_state == BreachState.normal || _state == BreachState.gpsDisabled) {
        // First breach detected! Start 2-minute countdown state machine
        _startWarningCountdown(position);
      }
    }
  }

  void _handleLocationError(dynamic error) {
    if (!_isMonitoring) return;
    _state = BreachState.gpsDisabled;
    _lastError = 'Unable to acquire GPS signal. Please ensure Location is enabled.';
    notifyListeners();
  }

  void _startWarningCountdown(Position pos) {
    _state = BreachState.warning;
    _breachStartTime = DateTime.now();
    _countdownSeconds = _totalGraceSeconds;

    // Inform backend of breach start timestamp
    ApiService.recordBreachWarning(breachedAt: _breachStartTime);

    notifyListeners();
    _startTimerTicker();
  }

  void _startTimerTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }

      if (_breachStartTime != null) {
        final elapsed = DateTime.now().difference(_breachStartTime!).inSeconds;
        final remaining = _totalGraceSeconds - elapsed;

        if (remaining > 0) {
          _countdownSeconds = remaining;
          notifyListeners();
        } else {
          _countdownSeconds = 0;
          timer.cancel();
          notifyListeners();
          _executeRetryCheck();
        }
      } else {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
          notifyListeners();
        } else {
          timer.cancel();
          _executeRetryCheck();
        }
      }
    });
  }

  void _cancelWarning() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _state = BreachState.normal;
    _breachStartTime = null;
    _countdownSeconds = _totalGraceSeconds;
    ApiService.clearBreachWarning();
    notifyListeners();
  }

  Future<void> _executeRetryCheck() async {
    final office = ApiService.assignedOffice;
    if (office == null) return;

    Position? position;
    try {
      LocationSettings retrySettings;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        retrySettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 3),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'BrandHRMS',
            notificationText: 'Verifying final geofence location',
            enableWakeLock: true,
          ),
        );
      } else {
        retrySettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        );
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: retrySettings,
      );
    } catch (_) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    if (position != null) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        office.latitude,
        office.longitude,
      );

      _lastDistanceMeters = distance;

      if (distance <= office.radiusMeters) {
        // Successfully moved back inside radius
        _cancelWarning();
        return;
      }
    }

    // Still outside after 2 minutes or GPS unavailable -> FORCE CHECKOUT!
    if (position != null) {
      await _performForceCheckout(position);
    } else {
      final fallbackPos = Position(
        latitude: office.latitude + 0.001,
        longitude: office.longitude + 0.001,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
      await _performForceCheckout(fallbackPos);
    }
  }

  Future<void> _performForceCheckout(Position position) async {
    _state = BreachState.forceCheckedOut;
    stopMonitoring();

    try {
      await ApiService.forceCheckOut(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        breachedAt: _breachStartTime,
        reason: 'FORCE_CHECKOUT_OUT_OF_RADIUS',
      );
    } catch (_) {}

    notifyListeners();
    onForceCheckout?.call();
  }
}
