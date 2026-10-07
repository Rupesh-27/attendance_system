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

  Timer? _pollingTimer;
  Timer? _countdownTimer;

  bool _isMonitoring = false;
  BreachState _state = BreachState.normal;
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

  Future<void> startMonitoring({VoidCallback? onForceCheckoutCallback}) async {
    if (_isMonitoring) return;

    onForceCheckout = onForceCheckoutCallback;
    _isMonitoring = true;
    _state = BreachState.normal;
    _breachStartTime = null;
    _countdownSeconds = 120;
    _lastError = null;

    // Fetch dynamic system settings if available
    try {
      final settings = await ApiService.getSettings();
      if (settings != null && settings.retryIntervalMinutes > 0) {
        _countdownSeconds = settings.retryIntervalMinutes * 60;
      }
    } catch (_) {}

    notifyListeners();

    // Start 30-second continuous GPS polling
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pollLocation();
    });

    // Run first check immediately
    _pollLocation();
  }

  void stopMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
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

  Future<void> _pollLocation() async {
    if (!_isMonitoring) return;

    final office = ApiService.assignedOffice;
    if (office == null) return;
    _allowedRadiusMeters = office.radiusMeters;

    try {
      // Check location service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Outcome C: GPS disabled - handle separately, DO NOT force checkout
        _state = BreachState.gpsDisabled;
        _lastError = 'Location service is disabled';
        notifyListeners();
        return;
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Outcome C: Permission lost
        _state = BreachState.gpsDisabled;
        _lastError = 'Location permission is not granted';
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        office.latitude,
        office.longitude,
      );

      _lastDistanceMeters = distance;
      _lastError = null;

      if (distance <= office.radiusMeters) {
        // Outcome A: Inside allowed radius
        if (_state == BreachState.warning) {
          // Warning cancelled, back inside
          _cancelWarning();
        } else if (_state == BreachState.gpsDisabled) {
          _state = BreachState.normal;
          notifyListeners();
        }
      } else {
        // Outside allowed radius (distance > office.radiusMeters)
        if (_state == BreachState.normal || _state == BreachState.gpsDisabled) {
          // First breach detected! Start 2-minute countdown state machine
          _startWarningCountdown(position);
        }
      }
    } catch (e) {
      // Hardware / timeout error - treat as GPS lost (Outcome C), not out-of-radius
      _state = BreachState.gpsDisabled;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  void _startWarningCountdown(Position pos) {
    _state = BreachState.warning;
    _breachStartTime = DateTime.now();

    // Default 120s if not set
    if (_countdownSeconds <= 0) {
      _countdownSeconds = 120;
    }

    // Inform backend of breach start timestamp
    ApiService.recordBreachWarning(breachedAt: _breachStartTime);

    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }

      if (_countdownSeconds > 0) {
        _countdownSeconds--;
        notifyListeners();
      } else {
        // Countdown reached 0: execute retry check
        timer.cancel();
        _executeRetryCheck();
      }
    });
  }

  void _cancelWarning() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _state = BreachState.normal;
    _breachStartTime = null;
    _countdownSeconds = 120;
    notifyListeners();
  }

  Future<void> _executeRetryCheck() async {
    final office = ApiService.assignedOffice;
    if (office == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        office.latitude,
        office.longitude,
      );

      _lastDistanceMeters = distance;

      if (distance <= office.radiusMeters) {
        // Outcome A: Successfully moved back inside radius
        _cancelWarning();
      } else {
        // Outcome B: Still outside after 2 minutes -> FORCE CHECKOUT!
        await _performForceCheckout(position);
      }
    } catch (_) {
      // If location couldn't be fetched on retry, attempt force checkout with last known breach
      // Or if GPS is off, outcome C
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _state = BreachState.gpsDisabled;
        notifyListeners();
      } else {
        // Fallback retry using default position if possible
        try {
          final lastPos = await Geolocator.getLastKnownPosition();
          if (lastPos != null) {
            await _performForceCheckout(lastPos);
          }
        } catch (_) {}
      }
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
