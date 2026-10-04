import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';

class LocationVerificationScreen extends StatefulWidget {
  final bool isCheckOut;

  const LocationVerificationScreen({
    super.key,
    this.isCheckOut = false,
  });

  @override
  State<LocationVerificationScreen> createState() =>
      _LocationVerificationScreenState();
}

class _LocationVerificationScreenState
    extends State<LocationVerificationScreen> {
  static const Color primaryColor = Color(0xFF0F9D8A);

  String locationStatus = 'Location not checked';
  String locationDetails = 'Tap the button to verify your location and submit attendance.';
  bool isChecking = false;
  bool isSuccess = false;

  Future<void> verifyLocation() async {
    if (isChecking) {
      return;
    }

    setState(() {
      isChecking = true;
      locationStatus = 'Acquiring GPS location...';
      locationDetails = 'Please wait while we get high-precision coordinates from your device.';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          locationStatus = 'Location service is disabled';
          locationDetails = 'Please turn on Location/GPS and try again.';
          isChecking = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          locationStatus = 'Location permission denied';
          locationDetails = 'Allow location permission and try again.';
          isChecking = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationStatus = 'Location permission blocked';
          locationDetails =
              'Please enable location permission in phone settings.';
          isChecking = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        locationStatus = 'Verifying with office geofence...';
        locationDetails =
            'Coordinates: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}\n'
            'Accuracy: ±${position.accuracy.toStringAsFixed(1)}m\n'
            'Validating with backend server...';
      });

      // Submit coordinates to backend
      final result = widget.isCheckOut
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

      if (!mounted) return;

      if (result['success'] == true) {
        final serverTime = result['serverTime']?.toString() ?? '';
        String formattedTime = serverTime;
        try {
          final dt = DateTime.parse(serverTime).toLocal();
          final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
          final period = dt.hour >= 12 ? 'PM' : 'AM';
          formattedTime = '$hour:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} $period';
        } catch (_) {}

        final distance = result['distanceMeters'] ?? 0.0;
        final allowedRadius = result['allowedRadiusMeters'] ?? 10.0;

        setState(() {
          isSuccess = true;
          locationStatus = 'Available';
          locationDetails =
              'Status: ${result['status']}\n'
              'Distance to Office: ${distance.toString()} m\n'
              'Allowed Radius: ${allowedRadius.toString()} m\n'
              'Server Timestamp: $formattedTime';
          isChecking = false;
        });

        _showSuccessDialog(
          status: result['status']?.toString() ?? 'SUCCESS',
          serverTime: formattedTime,
          distance: distance.toString(),
          radius: allowedRadius.toString(),
        );
      } else {
        setState(() {
          locationStatus = 'Unavailable';
          locationDetails = result['message'] ?? 'Location verification failed.';
          isChecking = false;
        });

        _showErrorDialog(result['message'] ?? 'Could not record attendance.');
      }
    } catch (e) {
      setState(() {
        locationStatus = 'Unable to get location';
        locationDetails =
            'Please check your GPS and network connection, then retry.\nError: $e';
        isChecking = false;
      });
    }
  }

  void _showSuccessDialog({
    required String status,
    required String serverTime,
    required String distance,
    required String radius,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Text(
              widget.isCheckOut ? 'Checked Out' : 'Checked In',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isCheckOut
                  ? 'Your check-out has been verified and recorded.'
                  : 'Your check-in has been verified and recorded.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            _dialogRow('Status', status),
            const SizedBox(height: 8),
            _dialogRow('Server Time', serverTime),
            const SizedBox(height: 8),
            _dialogRow('Distance to Office', '$distance m'),
            const SizedBox(height: 8),
            _dialogRow('Office Geofence', '$radius m'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context, true); // Return to dashboard with success
            },
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Verification Failed', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.grey.shade800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final officeName = ApiService.assignedOffice?.name ?? 'BrandCrock Office';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.isCheckOut ? 'Check Out Verification' : 'Location Verification',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (isSuccess ? Colors.green : primaryColor).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess
                    ? Icons.check_circle
                    : (widget.isCheckOut ? Icons.logout : Icons.location_on),
                size: 55,
                color: isSuccess ? Colors.green : primaryColor,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              widget.isCheckOut ? 'Verify Your Check-Out' : 'Verify Your Location',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              widget.isCheckOut
                  ? 'We need your current location to verify that you are checking out within your assigned office.'
                  : 'We need your current location to verify whether you are at your assigned office.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 28),

            _infoCard(
              icon: Icons.business,
              title: 'Assigned Office',
              value: officeName,
            ),

            const SizedBox(height: 14),

            _infoCard(
              icon: isSuccess ? Icons.verified : Icons.gps_fixed,
              title: 'Location Status',
              value: locationStatus,
              valueColor: isSuccess ? Colors.green : (locationStatus.contains('Failed') ? Colors.red : null),
            ),

            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle_outline : Icons.info_outline,
                    color: isSuccess ? Colors.green : primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      locationDetails,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: isChecking ? null : verifyLocation,
                icon: isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(widget.isCheckOut ? Icons.logout : Icons.my_location),
                label: Text(
                  isChecking
                      ? 'Verifying Location...'
                      : (widget.isCheckOut ? 'Verify & Check Out' : 'Verify & Check In'),
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.isCheckOut ? Colors.orange.shade800 : primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security, color: primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your location is securely verified against your office geofence radius for attendance records.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
