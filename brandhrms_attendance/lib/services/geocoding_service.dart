import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class GeocodingService {
  /// Converts latitude & longitude into a clean, human-readable address string.
  /// Example outputs:
  /// - "Friedrichstraße, Mitte, Berlin, Germany"
  /// - "Anna Nagar, Chennai, Tamil Nadu, India"
  /// If geocoding fails (e.g. offline, timeout, or location not indexed),
  /// it gracefully returns an empty string without throwing or blocking check-in.
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 4), onTimeout: () => <Placemark>[]);

      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        final List<String> parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ]
            .where((s) => s != null && s.trim().isNotEmpty)
            .map((s) => s!.trim())
            .toSet()
            .toList();

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (e) {
      debugPrint('GeocodingService.getAddressFromCoordinates error: $e');
    }
    return '';
  }
}
