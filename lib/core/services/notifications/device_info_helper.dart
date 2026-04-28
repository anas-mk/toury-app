import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable per-install identifiers used by `/notifications/devices`.
class DeviceInfoHelper {
  static const _kDeviceIdKey = 'install.deviceId';

  final SharedPreferences prefs;
  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  DeviceInfoHelper(this.prefs);

  /// Returns a stable deviceId for this install.
  ///
  /// Strategy:
  ///   1. Prefer the value cached in SharedPreferences (survives FCM token
  ///      rotation and app restarts — never regenerate on every boot).
  ///   2. On first launch: iOS uses `identifierForVendor` when available;
  ///      Android uses a fingerprint-based key (no per-boot UUID);
  ///      Web / fallback uses a random v4 UUID persisted once.
  Future<String> getDeviceId() async {
    final cached = prefs.getString(_kDeviceIdKey);
    if (cached != null && cached.isNotEmpty) return cached;

    String? candidate;
    try {
      if (!kIsWeb && Platform.isIOS) {
        final info = await _plugin.iosInfo;
        candidate = info.identifierForVendor;
      } else if (!kIsWeb && Platform.isAndroid) {
        final a = await _plugin.androidInfo;
        candidate =
            '${a.brand}_${a.device}_${a.fingerprint}'.hashCode.toRadixString(16);
      }
    } catch (e) {
      debugPrint('⚠️ DeviceInfoHelper.getDeviceId: $e');
    }

    final id = (candidate != null && candidate.isNotEmpty)
        ? candidate
        : const Uuid().v4();
    await prefs.setString(_kDeviceIdKey, id);
    return id;
  }

  /// `"Android"` | `"iOS"` | `"Web"` — matches the backend contract.
  String get platform {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  /// Best-effort device model label, e.g. `"Pixel 8 (Android 14)"`. Used by
  /// the backend for human-readable device lists. We never crash if the
  /// device info plugin throws — we just return `null`.
  Future<String?> getDeviceLabel() async {
    try {
      if (kIsWeb) return 'Web client';
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        return '${info.manufacturer} ${info.model} (Android ${info.version.release})';
      }
      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        return '${info.utsname.machine} (iOS ${info.systemVersion})';
      }
    } catch (e) {
      debugPrint('⚠️ DeviceInfoHelper: $e');
    }
    return null;
  }
}
