import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../realtime/event_dedup_cache.dart';
import '../realtime/realtime_logger.dart';

/// Single source of routing for both FCM tap actions and SignalR-driven
/// navigation triggers.
class NotificationRouter {
  NotificationRouter._();
  static final NotificationRouter instance = NotificationRouter._();

  GoRouter? _router;
  GlobalKey<NavigatorState>? _navigatorKey;

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

  bool routeFromData(Map<String, dynamic> data, {String reason = 'fcm'}) {
    final type = (data['notificationType'] ??
            data['NotificationType'] ??
            data['type'])
        ?.toString();
    final eventId = data['eventId']?.toString() ?? data['EventId']?.toString();
    final bookingId =
        data['bookingId']?.toString() ?? data['BookingId']?.toString();
    final conversationId = data['conversationId']?.toString() ??
        data['ConversationId']?.toString();

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

    final route = _routeFor(type,
        bookingId: bookingId, conversationId: conversationId);
    if (route == null) {
      RealtimeLogger.instance.log(
        'Router',
        'route.unmapped',
        'type=$type',
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

  String? _routeFor(
    String type, {
    String? bookingId,
    String? conversationId,
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
        return id.isEmpty ? null : '/booking-details/$id';
      case 'ChatMessage':
        final convo = conversationId ?? id;
        return convo.isEmpty ? null : '/chat/$convo';
      case 'HelperReportResolved':
      case 'ReportResolved':
        return '/reports';
      case 'SosTriggered':
      case 'SosResolved':
        return '/home';
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
