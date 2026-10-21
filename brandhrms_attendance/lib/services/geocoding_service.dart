import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class GeocodingService {
  /// Converts latitude & longitude into a clean, human-readable address string.
  /// If [cityDistrictStateCountryOnly] is true, returns City, District, State, and Country.
  /// Example outputs:
  /// - "Friedrichstraße, Mitte, Berlin, Germany"
  /// - "Anna Nagar, Chennai, Tamil Nadu, India"
  /// If geocoding fails (e.g. offline, timeout, or location not indexed),
  /// it gracefully returns an empty string without throwing or blocking check-in.
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude, {
    bool cityDistrictStateCountryOnly = false,
  }) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      ).timeout(const Duration(seconds: 4), onTimeout: () => <Placemark>[]);

      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;

        if (cityDistrictStateCountryOnly) {
          final List<String> parts = [
            p.locality,             // City
            p.subAdministrativeArea,// District
            p.administrativeArea,   // State
            p.country,              // Country
          ]
              .where((s) => s != null && s.trim().isNotEmpty)
              .map((s) => s!.trim())
              .toSet()
              .toList();

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }

        final List<String> parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
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

  /// Formats any address into City, District, State, and Country
  static String formatCityDistrictStateCountry(String rawAddress) {
    if (rawAddress.trim().isEmpty) return '';
    final parts = rawAddress
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length <= 4) {
      return parts.join(', ');
    }
    // Return the last 4 segments (City, District, State, Country)
    return parts.sublist(parts.length - 4).join(', ');
  }
}
