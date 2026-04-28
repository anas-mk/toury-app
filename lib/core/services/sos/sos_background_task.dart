import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

class SosBackgroundTask {
  SosBackgroundTask._();

  static const String activeSosPrefsKey = 'active_sos_v1';
  static const String authTokenPrefsKey = 'token';
  static const String channelId = 'rafiq_default';
  static const String channelName = 'Toury notifications';
  static const String channelDescription =
      'Booking, payment, chat, and SOS notifications';
  static const int notificationId = 12221;
  static const Duration tickInterval = Duration(seconds: 2);
  static const Duration requestTimeout = Duration(seconds: 5);
  static const Duration maxStreamingDuration = Duration(hours: 4);
  static const String activeTitle = 'SOS Active';
  static const String activeBody =
      'Sharing your live location with our safety team';
  static const String pausedBody =
      'SOS still active - location streaming paused';

  static Future<bool> configure() async {
    final service = FlutterBackgroundService();
    return service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: channelId,
        initialNotificationTitle: activeTitle,
        initialNotificationContent: activeBody,
        foregroundServiceNotificationId: notificationId,
        foregroundServiceTypes: const [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        // TODO(ios-sos): add iOS background mode + handler wiring.
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final active = _readActiveSosState(prefs);
    if (active == null) {
      _log('[SOS bg] stopping reason=missing-active-state');
      service.invoke('sos.stop', {'reason': 'missing-active-state'});
      service.stopSelf();
      return;
    }

    final token = prefs.getString(authTokenPrefsKey)?.trim();
    if (token == null || token.isEmpty) {
      _log('[SOS bg] stopping reason=missing-auth-token');
      service.invoke('sos.stop', {'reason': 'missing-auth-token'});
      service.stopSelf();
      return;
    }

    final localNotifications = FlutterLocalNotificationsPlugin();
    await _ensureNotificationChannel(localNotifications);
    await _updateForegroundNotification(
      service: service,
      notifications: localNotifications,
      bookingId: active.bookingId,
      sosId: active.sosId,
      body: activeBody,
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: requestTimeout,
        receiveTimeout: requestTimeout,
        sendTimeout: requestTimeout,
        headers: {
          ...ApiConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    Timer? timer;
    var seq = 0;
    var inFlight = false;
    var stopped = false;
    var pausedByCap = false;

    Future<void> stopNow(
      String reason, {
      Map<String, dynamic>? event,
      bool emitToUi = false,
    }) async {
      if (stopped) return;
      stopped = true;
      timer?.cancel();
      if (emitToUi) {
        service.invoke('sos.stop', {'reason': reason, ...?event});
      }
      service.stopSelf();
    }

    service.on('cancel').listen((event) {
      final reason = event?['reason']?.toString() ?? 'cancelled';
      _log('[SOS bg] stopping reason=$reason');
      unawaited(stopNow(reason));
    });

    service.on('stopService').listen((_) {
      _log('[SOS bg] stopping reason=stopService');
      unawaited(stopNow('stopService'));
    });

    timer = Timer.periodic(tickInterval, (_) async {
      if (stopped || inFlight) return;
      inFlight = true;
      try {
        final elapsed = DateTime.now().toUtc().difference(active.startedAtUtc);
        if (elapsed > maxStreamingDuration) {
          if (!pausedByCap) {
            pausedByCap = true;
            _log('[SOS bg] paused reason=cap-exceeded');
            await _updateForegroundNotification(
              service: service,
              notifications: localNotifications,
              bookingId: active.bookingId,
              sosId: active.sosId,
              body: pausedBody,
            );
          }
          return;
        }

        Position position;
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: requestTimeout,
            ),
          );
        } catch (e) {
          _log('[SOS bg] tick.fail reason=gps-error error=$e');
          return;
        }

        seq += 1;
        final body = <String, dynamic>{
          'latitude': position.latitude,
          'longitude': position.longitude,
          if (position.accuracy.isFinite) 'accuracyMeters': position.accuracy,
          'source': 'user_sos',
        };

        try {
          final response = await dio.post(
            ApiConfig.postSosLocation(active.sosId),
            data: body,
            options: Options(
              sendTimeout: requestTimeout,
              receiveTimeout: requestTimeout,
            ),
          );
          final code = response.statusCode ?? 0;
          if (code >= 200 && code < 300) {
            _log(
              '[SOS bg] tick.ok seq=$seq lat=${position.latitude.toStringAsFixed(6)} '
              'lng=${position.longitude.toStringAsFixed(6)}',
            );
            return;
          }

          if (code == 400 || code == 404 || code == 410) {
            final rawBody = response.data?.toString() ?? '';
            _log('[SOS bg] stopping reason=4xx code=$code body=$rawBody');
            // TODO(test): 4xx-stop path needs a proper integration test.
            await stopNow(
              '4xx',
              emitToUi: true,
              event: {'code': code, 'body': rawBody},
            );
            return;
          }

          _log('[SOS bg] tick.fail reason=http-$code');
        } on DioException catch (e) {
          final code = e.response?.statusCode ?? 0;
          if (code == 400 || code == 404 || code == 410) {
            final rawBody = e.response?.data?.toString() ?? e.message ?? '';
            _log('[SOS bg] stopping reason=4xx code=$code body=$rawBody');
            // TODO(test): 4xx-stop path needs a proper integration test.
            await stopNow(
              '4xx',
              emitToUi: true,
              event: {'code': code, 'body': rawBody},
            );
            return;
          }
          _log('[SOS bg] tick.fail reason=${e.type} code=$code');
        } catch (e) {
          _log('[SOS bg] tick.fail reason=exception error=$e');
        }
      } catch (e) {
        _log('[SOS bg] tick.fail reason=unexpected error=$e');
      } finally {
        inFlight = false;
      }
    });
  }

  static _BgActiveSosState? _readActiveSosState(SharedPreferences prefs) {
    final raw = prefs.getString(activeSosPrefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final sosId = map['sosId']?.toString() ?? '';
      final bookingId = map['bookingId']?.toString() ?? '';
      final startedAtRaw = map['startedAt']?.toString() ?? '';
      final startedAt =
          DateTime.tryParse(startedAtRaw)?.toUtc() ?? DateTime.now().toUtc();
      if (sosId.isEmpty || bookingId.isEmpty) return null;
      return _BgActiveSosState(
        sosId: sosId,
        bookingId: bookingId,
        startedAtUtc: startedAt,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _ensureNotificationChannel(
    FlutterLocalNotificationsPlugin notifications,
  ) async {
    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
      enableLights: true,
    );
    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _updateForegroundNotification({
    required ServiceInstance service,
    required FlutterLocalNotificationsPlugin notifications,
    required String bookingId,
    required String sosId,
    required String body,
  }) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(title: activeTitle, content: body);
    }

    const android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: 'ic_stat_notify',
      color: Color(0xFF276EF1),
      visibility: NotificationVisibility.public,
      playSound: false,
      enableVibration: false,
      showWhen: true,
    );
    await notifications.show(
      id: notificationId,
      title: activeTitle,
      body: body,
      notificationDetails: const NotificationDetails(android: android),
      payload: _encodePayload({
        'notificationType': 'TripStarted',
        'bookingId': bookingId,
        'eventId': 'sos-bg-$sosId',
        'source': 'sos-background-service',
      }),
    );
  }

  static String _encodePayload(Map<String, dynamic> data) {
    final buf = StringBuffer();
    data.forEach((k, v) {
      buf.write(k);
      buf.write('\x01');
      buf.write(v?.toString() ?? '');
      buf.write('\x02');
    });
    return buf.toString();
  }

  static void _log(String message) {
    debugPrint(message);
  }
}

class _BgActiveSosState {
  const _BgActiveSosState({
    required this.sosId,
    required this.bookingId,
    required this.startedAtUtc,
  });

  final String sosId;
  final String bookingId;
  final DateTime startedAtUtc;
}
