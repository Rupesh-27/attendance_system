import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const String _prefDeviceId = 'app_persistent_device_id';
  static const String _prefDeviceModel = 'app_persistent_device_model';

  /// Retrieves or generates a persistent hardware identifier for this device
  static Future<Map<String, String>> getDeviceDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_prefDeviceId);
      String? deviceModel = prefs.getString(_prefDeviceModel);

      if (deviceId == null || deviceId.isEmpty) {
        // Generate a cryptographically secure 128-bit persistent device token
        final random = Random.secure();
        final values = List<int>.generate(16, (i) => random.nextInt(256));
        deviceId = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        await prefs.setString(_prefDeviceId, deviceId);
      }

      if (deviceModel == null || deviceModel.isEmpty) {
        final os = Platform.isAndroid
            ? 'Android Phone'
            : (Platform.isIOS ? 'iPhone' : Platform.operatingSystem);
        deviceModel = os;
        await prefs.setString(_prefDeviceModel, deviceModel);
      }

      return {
        'device_id': deviceId,
        'device_model': deviceModel,
      };
    } catch (_) {
      return {
        'device_id': 'fallback_device_token',
        'device_model': 'Mobile Device',
      };
    }
  }
}

