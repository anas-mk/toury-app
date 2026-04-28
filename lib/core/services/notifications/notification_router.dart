import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../realtime/event_dedup_cache.dart';
import '../realtime/realtime_logger.dart';

/// Single source of routing for both FCM tap actions and SignalR-driven
/// navigation triggers.
///
/// Notification-tap lifecycle (in order of arrival):
///
/// 1. **Cold-start tap** (app was killed). `FirebaseMessaging.getInitialMessage()`
///    is read in `main()` BEFORE `runApp()`. The result is stashed via
///    [setPendingDeepLink] because the navigator key is not mounted yet —
///    routing immediately would no-op. It will be consumed by the first
///    successful auth-gated navigation in `app_router.dart`'s redirect
///    callback (see [consumePendingDeepLink]).
///
/// 2. **Background tap** (app was alive but not visible).
///    `FirebaseMessaging.onMessageOpenedApp` lands on [routeFromData] directly.
///    The router IS bound by this point so navigation runs synchronously.
///
/// 3. **Foreground push** (app visible). `FirebaseMessaging.onMessage` is
///    handled by `MessagingService` — it shows a heads-up via
///    `flutter_local_notifications`; tapping the heads-up calls back into
///    [routeFromData] via the local-notification tap handler.
class NotificationRouter {
  NotificationRouter._();
  static final NotificationRouter instance = NotificationRouter._();

  GoRouter? _router;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// FCM `data` map captured before the navigator was ready (cold-start tap).
  /// Drained by [consumePendingDeepLink] once the router is mounted AND the
  /// user has finished the splash → auth flow.
  Map<String, dynamic>? _pendingDeepLink;

  /// User-app contract: helper-only notification types should never trigger
  /// navigation here. The backend may emit defensively to all device tokens
  /// for a given user id when role-fanout is uncertain. We log + drop.
  static const Set<String> _helperOnlyTypes = {
    'RequestIncoming',
    'RequestRemoved',
    'HelperApprovalChanged',
    'HelperBanStatusChanged',
    'HelperSuspensionChanged',
    'HelperDeactivatedByDrugTest',
    'HelperAvailabilityChanged',
    'HelperDashboardChanged',
    'InterviewDecision',
  };

  void bind(GoRouter router, {GlobalKey<NavigatorState>? navigatorKey}) {
    _router = router;
    _navigatorKey = navigatorKey;
    RealtimeLogger.instance.log(
      'Router',
      'bind',
      'GoRouter bound navigatorKey=${navigatorKey != null}',
    );
  }

  BuildContext? get _context =>
      _navigatorKey?.currentContext ??
      _router?.routerDelegate.navigatorKey.currentContext;

  BuildContext? get navigatorContext => _context;

  // ── Pending deep-link buffer ──────────────────────────────────────────────

  /// Captures an FCM `data` map that we cannot route immediately because
  /// either the GoRouter isn't bound yet OR the user hasn't finished the
  /// splash → auth flow. Called from `main()` for cold-start initial messages.
  ///
  /// Calling twice in a row keeps the latest message — the user almost
  /// certainly tapped one notification, not two simultaneously.
  void setPendingDeepLink(Map<String, dynamic> data) {
    final type = data['notificationType']?.toString();
    final eventId = data['eventId']?.toString();
    _pendingDeepLink = data;
    RealtimeLogger.instance.log(
      'Router',
      'pending.set',
      'type=$type — buffered for post-auth consumption',
      eventId: eventId,
    );
  }

  /// Returns and clears the pending deep-link, if any. Safe to call from
  /// the GoRouter `redirect` callback — caller decides whether to
  /// consume the destination string and let GoRouter navigate, or to
  /// invoke [routeFromData] directly.
  Map<String, dynamic>? takePendingDeepLink() {
    final data = _pendingDeepLink;
    _pendingDeepLink = null;
    return data;
  }

  /// Routes the buffered link if present. Returns the destination route
  /// string when GoRouter should redirect there, or `null` if there's
  /// nothing pending / nothing routable.
  ///
  /// Marks the `eventId` in [EventDedupCache] before returning so a
  /// concurrent SignalR-driven navigation for the same event is suppressed.
  String? consumePendingDeepLink() {
    final data = _pendingDeepLink;
    if (data == null) return null;
    final type = data['notificationType']?.toString() ??
        data['NotificationType']?.toString();
    if (type == null || type.isEmpty) {
      _pendingDeepLink = null;
      return null;
    }
    if (_helperOnlyTypes.contains(type)) {
      _pendingDeepLink = null;
      RealtimeLogger.instance.log(
        'Router',
        'pending.drop.helperType',
        'type=$type — user app ignores helper-only types',
      );
      return null;
    }
    final route = _routeForData(data);
    if (route == null) {
      _pendingDeepLink = null;
      return null;
    }
    final eventId = data['eventId']?.toString() ??
        data['EventId']?.toString();
    if (eventId != null && eventId.isNotEmpty) {
      EventDedupCache.instance.mark(eventId);
    }
    _pendingDeepLink = null;
    RealtimeLogger.instance.log(
      'Router',
      'pending.consume',
      'type=$type → $route',
      eventId: eventId,
    );
    return route;
  }

  // ── Direct routing (background tap / local-notification tap / SignalR) ────

  bool routeFromData(Map<String, dynamic> data, {String reason = 'fcm'}) {
    final type = (data['notificationType'] ??
            data['NotificationType'] ??
            data['type'])
        ?.toString();
    final eventId = data['eventId']?.toString() ?? data['EventId']?.toString();

    if (type == 'Test') {
      RealtimeLogger.instance.log(
        'Router',
        'test',
        'dev test push — toast only ($reason)',
        eventId: eventId,
      );
      _postFrameSnack('Test push (dev)');
      return false;
    }

    if (type == null || type.isEmpty) {
      RealtimeLogger.instance.log(
        'Router',
        'route.skip',
        'no notificationType in data',
        eventId: eventId,
        isError: true,
      );
      return false;
    }

    if (_helperOnlyTypes.contains(type)) {
      RealtimeLogger.instance.log(
        'Router',
        'route.drop.helperType',
        'type=$type — user app ignores helper-only types',
        eventId: eventId,
      );
      return false;
    }

    final route = _routeForData(data);
    if (route == null) {
      RealtimeLogger.instance.log(
        'Router',
        'route.unmapped',
        'type=$type — no route or required id missing',
        eventId: eventId,
        isError: true,
      );
      return false;
    }

    RealtimeLogger.instance.log(
      'Router',
      'go',
      'type=$type → $route ($reason)',
      eventId: eventId,
    );

    final navigated = _go(route);
    if (navigated && type == 'BookingCancelled') {
      _postFrameSnack('Booking cancelled');
    }
    return navigated;
  }

  void _postFrameSnack(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _context;
      if (ctx == null || !ctx.mounted) return;
      ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  /// Reads any combination of camelCase / PascalCase keys and returns the
  /// destination route, or `null` if the type is unmapped or a required
  /// id is missing.
  String? _routeForData(Map<String, dynamic> data) {
    final type = (data['notificationType'] ??
            data['NotificationType'] ??
            data['type'])
        ?.toString();
    if (type == null || type.isEmpty) return null;
    final bookingId = data['bookingId']?.toString() ??
        data['BookingId']?.toString();
    final conversationId = data['conversationId']?.toString() ??
        data['ConversationId']?.toString();
    final paymentStatus = data['paymentStatus']?.toString() ??
        data['PaymentStatus']?.toString();
    return _routeFor(
      type,
      bookingId: bookingId,
      conversationId: conversationId,
      paymentStatus: paymentStatus,
    );
  }

  String? _routeFor(
    String type, {
    String? bookingId,
    String? conversationId,
    String? paymentStatus,
  }) {
    final id = bookingId ?? '';
    switch (type) {
      case 'BookingAccepted':
        return id.isEmpty ? null : '/instant/confirmed/$id';
      case 'BookingDeclined':
      case 'BookingAwaitingUserAction':
        return id.isEmpty ? null : '/instant/alternatives/$id';
      case 'BookingReassigning':
        return id.isEmpty ? null : '/instant/waiting/$id';
      case 'BookingCancelled':
        return id.isEmpty ? null : '/booking-details/$id';
      case 'TripStarted':
        return id.isEmpty ? null : '/trip/$id';
      case 'TripEnded':
        // Conditional: pay-now if backend says payment is awaiting, else
        // post-trip review screen. Matches the user-flow contract from the
        // instant-booking redesign work.
        if (id.isEmpty) return null;
        return paymentStatus == 'AwaitingPayment'
            ? '/instant/pay-now/$id'
            : '/booking-details/$id';
      case 'ChatMessage':
        // /chat/:id consumes a bookingId (see app_router.dart:1024–1028
        // → UserChatPage(bookingId: id)). conversationId is the defensive
        // fallback in case the backend ever ships ChatMessage without
        // bookingId for a non-booking conversation type.
        final chatId = id.isNotEmpty ? id : (conversationId ?? '');
        return chatId.isEmpty ? null : '/chat/$chatId';
      case 'HelperReportResolved':
      case 'ReportResolved':
        return '/reports';
      case 'SosTriggered':
      case 'SosResolved':
        // Active-trip context first; falls back to home if SOS arrives
        // without a bookingId (shouldn't happen, but defensive).
        return id.isEmpty ? '/home' : '/booking-details/$id';
      default:
        return null;
    }
  }

  bool _go(String route) {
    final r = _router;
    if (r == null) {
      RealtimeLogger.instance.log(
        'Router',
        'go.skip',
        'router not bound yet',
        isError: true,
      );
      return false;
    }
    try {
      final ctx = _context;
      if (ctx != null && ctx.mounted) {
        ctx.push(route);
      } else {
        r.go(route);
      }
      return true;
    } catch (e) {
      RealtimeLogger.instance.log(
        'Router',
        'go.error',
        '$e',
        isError: true,
      );
      try {
        r.go(route);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  bool routeFromSignalR({
    required String notificationType,
    required String eventId,
    String? bookingId,
    String? conversationId,
    Map<String, dynamic>? extra,
  }) {
    if (EventDedupCache.instance.isDuplicate(eventId)) {
      RealtimeLogger.instance.log(
        'Router',
        'route.dedup',
        'type=$notificationType — dropped (eventId already routed via FCM)',
        eventId: eventId,
      );
      return false;
    }
    return routeFromData(
      {
        ...?extra,
        'notificationType': notificationType,
        'eventId': eventId,
        if (bookingId != null) 'bookingId': bookingId,
        if (conversationId != null) 'conversationId': conversationId,
      },
      reason: 'signalr',
    );
  }
}
