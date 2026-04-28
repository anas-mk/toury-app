import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/api_config.dart';
import '../realtime/realtime_logger.dart';
import 'device_info_helper.dart';

/// Wraps `/notifications/devices` (register / unregister / unregister-all).
///
/// Lifecycle:
///   - Call [registerCurrentDevice] right after a successful login.
///   - Call [unregisterCurrentDevice] right before logout.
///   - The service auto-listens for FCM token rotations and re-registers.
///
/// On platforms where Firebase is not configured natively (e.g. desktop),
/// every method is a no-op and logs a warning instead of crashing the app.
class DeviceTokenService {
  final Dio dio;
  final DeviceInfoHelper deviceInfo;

  StreamSubscription<String>? _tokenRefreshSub;
  String? _lastRegisteredToken;

  DeviceTokenService({
    required this.dio,
    required this.deviceInfo,
  });

  /// Requests notification permission, fetches the FCM token and POSTs it.
  Future<void> registerCurrentDevice() async {
    if (!_supportsFirebase()) {
      debugPrint('🔕 DeviceTokenService: platform unsupported, skipping');
      return;
    }
    try {
      await _requestPermission();
      final fcmToken = await _safeGetToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ DeviceTokenService: empty FCM token');
        return;
      }
      await _postRegister(fcmToken);
      _attachTokenRefreshListener();
    } catch (e, st) {
      debugPrint('💥 DeviceTokenService.register failed: $e\n$st');
    }
  }

  /// DELETEs the current device from `/notifications/devices`.
  ///
  /// Called BEFORE the auth token is cleared, otherwise the call would 401.
  Future<void> unregisterCurrentDevice() async {
    if (!_supportsFirebase()) return;
    final token = _lastRegisteredToken ?? await _safeGetToken();
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    if (token == null || token.isEmpty) {
      debugPrint('⚠️ DeviceTokenService: no FCM token to unregister');
      return;
    }
    try {
      await dio.delete(ApiConfig.unregisterDevice(token));
      debugPrint('✅ Unregistered FCM token');
      _lastRegisteredToken = null;
    } catch (e) {
      debugPrint('⚠️ DeviceTokenService.unregister failed: $e');
    }
  }

  /// DELETEs every device for the current user (used by "Sign out everywhere").
  Future<void> unregisterAllDevices() async {
    try {
      await dio.delete(ApiConfig.unregisterAllDevices);
      _lastRegisteredToken = null;
    } catch (e) {
      debugPrint('⚠️ DeviceTokenService.unregisterAll failed: $e');
    }
  }

  /// Hits the dev-only `POST /notifications/devices/test` endpoint so the
  /// server pushes a test FCM payload back to this device. Used by the
  /// `/dev/realtime` diagnostics page to verify the entire push pipeline.
  Future<void> sendTestPushToSelf() async {
    try {
      debugPrint('🧪 POST ${ApiConfig.testDevicePush}');
      await dio.post(ApiConfig.testDevicePush);
      debugPrint('✅ Test push requested');
    } catch (e) {
      debugPrint('⚠️ DeviceTokenService.sendTestPushToSelf failed: $e');
      rethrow;
    }
  }

  /// Last token we POSTed to `/notifications/devices`. `null` until the
  /// first successful registration (used by the diagnostics page).
  String? get lastRegisteredToken => _lastRegisteredToken;

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _postRegister(String fcmToken) async {
    final deviceId = await deviceInfo.getDeviceId();
    final appVersion = await _appVersion();

    final body = <String, dynamic>{
      'fcmToken': fcmToken,
      'deviceId': deviceId,
      'appType': 'UserApp',
      'platform': deviceInfo.platform,
      'appVersion': appVersion,
    };

    RealtimeLogger.instance.log(
      'FCM',
      'register.http',
      'POST ${ApiConfig.registerDevice} fcmToken=…${fcmToken.substring(fcmToken.length - 10)} deviceId=$deviceId',
    );
    await dio.post(ApiConfig.registerDevice, data: body);
    _lastRegisteredToken = fcmToken;
    RealtimeLogger.instance.log('FCM', 'register.ok', 'device registered');
  }

  void _attachTokenRefreshListener() {
    _tokenRefreshSub?.cancel();
    try {
      _tokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM token refreshed → re-registering');
        try {
          if (_lastRegisteredToken != null &&
              _lastRegisteredToken != newToken) {
            await dio.delete(
              ApiConfig.unregisterDevice(_lastRegisteredToken!),
            );
          }
          await _postRegister(newToken);
        } catch (e) {
          debugPrint('⚠️ FCM refresh re-register failed: $e');
        }
      });
    } catch (e) {
      debugPrint('⚠️ FCM onTokenRefresh unavailable: $e');
    }
  }

  Future<String?> _safeGetToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('⚠️ FirebaseMessaging.getToken failed: $e');
      return null;
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔔 FCM permission: ${settings.authorizationStatus}');
      if (Platform.isAndroid) {
        // Android 13+ also surfaces a runtime permission for notifications.
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('⚠️ FCM requestPermission failed: $e');
    }
  }

  bool _supportsFirebase() =>
      kIsWeb || Platform.isAndroid || Platform.isIOS;

  Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return '1.0.0+1';
    }
  }
}
