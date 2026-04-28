import 'package:flutter/widgets.dart';
import 'package:signalr_netcore/hub_connection.dart';

import '../auth_service.dart';
import '../signalr/booking_tracking_hub_service.dart';
import 'realtime_logger.dart';

/// Watches Flutter's app-lifecycle and re-opens the SignalR connection when
/// the app comes back to foreground.
///
/// This is the ONLY place we react to app-lifecycle for realtime; we
/// deliberately do NOT add a polling fallback here — `signalr_netcore`'s
/// own `withAutomaticReconnect` already handles transient drops while the
/// app is in the foreground. We only need to "wake up" the connection
/// when the OS has paused it (e.g. after a long backgrounding).
class HubLifecycleObserver with WidgetsBindingObserver {
  HubLifecycleObserver({
    required this.hubService,
    required this.authService,
  });

  final BookingTrackingHubService hubService;
  final AuthService authService;

  bool _attached = false;

  void attach() {
    if (_attached) return;
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
    RealtimeLogger.instance
        .log('Lifecycle', 'observer.attach', 'foreground watcher armed');
  }

  void detach() {
    if (!_attached) return;
    WidgetsBinding.instance.removeObserver(this);
    _attached = false;
    RealtimeLogger.instance
        .log('Lifecycle', 'observer.detach', 'foreground watcher disarmed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    RealtimeLogger.instance.log('Lifecycle', 'state', state.toString());
    if (state == AppLifecycleState.resumed) {
      _maybeReconnect();
    }
  }

  Future<void> _maybeReconnect() async {
    final token = authService.getToken();
    if (token == null || token.isEmpty) {
      // Not signed in — nothing to do.
      return;
    }
    final st = hubService.connectionState;
    if (st == HubConnectionState.Connected ||
        st == HubConnectionState.Connecting ||
        st == HubConnectionState.Reconnecting) {
      return;
    }
    RealtimeLogger.instance
        .log('Lifecycle', 'reconnect', 'app resumed → reopening hub');
    try {
      await hubService.start();
    } catch (e) {
      RealtimeLogger.instance.log(
        'Lifecycle',
        'reconnect.error',
        '$e',
        isError: true,
      );
    }
  }
}
