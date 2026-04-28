import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../realtime/booking_realtime_event_bus.dart';
import '../realtime/event_dedup_cache.dart';
import '../realtime/realtime_logger.dart';
import 'device_token_service.dart';
import 'notification_router.dart';

/// Coordinates everything FCM-related for the user app:
///
///   1. Permission requests (iOS provisional, Android 13+ POST_NOTIFICATIONS).
///   2. APNS-token wait + FCM-token acquisition.
///   3. Device-token registration with the backend (delegated to
///      [DeviceTokenService]).
///   4. Foreground heads-up notifications via [FlutterLocalNotificationsPlugin]
///      (so the user sees the push even when the app is in front).
///   5. Tap routing (foreground / background / cold-start) via
///      [NotificationRouter].
///   6. Dedup against SignalR using `eventId` from the data payload.
///
/// Does NOT own any backend HTTP call beyond what [DeviceTokenService]
/// already does.
class MessagingService {
  MessagingService({required this.deviceTokenService});

  final DeviceTokenService deviceTokenService;

  static const String _androidChannelId = 'rafiq_default';
  static const String _androidChannelName = 'Toury notifications';
  static const String _androidChannelDescription =
      'Booking, payment, chat, and SOS notifications';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;
  bool _started = false;
  String? _lastFcmToken;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  String? get lastFcmToken => _lastFcmToken;
  String get deviceIdSync => '—';

  Future<void> initialise() async {
    if (_initialised) return;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (resp) {
          _handleLocalNotificationTap(resp);
        },
      );

      if (!kIsWeb && Platform.isAndroid) {
        // High-importance channel ↔ heads-up + sound + lock-screen body.
        // MUST stay in sync with the channel id referenced by
        // AndroidManifest's `default_notification_channel_id` meta-data,
        // otherwise OS-rendered FCM pushes fall back to a low-importance
        // system channel (silent, no heads-up). Lock-screen visibility is
        // configured per-notification via AndroidNotificationDetails.visibility
        // below — the channel itself doesn't expose that field in
        // flutter_local_notifications v21.
        const channel = AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: _androidChannelDescription,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
          showBadge: true,
          enableLights: true,
          ledColor: Color(0xFF276EF1),
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
      }

      _initialised = true;
      RealtimeLogger.instance.log('FCM', 'init', 'local-notifications ready');
    } catch (e, st) {
      RealtimeLogger.instance.log(
        'FCM',
        'init.error',
        '$e\n$st',
        isError: true,
      );
    }
  }

  Future<void> start() async {
    if (_started) return;
    if (!_isFirebaseSupported()) {
      RealtimeLogger.instance.log('FCM', 'start.skip', 'platform unsupported');
      return;
    }
    if (!_isFirebaseReady()) {
      // Firebase.initializeApp() failed in main() (usually because
      // google-services.json / GoogleService-Info.plist is missing). Calling
      // FirebaseMessaging.instance here would just throw the same native
      // error every time. Skip with a clear log instead.
      RealtimeLogger.instance.log(
        'FCM',
        'start.skip',
        'Firebase not initialized — push notifications disabled',
        isError: true,
      );
      return;
    }
    await initialise();

    try {
      await _requestPermissions();
      await _waitForApnsTokenIfIos();

      final token = await _safeGetToken();
      if (token != null && token.isNotEmpty) {
        _lastFcmToken = token;
        RealtimeLogger.instance.log(
          'FCM',
          'token',
          '…${token.substring(token.length - 10)}',
        );
        await deviceTokenService.registerCurrentDevice();
      } else {
        RealtimeLogger.instance.log(
          'FCM',
          'token.empty',
          'getToken returned null/empty',
          isError: true,
        );
      }

      _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      _onMessageOpenedAppSub?.cancel();
      _onMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
        _onMessageOpenedApp,
      );

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _onMessageOpenedApp(initialMessage);
      }

      await _onTokenRefreshSub?.cancel();
      _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
        newToken,
      ) async {
        _lastFcmToken = newToken;
        RealtimeLogger.instance.log(
          'FCM',
          'token.refresh',
          '…${newToken.substring(newToken.length - 10)}',
        );
        try {
          await deviceTokenService.registerCurrentDevice();
        } catch (e, st) {
          RealtimeLogger.instance.log(
            'FCM',
            'token.refresh.register',
            '$e\n$st',
            isError: true,
          );
        }
      });

      _started = true;
      RealtimeLogger.instance.log('FCM', 'start', 'subscribed to FCM streams');
    } catch (e, st) {
      RealtimeLogger.instance.log(
        'FCM',
        'start.error',
        '$e\n$st',
        isError: true,
      );
    }
  }

  Future<void> stop() async {
    await _onMessageSub?.cancel();
    _onMessageSub = null;
    await _onMessageOpenedAppSub?.cancel();
    _onMessageOpenedAppSub = null;
    await _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = null;
    try {
      await deviceTokenService.unregisterCurrentDevice();
    } catch (e) {
      RealtimeLogger.instance.log(
        'FCM',
        'unregister.error',
        '$e',
        isError: true,
      );
    }
    _started = false;
    RealtimeLogger.instance.log('FCM', 'stop', 'detached from FCM streams');
  }

  Future<void> sendTestPush() async {
    await deviceTokenService.sendTestPushToSelf();
  }

  void _onForegroundMessage(RemoteMessage message) {
    final data = _stringifyData(message.data);
    final eventId = message.data['eventId']?.toString();
    RealtimeLogger.instance.log(
      'FCM',
      'foreground',
      'data=${message.data} notification=${message.notification?.title}',
      eventId: eventId,
    );
    if (data['notificationType'] == 'Test') {
      _postFrameSnackFromRoot('Test push (dev)');
      if (eventId != null && eventId.isNotEmpty) {
        EventDedupCache.instance.mark(eventId);
      }
      return;
    }
    final isDup = EventDedupCache.instance.contains(eventId);
    _showHeadsUp(message, isDuplicate: isDup);
    if (!isDup && eventId != null && eventId.isNotEmpty) {
      EventDedupCache.instance.mark(eventId);
    }
  }

  void showInAppBanner(
    String title,
    String body, [
    Map<String, dynamic>? data,
  ]) {
    final line = title.isEmpty
        ? body
        : (body.isEmpty ? title : '$title: $body');
    _postFrameSnackFromRoot(line);
  }

  void maybeInAppBannerFromBusEvent(BookingRealtimeBusEvent e) {
    late final String eventId;
    String title = 'Rafiq';
    String body = '';
    if (e is BusBookingStatusChanged) {
      if (e.event.newStatus != 'Confirmed') return;
      eventId = e.event.eventId;
      title = 'Booking update';
      body = e.event.newStatus;
    } else if (e is BusBookingTripStarted) {
      eventId = e.event.eventId;
      title = 'Trip started';
      body = 'Your trip is underway.';
    } else if (e is BusBookingTripEnded) {
      eventId = e.event.eventId;
      title = 'Trip ended';
      body = 'Time to complete payment.';
    } else if (e is BusBookingPaymentChanged) {
      eventId = e.event.eventId;
      title = 'Payment';
      body = e.event.status;
    } else {
      return;
    }
    if (eventId.isNotEmpty && EventDedupCache.instance.contains(eventId)) {
      return;
    }
    showInAppBanner(title, body);
  }

  void _postFrameSnackFromRoot(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = NotificationRouter.instance.navigatorContext;
      if (ctx == null || !ctx.mounted) return;
      ScaffoldMessenger.maybeOf(
        ctx,
      )?.showSnackBar(SnackBar(content: Text(text)));
    });
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final data = _stringifyData(message.data);
    final eventId = data['eventId'];
    RealtimeLogger.instance.log(
      'FCM',
      'onTap',
      'type=${data['notificationType']}',
      eventId: eventId,
    );
    NotificationRouter.instance.routeFromData(data, reason: 'fcm-tap');
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final data = _decodePayload(payload);
    if (data == null) return;
    RealtimeLogger.instance.log(
      'FCM',
      'localTap',
      'type=${data['notificationType']}',
      eventId: data['eventId'],
    );
    NotificationRouter.instance.routeFromData(data, reason: 'local-tap');
  }

  Future<void> _showHeadsUp(
    RemoteMessage message, {
    required bool isDuplicate,
  }) async {
    void markEvent() {
      final eid = message.data['eventId']?.toString();
      EventDedupCache.instance.mark(eid);
    }

    final notif = message.notification;
    if (notif == null) {
      final type = message.data['notificationType']?.toString() ?? 'Toury';
      if (!isDuplicate) {
        await _postLocal(
          id: message.hashCode & 0x7FFFFFFF,
          title: type,
          body: message.data['preview']?.toString() ?? '',
          payload: _encodePayload(message.data),
        );
        markEvent();
      }
      return;
    }
    if (isDuplicate) {
      RealtimeLogger.instance.log(
        'FCM',
        'dedup',
        'eventId already seen via SignalR — suppressing heads-up',
        eventId: message.data['eventId']?.toString(),
      );
      return;
    }
    await _postLocal(
      id: message.hashCode & 0x7FFFFFFF,
      title: notif.title ?? 'Toury',
      body: notif.body ?? '',
      payload: _encodePayload(message.data),
    );
    markEvent();
  }

  Future<void> _postLocal({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        // Brand tint applied to the silhouette icon and the lock-screen
        // accent dot. Same hex as `notification_color` in
        // android/app/src/main/res/values/colors.xml so foreground
        // (Dart-rendered) and background (OS-rendered) pushes match.
        color: Color(0xFF276EF1),
        // Show full title + body on the lock screen. Switch to
        // NotificationVisibility.secret if a future privacy audit
        // decides chat previews / booking ids are too revealing on
        // a locked device.
        visibility: NotificationVisibility.public,
        // TODO(notification-icon): Replace placeholder with proper
        // white-silhouette PNG generated from Android Asset Studio.
        // Current placeholder is the colored launcher logo, which
        // Android 5+ will render as a white square in the status bar.
        // See Problem 3 follow-up + NOTIFICATION_ICON_TODO.md.
        icon: 'ic_stat_notify',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
      );
    } catch (e) {
      RealtimeLogger.instance.log(
        'FCM',
        'localShow.error',
        '$e',
        isError: true,
      );
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final NotificationSettings settings;
      if (kIsWeb) {
        settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isIOS) {
        settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: true,
        );
      } else {
        settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      RealtimeLogger.instance.log(
        'FCM',
        'permission',
        settings.authorizationStatus.toString(),
      );
    } catch (e) {
      RealtimeLogger.instance.log(
        'FCM',
        'permission.error',
        '$e',
        isError: true,
      );
    }
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final s = await Permission.notification.request();
        RealtimeLogger.instance.log('FCM', 'androidPermission', s.toString());
      } catch (e) {
        RealtimeLogger.instance.log(
          'FCM',
          'androidPermission.error',
          '$e',
          isError: true,
        );
      }
    }
  }

  Future<void> _waitForApnsTokenIfIos() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      String? apns;
      for (int i = 0; i < 10 && apns == null; i++) {
        apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
      RealtimeLogger.instance.log(
        'FCM',
        'apns',
        apns == null ? 'NOT VERIFIED: APNS token still null' : 'ready',
        isError: apns == null,
      );
    } catch (e) {
      RealtimeLogger.instance.log('FCM', 'apns.error', '$e', isError: true);
    }
  }

  Future<String?> _safeGetToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      RealtimeLogger.instance.log('FCM', 'getToken.error', '$e', isError: true);
      return null;
    }
  }

  bool _isFirebaseSupported() => kIsWeb || Platform.isAndroid || Platform.isIOS;

  bool _isFirebaseReady() {
    try {
      // Firebase.apps is empty when initializeApp() failed or was never run.
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _stringifyData(Map<String, dynamic> data) {
    return data.map((k, v) => MapEntry(k, v?.toString()));
  }

  String _encodePayload(Map<String, dynamic> data) {
    final buf = StringBuffer();
    data.forEach((k, v) {
      buf.write(k);
      buf.write('\x01');
      buf.write(v?.toString() ?? '');
      buf.write('\x02');
    });
    return buf.toString();
  }

  Map<String, dynamic>? _decodePayload(String payload) {
    final entries = payload.split('\x02');
    final out = <String, dynamic>{};
    for (final e in entries) {
      if (e.isEmpty) continue;
      final idx = e.indexOf('\x01');
      if (idx <= 0) continue;
      out[e.substring(0, idx)] = e.substring(idx + 1);
    }
    return out.isEmpty ? null : out;
  }

  @visibleForTesting
  // ignore: invalid_use_of_visible_for_testing_member
  void debugIngestForTest(RemoteMessage m) => _onForegroundMessage(m);

  void debugFakeForegroundHeadsUp() {
    _onForegroundMessage(
      RemoteMessage(
        data: {
          'eventId': 'debug-fg-${DateTime.now().millisecondsSinceEpoch}',
          'notificationType': 'Diagnostics',
        },
        notification: const RemoteNotification(
          title: 'Rafiq',
          body: 'Synthetic foreground heads-up',
        ),
      ),
    );
  }
}
