import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages local employee avatar profile picture selection, persistence, and removal.
class AvatarService extends ChangeNotifier {
  static final AvatarService instance = AvatarService._internal();
  AvatarService._internal();

  static const String _prefAvatarPrefix = 'employee_avatar_path_';
  static const String _prefLastAvatar = 'last_active_avatar_path';

  String? _avatarPath;
  String? get avatarPath => _avatarPath;

  /// Returns true if a custom profile picture is currently set and the file exists.
  bool get hasCustomAvatar =>
      _avatarPath != null && _avatarPath!.isNotEmpty && File(_avatarPath!).existsSync();

  /// Loads the profile picture for the active employee.
  Future<void> init([String? employeeId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedPath;
      if (employeeId != null && employeeId.isNotEmpty) {
        savedPath = prefs.getString('$_prefAvatarPrefix$employeeId');
      }
      savedPath ??= prefs.getString(_prefLastAvatar);

      if (savedPath != null && savedPath.isNotEmpty && File(savedPath).existsSync()) {
        _avatarPath = savedPath;
      } else {
        _avatarPath = null;
      }
      notifyListeners();
    } catch (_) {}
  }

  /// Opens the device file picker to select a profile image (.jpg, .jpeg, .png, .webp).
  Future<bool> pickAndSaveAvatar(String? employeeId) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (file != null && file.path != null) {
        final pickedPath = file.path!;
        if (File(pickedPath).existsSync()) {
          _avatarPath = pickedPath;
          notifyListeners();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefLastAvatar, pickedPath);
          if (employeeId != null && employeeId.isNotEmpty) {
            await prefs.setString('$_prefAvatarPrefix$employeeId', pickedPath);
          }
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Removes the custom avatar and reverts back to the initial letter badge.
  Future<void> removeAvatar(String? employeeId) async {
    try {
      _avatarPath = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefLastAvatar);
      if (employeeId != null && employeeId.isNotEmpty) {
        await prefs.remove('$_prefAvatarPrefix$employeeId');
      }
    } catch (_) {}
  }
}

