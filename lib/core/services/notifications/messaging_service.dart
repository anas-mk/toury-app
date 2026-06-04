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
import 'in_app_notification_banner.dart';
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

  // Dedicated channel for notifications posted while the app is in the
  // foreground. Low importance = appears in the shade but NO heads-up
  // overlay and NO sound/vibration (the in-app banner handles that).
  static const String _foregroundChannelId   = 'rafiq_foreground_silent';
  static const String _foregroundChannelName = 'In-app notifications';

  // Channel IDs that match the backend's ResolveAndroidChannel values.
  // Each must be created before the first notification arrives — if a
  // channel referenced in the FCM payload doesn't exist, Android 8+
  // silently drops the heads-up and sound.
  static const _extraChannels = [
    ('booking_updates', 'Booking updates',
        'Helper accepted / declined, reassignment, cancellation'),
    ('trip_updates', 'Trip updates', 'Trip started and ended events'),
    ('booking_requests', 'Booking requests',
        'Incoming helper requests'),
    ('high_priority', 'Alerts', 'High-priority system alerts'),
  ];

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;
  bool _started = false;
  String? _lastFcmToken;

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  String? get lastFcmToken => _lastFcmToken;
  String get deviceIdSync => 'â€”';

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
        // High-importance channel â†” heads-up + sound + lock-screen body.
        // MUST stay in sync with the channel id referenced by
        // AndroidManifest's `default_notification_channel_id` meta-data,
        // otherwise OS-rendered FCM pushes fall back to a low-importance
        // system channel (silent, no heads-up). Lock-screen visibility is
        // configured per-notification via AndroidNotificationDetails.visibility
        // below â€” the channel itself doesn't expose that field in
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
        final plugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await plugin?.createNotificationChannel(channel);

        // Create every channel the backend references so Android never
        // falls back to a silent low-importance system channel.
        for (final (id, name, desc) in _extraChannels) {
          await plugin?.createNotificationChannel(
            AndroidNotificationChannel(
              id,
              name,
              description: desc,
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
              showBadge: true,
              enableLights: true,
              ledColor: const Color(0xFF276EF1),
            ),
          );
        }

        // Silent foreground channel — no heads-up, no sound, no vibration.
        // Used when the app is open so the in-app banner handles the UX
        // and the notification only lands silently in the shade.
        await plugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _foregroundChannelId,
            _foregroundChannelName,
            description: 'Silently logged while the app is open',
            importance: Importance.low,
            enableVibration: false,
            playSound: false,
            showBadge: false,
          ),
        );
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
        'Firebase not initialized â€” push notifications disabled',
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
          'â€¦${token.substring(token.length - 10)}',
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
          'â€¦${newToken.substring(newToken.length - 10)}',
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
    final notifType = data['notificationType'];
    RealtimeLogger.instance.log(
      'FCM',
      'foreground',
      'type=$notifType eventId=$eventId',
      eventId: eventId,
    );

    if (notifType == 'Test') {
      showInAppBanner('Test push (dev)', '', null, 'Test');
      EventDedupCache.instance.mark(eventId);
      return;
    }

    // App is in FOREGROUND â†’ show our overlay banner.
    // If SignalR already handled this event (dedup hit), skip silently â€”
    // the banner was already displayed via maybeInAppBannerFromBusEvent.
    if (EventDedupCache.instance.contains(eventId)) {
      RealtimeLogger.instance.log(
        'FCM',
        'foreground.dedup',
        'eventId already seen via SignalR â€” overlay already shown',
        eventId: eventId,
      );
      return;
    }
    EventDedupCache.instance.mark(eventId);

    // Always use branded titles — the backend's data['title'] may be a raw
    // sender name (e.g. "Ahmed Hassan") which is not a notification title.
    final (title, fallbackBody) = _brandedContent(notifType, message.data, message.notification);
    final body = data['body']?.toString() ??
        data['preview']?.toString() ??
        fallbackBody;

    showInAppBanner(title, body, Map<String, dynamic>.from(message.data), notifType);
  }

  void showInAppBanner(
    String title,
    String body, [
    Map<String, dynamic>? data,
    String? notificationType,
  ]) {
    // InAppBannerHost in app.dart renders the banner via ValueNotifier —
    // no overlay state lookup, no frame-phase checking needed.
    InAppNotificationBanner.show(
      title: title,
      body: body,
      notificationType: notificationType,
      onTap: data == null
          ? null
          : () => NotificationRouter.instance.routeFromData(
                data,
                reason: 'in-app-banner-tap',
              ),
    );
    // Also post to the system notification shade so the user can see it
    // when they pull down the drawer (even while the app is open).
    unawaited(_showSystemNotification(
      title: title,
      body: body,
      notificationType: notificationType,
      data: data,
    ));
  }

  Future<void> _showSystemNotification({
    required String title,
    required String body,
    required String? notificationType,
    Map<String, dynamic>? data,
  }) async {
    if (!_initialised || kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final payload = data != null ? _encodePayload(data) : null;
      final id = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
      // Always use the silent foreground channel when the app is open:
      // no heads-up overlay, no sound — the in-app banner handles UX.
      // The notification is still written to the shade so the user sees
      // it when they pull down.
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _foregroundChannelId,
            _foregroundChannelName,
            importance: Importance.low,
            priority: Priority.low,
            showWhen: true,
            playSound: false,
            enableVibration: false,
            visibility: NotificationVisibility.private,
          ),
        ),
        payload: payload,
      );
    } catch (e, st) {
      RealtimeLogger.instance.log(
        'FCM', 'localNotif.error', '$e\n$st', isError: true,
      );
    }
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}\x01${e.value}').join('\x02');
  }

  void maybeInAppBannerFromBusEvent(BookingRealtimeBusEvent e) {
    late final String eventId;
    String title = 'RAFIQ';
    String body = '';
    String? notifType;
    Map<String, dynamic>? routeData;

    if (e is BusBookingStatusChanged) {
      eventId = e.event.eventId;
      switch (e.event.newStatus) {
        case 'AcceptedByHelper':
          title = 'Helper accepted your booking';
          body = 'Your booking has been accepted. Open the app for details.';
          notifType = 'BookingAccepted';
          routeData = {
            'notificationType': 'BookingAccepted',
            'bookingId': e.event.bookingId,
            'eventId': eventId,
          };
        case 'DeclinedByHelper':
        case 'ExpiredNoResponse':
          title = 'Helper declined your booking';
          body = 'The helper declined. We\'ll suggest another one.';
          notifType = 'BookingDeclined';
          routeData = {
            'notificationType': 'BookingDeclined',
            'bookingId': e.event.bookingId,
            'eventId': eventId,
          };
        case 'ReassignmentInProgress':
          title = 'Finding a helper';
          body = 'Searching for an available helperâ€¦';
          notifType = 'BookingReassigning';
          routeData = {
            'notificationType': 'BookingReassigning',
            'bookingId': e.event.bookingId,
            'eventId': eventId,
          };
        case 'WaitingForUserAction':
          title = 'Action needed';
          body = 'Please choose from available helpers.';
          notifType = 'BookingAwaitingUserAction';
          routeData = {
            'notificationType': 'BookingAwaitingUserAction',
            'bookingId': e.event.bookingId,
            'eventId': eventId,
          };
        case 'ConfirmedAwaitingPayment':
        case 'ConfirmedPaid':
        case 'Upcoming':
          title = 'Booking confirmed';
          body = 'Complete payment to lock in your trip.';
          notifType = 'BookingAccepted';
          routeData = {
            'notificationType': 'BookingAccepted',
            'bookingId': e.event.bookingId,
            'eventId': eventId,
          };
        case 'CancelledByHelper':
        case 'CancelledBySystem':
          title = 'Booking cancelled';
          body = 'Your booking was cancelled.';
          notifType = 'BookingCancelled';
          routeData = {
            'notificationType': 'BookingCancelled',
            'bookingId': e.event.bookingId,
            'eventId': eventId,
          };
        default:
          return;
      }
    } else if (e is BusBookingTripStarted) {
      eventId = e.event.eventId;
      title = 'Trip started';
      body = 'Your trip is underway.';
      notifType = 'TripStarted';
      routeData = {
        'notificationType': 'TripStarted',
        'bookingId': e.event.bookingId,
        'eventId': eventId,
      };
    } else if (e is BusBookingTripEnded) {
      eventId = e.event.eventId;
      title = 'Trip ended';
      body = 'Time to complete payment.';
      notifType = 'TripEnded';
      routeData = {
        'notificationType': 'TripEnded',
        'bookingId': e.event.bookingId,
        'eventId': eventId,
      };
    } else if (e is BusBookingPaymentChanged) {
      eventId = e.event.eventId;
      title = 'Payment update';
      body = e.event.status;
    } else if (e is BusChatMessage) {
      eventId = e.event.eventId;
      final sender = (e.event.senderName?.isNotEmpty == true)
          ? e.event.senderName!
          : 'your helper';
      title = 'New message from $sender';
      body = e.event.preview?.isNotEmpty == true
          ? e.event.preview!
          : 'You received a new message.';
      notifType = 'ChatMessage';
      routeData = {
        'notificationType': 'ChatMessage',
        'bookingId': e.event.bookingId,
        'eventId': eventId,
      };
    } else {
      return;
    }

    if (eventId.isNotEmpty && EventDedupCache.instance.contains(eventId)) {
      return;
    }
    EventDedupCache.instance.mark(eventId);
    showInAppBanner(title, body, routeData, notifType);
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


  /// Returns RAFIQ-branded (title, body) regardless of what the FCM
  /// `notification` field contains. The FCM notification.title is often the
  /// helper's name (set by the backend), which we never want to surface
  /// directly as the notification title.
  static (String, String) _brandedContent(
    String? type,
    Map<String, dynamic> data,
    RemoteNotification? notif,
  ) {
    // Prefer the preview / body from the data payload when available,
    // since it's what the backend explicitly set for our consumption.
    final dataBody = data['preview']?.toString() ??
        data['body']?.toString() ??
        notif?.body ??
        '';

    switch (type) {
      case 'ChatMessage':
        final sender = data['senderName']?.toString() ??
            data['helperName']?.toString() ??
            notif?.title ??
            'Your helper';
        return ('New message from $sender', dataBody);
      case 'BookingAccepted':
        return ('Helper accepted your booking', dataBody.isNotEmpty ? dataBody : 'Your booking has been accepted.');
      case 'BookingDeclined':
        return ('Helper declined', dataBody.isNotEmpty ? dataBody : 'The helper declined. We\'ll suggest another one.');
      case 'BookingReassigning':
        return ('Finding a helper', dataBody.isNotEmpty ? dataBody : 'Searching for an available helperâ€¦');
      case 'BookingCancelled':
        return ('Booking cancelled', dataBody.isNotEmpty ? dataBody : 'Your booking was cancelled.');
      case 'TripStarted':
        return ('Trip started', dataBody.isNotEmpty ? dataBody : 'Your trip is underway.');
      case 'TripEnded':
        return ('Trip ended', dataBody.isNotEmpty ? dataBody : 'Time to complete payment.');
      default:
        return ('RAFIQ', dataBody.isNotEmpty ? dataBody : (notif?.title ?? ''));
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
