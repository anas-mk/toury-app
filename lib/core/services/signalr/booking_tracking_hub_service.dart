import 'dart:async';

import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

import '../../config/api_config.dart';
import '../../models/tracking/tracking_point_model.dart';
import '../../models/tracking/tracking_update.dart';
import '../auth_service.dart';
import '../realtime/event_dedup_cache.dart';
import '../realtime/realtime_connection_issue_notifier.dart';
import '../realtime/realtime_logger.dart';
import 'booking_hub_events.dart';

/// SignalR client for `/hubs/booking`.
///
/// Lifecycle:
///   - `start()` is called from `AuthCubit` (and from the app-resume observer)
///     after a successful login. The token is resolved fresh on every reconnect
///     via the [AuthService] reference, so a token refresh during a session
///     "just works" on the next reconnect cycle without us having to call
///     `disconnect → connect` ourselves.
///   - `connect(String token)` is the legacy entry point; it forwards to
///     `start()` and stores the token in the auth service if it isn't there.
///   - `stop()` is called on logout.
///   - `ensureConnected()` is awaited by feature cubits before subscribing.
///
/// Every incoming event is:
///   1. Logged through [RealtimeLogger] (`📡 RT:` prefix).
///   2. Marked in [EventDedupCache] so a duplicate FCM doesn't re-process it.
///   3. Parsed leniently (PascalCase OR camelCase keys).
///   4. Pushed onto BOTH a typed stream (preferred) and the legacy
///      `Map<String, dynamic>` stream (helper-side cubits still depend on it).
///
/// Reconnection is handled by `signalr_netcore`'s built-in
/// `withAutomaticReconnect`. Do NOT add a polling fallback or HTTP retry on
/// top of this.
class BookingTrackingHubService {
  BookingTrackingHubService({
    AuthService? authService,
    RealtimeConnectionIssueNotifier? connectionIssues,
  })  : _authService = authService,
        _connectionIssues = connectionIssues;

  AuthService? _authService;
  final RealtimeConnectionIssueNotifier? _connectionIssues;
  HubConnection? _hubConnection;
  String? _lastTokenSnapshot;
  Future<void>? _connectInFlight;

  // Diagnostics: tracks the previous connection state so we can log
  // `old → new` transitions on every change. Step 1 of the realtime audit.
  HubConnectionState _lastLoggedState = HubConnectionState.Disconnected;

  /// Names of the server-method handlers we have registered. Surfaced to
  /// the diagnostics page so we can verify nothing was forgotten.
  final Set<String> _registeredHandlers = <String>{};
  Set<String> get registeredHandlers => Set.unmodifiable(_registeredHandlers);

  // Lazy hook so callers that built the service before the AuthService was
  // available (e.g. tests) can still wire it later.
  void bindAuthService(AuthService authService) {
    _authService = authService;
  }

  // ── Legacy untyped controllers (helper-side relies on them) ─────────────────
  final _locationController = StreamController<TrackingUpdate>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _requestController = StreamController<Map<String, dynamic>>.broadcast();
  final _dashboardController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();

  // ── Typed controllers (USE THESE for new code) ──────────────────────────────
  final _bookingStatusChanged =
      StreamController<BookingStatusChangedEvent>.broadcast();
  final _bookingCancelled =
      StreamController<BookingCancelledEvent>.broadcast();
  final _bookingPaymentChanged =
      StreamController<BookingPaymentChangedEvent>.broadcast();
  final _bookingTripStarted =
      StreamController<BookingTripStartedEvent>.broadcast();
  final _bookingTripEnded =
      StreamController<BookingTripEndedEvent>.broadcast();
  final _helperLocationUpdate =
      StreamController<HelperLocationUpdateEvent>.broadcast();
  final _chatMessagePush =
      StreamController<ChatMessagePushEvent>.broadcast();
  final _helperReportResolved =
      StreamController<HelperReportResolvedEvent>.broadcast();
  final _reportResolved =
      StreamController<ReportResolvedEvent>.broadcast();
  final _sosTriggered = StreamController<SosTriggeredEvent>.broadcast();
  final _sosResolved = StreamController<SosResolvedEvent>.broadcast();
  final _pong = StreamController<PongEvent>.broadcast();

  final _connectionStateController =
      StreamController<HubConnectionState>.broadcast();

  // ── Legacy stream getters ──────────────────────────────────────────────────
  Stream<TrackingUpdate> get locationStream => _locationController.stream;
  @Deprecated('Use locationStream instead')
  Stream<TrackingUpdate> get updateStream => _locationController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get requestStream => _requestController.stream;
  Stream<Map<String, dynamic>> get dashboardStream =>
      _dashboardController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;

  // ── Typed stream getters ───────────────────────────────────────────────────
  Stream<BookingStatusChangedEvent> get bookingStatusChangedStream =>
      _bookingStatusChanged.stream;
  Stream<BookingCancelledEvent> get bookingCancelledStream =>
      _bookingCancelled.stream;
  Stream<BookingPaymentChangedEvent> get bookingPaymentChangedStream =>
      _bookingPaymentChanged.stream;
  Stream<BookingTripStartedEvent> get bookingTripStartedStream =>
      _bookingTripStarted.stream;
  Stream<BookingTripEndedEvent> get bookingTripEndedStream =>
      _bookingTripEnded.stream;
  Stream<HelperLocationUpdateEvent> get helperLocationUpdateStream =>
      _helperLocationUpdate.stream;
  Stream<ChatMessagePushEvent> get chatMessageStream =>
      _chatMessagePush.stream;
  Stream<HelperReportResolvedEvent> get helperReportResolvedStream =>
      _helperReportResolved.stream;
  Stream<ReportResolvedEvent> get reportResolvedStream =>
      _reportResolved.stream;
  Stream<SosTriggeredEvent> get sosTriggeredStream => _sosTriggered.stream;
  Stream<SosResolvedEvent> get sosResolvedStream => _sosResolved.stream;
  Stream<PongEvent> get pongStream => _pong.stream;

  Stream<HubConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  HubConnectionState get connectionState =>
      _hubConnection?.state ?? HubConnectionState.Disconnected;

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  // ── Public lifecycle ───────────────────────────────────────────────────────

  /// Starts (or restarts) the hub connection. The token is resolved freshly
  /// on every reconnect via [AuthService], so this is the path you want for
  /// a JWT that may have been refreshed in the background.
  Future<void> start() async {
    if (_authService == null) {
      RealtimeLogger.instance.log(
        'SignalR',
        'start.skip',
        'AuthService not bound — cannot resolve token',
        isError: true,
      );
      return;
    }
    final token = _authService!.getToken();
    if (token == null || token.isEmpty) {
      RealtimeLogger.instance.log(
        'SignalR',
        'start.skip',
        'No JWT in AuthService',
        isError: true,
      );
      return;
    }
    await connect(token);
  }

  /// Legacy entry — kept for callers that explicitly hold the token.
  /// Prefer [start] from new code.
  Future<void> connect(String token) async {
    if (isConnected && _lastTokenSnapshot == token) {
      RealtimeLogger.instance
          .log('SignalR', 'connect.skip', 'already connected with same token');
      return;
    }
    if (isConnected && _lastTokenSnapshot != token) {
      RealtimeLogger.instance.log(
        'SignalR',
        'reconnect.token',
        'access string changed while connected → stop + reconnect',
      );
      await stop();
    }
    if (_connectInFlight != null) {
      return _connectInFlight!;
    }
    _connectInFlight = _connect(token);
    try {
      await _connectInFlight;
    } finally {
      _connectInFlight = null;
    }
  }

  /// Awaited by feature cubits before they subscribe.
  Future<void> ensureConnected() async {
    if (isConnected) return;
    if (_authService != null) {
      await start();
      return;
    }
    final token = _lastTokenSnapshot;
    if (token == null) {
      throw StateError(
        'SignalR not initialised — call start()/connect(token) on login first.',
      );
    }
    await connect(token);
  }

  Future<void> disconnect() => stop();

  /// Called when [AuthService.saveToken] persisted a new JWT — closes an
  /// existing socket so the next negotiate uses the fresh bearer.
  Future<void> onAccessTokenPersisted(String token) async {
    if (token.isEmpty) return;
    if (!isConnected) return;
    if (_lastTokenSnapshot == token) return;
    RealtimeLogger.instance.log(
      'SignalR',
      'token.persisted',
      'new access string → reconnecting /hubs/booking',
    );
    await stop();
    await connect(token);
  }

  Future<void> stop() async {
    try {
      await _hubConnection?.stop();
      RealtimeLogger.instance.log('SignalR', 'stop', 'connection stopped');
    } catch (e) {
      RealtimeLogger.instance.log(
        'SignalR',
        'stop.error',
        '$e',
        isError: true,
      );
    } finally {
      _hubConnection = null;
      _lastTokenSnapshot = null;
      _emitState(HubConnectionState.Disconnected);
    }
  }

  /// Fires `Ping()` on the hub. The server replies via the `Pong` handler
  /// which lands on [pongStream]. Used by the diagnostics page.
  Future<void> ping() async {
    if (!isConnected) {
      RealtimeLogger.instance.log(
        'SignalR',
        'ping.skip',
        'not connected',
        isError: true,
      );
      return;
    }
    try {
      await _hubConnection!.invoke('Ping');
      RealtimeLogger.instance.log('SignalR', 'ping', 'sent');
    } catch (e) {
      RealtimeLogger.instance.log(
        'SignalR',
        'ping.error',
        '$e',
        isError: true,
      );
    }
  }

  Future<void> dispose() async {
    await stop();
    await _locationController.close();
    await _statusController.close();
    await _requestController.close();
    await _dashboardController.close();
    await _chatController.close();
    await _bookingStatusChanged.close();
    await _bookingCancelled.close();
    await _bookingPaymentChanged.close();
    await _bookingTripStarted.close();
    await _bookingTripEnded.close();
    await _helperLocationUpdate.close();
    await _chatMessagePush.close();
    await _helperReportResolved.close();
    await _reportResolved.close();
    await _sosTriggered.close();
    await _sosResolved.close();
    await _pong.close();
    await _connectionStateController.close();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  /// Pushes [next] onto the connection-state stream AND logs the
  /// `old → new` transition exactly once. All state changes go through this
  /// so we have a single grep-able line per transition (`📡 RT: SignalR
  /// state.transition Disconnected → Connected`).
  void _emitState(HubConnectionState next) {
    final prev = _lastLoggedState;
    if (prev == next) {
      // Don't spam the log when signalr_netcore re-emits the same state
      // (it sometimes fires Connected twice during fast reconnects).
      _connectionStateController.add(next);
      return;
    }
    _lastLoggedState = next;
    RealtimeLogger.instance.log(
      'SignalR',
      'state.transition',
      '${prev.name} → ${next.name}',
    );
    _connectionStateController.add(next);
  }

  Future<void> _connect(String token) async {
    _lastTokenSnapshot = token;
    final hubUrl = ApiConfig.bookingHub;

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            // Transport: leave default negotiate flow — ASP.NET orders
            // WebSockets → SSE → long-poll; client tries each until one works.
            // CRITICAL: factory resolves the LATEST token on every reconnect
            // attempt instead of capturing the one we connected with first.
            accessTokenFactory: () async {
              final fresh = _authService?.getToken() ?? _lastTokenSnapshot;
              return fresh ?? '';
            },
          ),
        )
        .withAutomaticReconnect(
          retryDelays: const [0, 2000, 5000, 10000, 20000],
        )
        .build();

    _hubConnection?.onclose(({error}) {
      RealtimeLogger.instance.log(
        'SignalR',
        'onclose',
        error?.toString() ?? 'closed',
        isError: error != null,
      );
      _connectionIssues?.reportHubClosedWithPossibleAuthIssue(error);
      _emitState(HubConnectionState.Disconnected);
    });
    _hubConnection?.onreconnecting(({error}) {
      RealtimeLogger.instance.log(
        'SignalR',
        'onreconnecting',
        error?.toString() ?? 'reconnecting',
      );
      _emitState(HubConnectionState.Reconnecting);
    });
    _hubConnection?.onreconnected(({connectionId}) {
      RealtimeLogger.instance.log(
        'SignalR',
        'onreconnected',
        'id=$connectionId',
      );
      _connectionIssues?.clear();
      _emitState(HubConnectionState.Connected);
    });

    _registerHandlers();

    try {
      await _hubConnection?.start();
      _emitState(HubConnectionState.Connected);
      _connectionIssues?.clear();
      RealtimeLogger.instance.log(
        'SignalR',
        'connected',
        'Connected to /hubs/booking — RT: registered ${_registeredHandlers.length} handlers',
      );
      // Step 1 diagnostic: dump the full handler-name list so we can sanity
      // check casing without re-reading the source. Sorted for stable diff.
      final sortedHandlers = _registeredHandlers.toList()..sort();
      RealtimeLogger.instance.log(
        'SignalR',
        'handlers',
        sortedHandlers.join(', '),
      );
      // Step 1 diagnostic: one-shot Ping → Pong RTT measurement. Cheap signal
      // for which transport the negotiate landed on:
      //   <50ms  ≈ WebSocket
      //   100–500ms ≈ SSE
      //   >1000ms ≈ long-polling (or server cold-start on runasp.net free tier)
      unawaited(_runStartupPingDiagnostic());
    } catch (e) {
      RealtimeLogger.instance.log(
        'SignalR',
        'connect.error',
        '$e',
        isError: true,
      );
      rethrow;
    }
  }

  /// Sends a single `Ping()` and logs the RTT to the first matching `Pong`.
  /// Times out at 5s so a stalled long-polling transport surfaces clearly.
  /// Errors here are diagnostic-only and never propagate.
  Future<void> _runStartupPingDiagnostic() async {
    final hub = _hubConnection;
    if (hub == null || hub.state != HubConnectionState.Connected) return;
    final completer = Completer<void>();
    StreamSubscription<PongEvent>? sub;
    sub = _pong.stream.listen((_) {
      if (!completer.isCompleted) completer.complete();
    });
    final sentAt = DateTime.now();
    try {
      await hub.invoke('Ping');
      RealtimeLogger.instance.log('SignalR', 'ping.diag.sent', '');
      await completer.future.timeout(const Duration(seconds: 5));
      final rttMs = DateTime.now().difference(sentAt).inMilliseconds;
      final transportHint = rttMs < 50
          ? 'likely WebSocket'
          : rttMs < 500
              ? 'likely SSE'
              : 'likely long-polling or cold start';
      RealtimeLogger.instance.log(
        'SignalR',
        'ping.diag.rtt',
        '${rttMs}ms ($transportHint)',
      );
    } on TimeoutException {
      RealtimeLogger.instance.log(
        'SignalR',
        'ping.diag.timeout',
        'no Pong within 5s — transport may be stalled',
        isError: true,
      );
    } catch (e) {
      RealtimeLogger.instance.log(
        'SignalR',
        'ping.diag.error',
        '$e',
        isError: true,
      );
    } finally {
      await sub.cancel();
    }
  }

  // Wraps the classic `hub.on(name, callback)` so that:
  //   - the handler name is recorded (for diagnostics),
  //   - the callback is `try/catch`-d (so a single bad payload doesn't kill
  //     the whole connection),
  //   - every payload is logged + the eventId is marked in dedup.
  void _registerOn<T>(
    String name, {
    required T Function(Map<String, dynamic>) parse,
    required void Function(T parsed) push,
    String? Function(T parsed)? eventIdOf,
  }) {
    final hub = _hubConnection;
    if (hub == null) return;
    hub.on(name, (args) {
      try {
        final raw = _firstMap(args);
        if (raw == null) {
          RealtimeLogger.instance.log(
            'SignalR',
            name,
            'empty payload, ignoring',
            isError: true,
          );
          return;
        }
        final parsed = parse(raw);
        final eid = eventIdOf?.call(parsed);
        EventDedupCache.instance.mark(eid);
        RealtimeLogger.instance.log(
          'SignalR',
          name,
          _summarize(name, raw),
          eventId: eid,
        );
        push(parsed);
      } catch (e, st) {
        RealtimeLogger.instance.log(
          'SignalR',
          '$name.error',
          '$e\n$st',
          isError: true,
        );
      }
    });
    _registeredHandlers.add(name);
  }

  void _registerHandlers() {
    final hub = _hubConnection;
    if (hub == null) return;
    _registeredHandlers.clear();

    // ── Booking lifecycle ───────────────────────────────────────────────────
    _registerOn<BookingStatusChangedEvent>(
      'BookingStatusChanged',
      parse: BookingStatusChangedEvent.fromMap,
      push: (e) {
        _statusController.add(_eventToMap(e));
        _bookingStatusChanged.add(e);
      },
      eventIdOf: (e) => e.eventId,
    );
    _registerOn<BookingCancelledEvent>(
      'BookingCancelled',
      parse: BookingCancelledEvent.fromMap,
      push: (e) {
        _statusController.add(_eventToMap(e));
        _bookingCancelled.add(e);
      },
      eventIdOf: (e) => e.eventId,
    );
    _registerOn<BookingPaymentChangedEvent>(
      'BookingPaymentChanged',
      parse: BookingPaymentChangedEvent.fromMap,
      push: (e) {
        _statusController.add(_eventToMap(e));
        _bookingPaymentChanged.add(e);
      },
      eventIdOf: (e) => e.eventId,
    );
    _registerOn<BookingTripStartedEvent>(
      'BookingTripStarted',
      parse: BookingTripStartedEvent.fromMap,
      push: (e) {
        _statusController.add(_eventToMap(e));
        _bookingTripStarted.add(e);
      },
      eventIdOf: (e) => e.eventId,
    );
    _registerOn<BookingTripEndedEvent>(
      'BookingTripEnded',
      parse: BookingTripEndedEvent.fromMap,
      push: (e) {
        _statusController.add(_eventToMap(e));
        _bookingTripEnded.add(e);
      },
      eventIdOf: (e) => e.eventId,
    );

    // ── Helper location (typed + legacy point conversion) ───────────────────
    hub.on('HelperLocationUpdate', (args) {
      try {
        final raw = _firstMap(args);
        if (raw == null) {
          RealtimeLogger.instance.log(
            'SignalR',
            'HelperLocationUpdate.empty',
            'args=$args',
            isError: true,
          );
          return;
        }
        final ev = HelperLocationUpdateEvent.fromMap(raw);
        EventDedupCache.instance.mark(ev.eventId);
        RealtimeLogger.instance.log(
          'SignalR',
          'HelperLocationUpdate',
          'booking=${ev.bookingId} '
              'lat=${ev.latitude.toStringAsFixed(5)} '
              'lng=${ev.longitude.toStringAsFixed(5)} '
              'phase=${ev.phase} '
              'etaPickup=${ev.etaToPickupMinutes} '
              'etaDest=${ev.etaToDestinationMinutes}',
          eventId: ev.eventId,
        );
        _helperLocationUpdate.add(ev);

        // Legacy stream — keep helper-side TrackingCubit working.
        try {
          final pointJson = raw['point'] is Map<String, dynamic>
              ? raw['point'] as Map<String, dynamic>
              : raw;
          final point = TrackingPointModel.fromJson(pointJson);
          _locationController.add(
            TrackingUpdate(
              point: point,
              status: raw['status']?.toString(),
              distanceToTarget:
                  (raw['distanceToTarget'] as num?)?.toDouble() ??
                      ev.distanceToPickupKm ??
                      ev.distanceToDestinationKm,
              etaMinutes: (raw['etaMinutes'] as num?)?.toInt() ??
                  ev.etaToPickupMinutes ??
                  ev.etaToDestinationMinutes,
            ),
          );
        } catch (e) {
          RealtimeLogger.instance.log(
            'SignalR',
            'HelperLocationUpdate.legacy',
            '$e',
            isError: true,
          );
        }
      } catch (e, st) {
        RealtimeLogger.instance.log(
          'SignalR',
          'HelperLocationUpdate.error',
          '$e\n$st',
          isError: true,
        );
      }
    });
    _registeredHandlers.add('HelperLocationUpdate');

    // ── Chat ────────────────────────────────────────────────────────────────
    _registerOn<ChatMessagePushEvent>(
      'ChatMessage',
      parse: ChatMessagePushEvent.fromMap,
      push: (e) {
        _chatController.add(_chatToMap(e));
        _chatMessagePush.add(e);
      },
      eventIdOf: (e) => e.eventId,
    );

    // ── Reports & SOS (NEW — added by this audit) ───────────────────────────
    _registerOn<HelperReportResolvedEvent>(
      'HelperReportResolved',
      parse: HelperReportResolvedEvent.fromMap,
      push: _helperReportResolved.add,
      eventIdOf: (e) => e.eventId,
    );
    _registerOn<ReportResolvedEvent>(
      'ReportResolved',
      parse: ReportResolvedEvent.fromMap,
      push: _reportResolved.add,
      eventIdOf: (e) => e.eventId,
    );
    _registerOn<SosTriggeredEvent>(
      'SosTriggered',
      parse: SosTriggeredEvent.fromMap,
      push: _sosTriggered.add,
      eventIdOf: (e) => e.eventId,
    );
    _registerOn<SosResolvedEvent>(
      'SosResolved',
      parse: SosResolvedEvent.fromMap,
      push: _sosResolved.add,
      eventIdOf: (e) => e.eventId,
    );

    // ── Helper-only broadcasts (kept so the helper app keeps working) ───────
    hub.on('RequestIncoming', (args) {
      final raw = _firstMap(args);
      if (raw != null) _requestController.add(raw);
    });
    hub.on('RequestRemoved', (args) {
      final raw = _firstMap(args);
      if (raw != null) _requestController.add(raw);
    });
    hub.on('HelperDashboardChanged', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });
    hub.on('HelperAvailabilityChanged', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });
    hub.on('HelperApprovalChanged', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });
    hub.on('HelperBanStatusChanged', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });
    hub.on('HelperSuspensionChanged', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });
    hub.on('HelperDeactivatedByDrugTest', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });
    hub.on('InterviewDecision', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });

    // ── Diagnostics ─────────────────────────────────────────────────────────
    hub.on('Pong', (args) {
      try {
        final ts = (args == null || args.isEmpty)
            ? 0
            : (args.first is num
                ? (args.first as num).toInt()
                : int.tryParse(args.first.toString()) ?? 0);
        _pong.add(PongEvent(serverTimestampMs: ts));
        RealtimeLogger.instance.log('SignalR', 'Pong', 'serverTs=$ts');
      } catch (e) {
        RealtimeLogger.instance.log(
          'SignalR',
          'Pong.error',
          '$e',
          isError: true,
        );
      }
    });
    _registeredHandlers.add('Pong');
  }

  Map<String, dynamic>? _firstMap(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final raw = args.first;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  // Compact one-liner used in the realtime log.
  // Reads keys via [_pick] so we tolerate both camelCase (signalr_netcore
  // default) and PascalCase (raw .NET) wire shapes — mirrors the leniency
  // already in `booking_hub_events.dart` so the log matches the parsed event.
  String _summarize(String name, Map<String, dynamic> raw) {
    final id = _pick(raw, 'bookingId');
    switch (name) {
      case 'BookingStatusChanged':
        return 'booking=$id ${_pick(raw, 'oldStatus')}→${_pick(raw, 'newStatus')}';
      case 'BookingCancelled':
        return 'booking=$id by=${_pick(raw, 'cancelledBy')} reason=${_pick(raw, 'reason')}';
      case 'BookingPaymentChanged':
        return 'booking=$id status=${_pick(raw, 'status')} amount=${_pick(raw, 'amount')}${_pick(raw, 'currency')}';
      case 'BookingTripStarted':
        return 'booking=$id startedAt=${_pick(raw, 'startedAt')}';
      case 'BookingTripEnded':
        return 'booking=$id final=${_pick(raw, 'finalPrice')} pay=${_pick(raw, 'paymentStatus')}';
      case 'ChatMessage':
        return 'booking=$id from=${_pick(raw, 'senderName')}';
      case 'HelperReportResolved':
      case 'ReportResolved':
        return 'reportId=${_pick(raw, 'reportId')} resolution=${_pick(raw, 'resolution')}';
      case 'SosTriggered':
        return 'sosId=${_pick(raw, 'sosId')} by=${_pick(raw, 'triggeredBy')}';
      case 'SosResolved':
        return 'sosId=${_pick(raw, 'sosId')} resolution=${_pick(raw, 'resolution')}';
    }
    return raw.keys.take(4).join(',');
  }

  /// camelCase-or-PascalCase tolerant scalar lookup, used only by
  /// [_summarize] so log lines stay readable regardless of wire casing.
  Object? _pick(Map raw, String camel) {
    if (raw.containsKey(camel)) return raw[camel];
    final pascal = camel.isEmpty
        ? camel
        : '${camel[0].toUpperCase()}${camel.substring(1)}';
    if (raw.containsKey(pascal)) return raw[pascal];
    return null;
  }

  // ── Adapters between typed events and the legacy Map-based streams ────────
  // The helper-side TrackingCubit / older code listens to `statusStream` /
  // `chatStream` as raw maps. We keep those alive by re-encoding the typed
  // events back into camelCase JSON-shaped maps.

  Map<String, dynamic> _eventToMap(Object e) {
    if (e is BookingStatusChangedEvent) {
      return {
        'eventType': 'BookingStatusChanged',
        'eventId': e.eventId,
        'bookingId': e.bookingId,
        'userId': e.userId,
        'helperId': e.helperId,
        'oldStatus': e.oldStatus,
        'newStatus': e.newStatus,
        'paymentStatus': e.paymentStatus,
      };
    }
    if (e is BookingCancelledEvent) {
      return {
        'eventType': 'BookingCancelled',
        'eventId': e.eventId,
        'bookingId': e.bookingId,
        'userId': e.userId,
        'helperId': e.helperId,
        'cancelledBy': e.cancelledBy,
        'reason': e.reason,
      };
    }
    if (e is BookingPaymentChangedEvent) {
      return {
        'eventType': 'BookingPaymentChanged',
        'eventId': e.eventId,
        'bookingId': e.bookingId,
        'paymentId': e.paymentId,
        'amount': e.amount,
        'currency': e.currency,
        'method': e.method,
        'status': e.status,
        'failureReason': e.failureReason,
        'refundedAmount': e.refundedAmount,
      };
    }
    if (e is BookingTripStartedEvent) {
      return {
        'eventType': 'BookingTripStarted',
        'eventId': e.eventId,
        'bookingId': e.bookingId,
        'startedAt': e.startedAt?.toIso8601String(),
      };
    }
    if (e is BookingTripEndedEvent) {
      return {
        'eventType': 'BookingTripEnded',
        'eventId': e.eventId,
        'bookingId': e.bookingId,
        'completedAt': e.completedAt?.toIso8601String(),
        'finalPrice': e.finalPrice,
        'paymentStatus': e.paymentStatus,
      };
    }
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _chatToMap(ChatMessagePushEvent e) => {
        'eventType': 'ChatMessage',
        'eventId': e.eventId,
        'bookingId': e.bookingId,
        'conversationId': e.conversationId,
        'messageId': e.messageId,
        'senderId': e.senderId,
        'senderType': e.senderType,
        'senderName': e.senderName,
        'recipientId': e.recipientId,
        'recipientType': e.recipientType,
        'messageType': e.messageType,
        'preview': e.preview,
        'sentAt': e.sentAt?.toIso8601String(),
      };

  /// HELPER-ONLY: pushes the helper's GPS to the hub. The user app should
  /// never call this; it's left here so the helper-side cubits don't break.
  Future<void> sendLocation(
    double lat,
    double lng, {
    double? heading,
    double? speedKmh,
    double? accuracyMeters,
  }) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      final args = <Object>[
        lat,
        lng,
        heading ?? 0.0,
        speedKmh ?? 0.0,
        accuracyMeters ?? 0.0,
      ];
      await _hubConnection!.invoke('SendLocation', args: args);
    }
  }
}
