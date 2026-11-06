import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const String _prefDeviceId = 'app_persistent_device_id';
  static const String _prefDeviceModel = 'app_persistent_device_model';
  static const MethodChannel _hardwareChannel =
      MethodChannel('com.brandhrms.device/hardware_id');

  /// Retrieves a permanent hardware identifier and device model
  static Future<Map<String, String>> getDeviceDetails() async {
    try {
      String? hardwareId;
      String? deviceModel;

      if (Platform.isAndroid) {
        // 1. Fetch permanent Android Hardware ID (MediaDrm Widevine or Settings.Secure.ANDROID_ID)
        try {
          final nativeId =
              await _hardwareChannel.invokeMethod<String>('getHardwareId');
          if (nativeId != null && nativeId.trim().isNotEmpty) {
            hardwareId = nativeId.trim();
          }
        } catch (_) {}

        // 2. Fetch real device brand and model via device_info_plus
        try {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          final manufacturer = androidInfo.manufacturer.trim();
          final model = androidInfo.model.trim();

          if (manufacturer.isNotEmpty && model.isNotEmpty) {
            deviceModel = manufacturer.toLowerCase() == model.toLowerCase()
                ? model
                : '$manufacturer $model';
          } else if (model.isNotEmpty) {
            deviceModel = model;
          } else {
            deviceModel = 'Android Phone';
          }

          // Fallback to deterministic physical hardware fingerprint if native channel failed
          if (hardwareId == null || hardwareId.isEmpty) {
            final rawHardware =
                '${androidInfo.brand}_${androidInfo.model}_${androidInfo.hardware}_${androidInfo.board}_${androidInfo.fingerprint}_${androidInfo.id}';
            hardwareId = _generateDeterministicHardwareId(rawHardware);
          }
        } catch (_) {}
      } else if (Platform.isIOS) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final iosInfo = await deviceInfo.iosInfo;
          hardwareId = iosInfo.identifierForVendor;
          deviceModel = iosInfo.name.isNotEmpty ? iosInfo.name : 'iPhone';
        } catch (_) {}
      }

      // If hardware ID successfully resolved, cache and return it
      if (hardwareId != null && hardwareId.isNotEmpty) {
        deviceModel ??= Platform.isAndroid ? 'Android Phone' : 'Mobile Device';
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefDeviceId, hardwareId);
          await prefs.setString(_prefDeviceModel, deviceModel);
        } catch (_) {}

        return {
          'device_id': hardwareId,
          'device_model': deviceModel,
        };
      }

      // Fallback for emulator or desktop platforms: Use cached ID or deterministic host fingerprint
      final prefs = await SharedPreferences.getInstance();
      String? cachedId = prefs.getString(_prefDeviceId);
      String? cachedModel = prefs.getString(_prefDeviceModel);

      if (cachedId == null || cachedId.isEmpty) {
        cachedId = _generateDeterministicHardwareId(
            '${Platform.operatingSystem}_${Platform.localHostname}_static_dev');
        await prefs.setString(_prefDeviceId, cachedId);
      }
      cachedModel ??= Platform.operatingSystem;

      return {
        'device_id': cachedId,
        'device_model': cachedModel,
      };
    } catch (_) {
      return {
        'device_id': 'fallback_device_token',
        'device_model': 'Mobile Device',
      };
    }
  }

  /// Pure Dart 64-bit FNV-1a dual-pass deterministic hash (produces 32-char hex string)
  /// Always returns the exact same string for the same physical hardware components, even after reinstall.
  static String _generateDeterministicHardwareId(String raw) {
    if (raw.isEmpty) return 'dev_fallback_hardware_token';
    var h1 = 0xcbf29ce484222325;
    const p1 = 0x100000001b3;
    for (var cu in raw.codeUnits) {
      h1 ^= cu;
      h1 = (h1 * p1) & 0xFFFFFFFFFFFFFFFF;
    }
    var h2 = 0x84222325cbf29ce4;
    const p2 = 0x100000001b3;
    for (var cu in raw.codeUnits.reversed) {
      h2 ^= cu;
      h2 = (h2 * p2) & 0xFFFFFFFFFFFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(16, '0')}${h2.toRadixString(16).padLeft(16, '0')}';
  }
}
