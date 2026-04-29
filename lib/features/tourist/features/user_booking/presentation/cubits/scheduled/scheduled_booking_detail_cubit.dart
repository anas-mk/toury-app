import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signalr_netcore/hub_connection.dart';

import '../../../../../../../core/services/realtime/booking_realtime_event_bus.dart';
import '../../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_status.dart';
import '../../../domain/usecases/instant/get_booking_detail_uc.dart';
import '../../../domain/usecases/instant/get_booking_status_uc.dart';

abstract class ScheduledBookingDetailState extends Equatable {
  const ScheduledBookingDetailState();
  @override
  List<Object?> get props => [];
}

class ScheduledBookingDetailInitial extends ScheduledBookingDetailState {
  const ScheduledBookingDetailInitial();
}

class ScheduledBookingDetailLoading extends ScheduledBookingDetailState {
  const ScheduledBookingDetailLoading();
}

class ScheduledBookingDetailLoaded extends ScheduledBookingDetailState {
  final BookingDetail booking;
  final bool isRefreshing;

  /// Number of inbound chat messages received since the last time the
  /// chat screen was opened (Fix 11). Reset to 0 by [markChatRead].
  final int unreadChatCount;

  /// True when the helper has triggered SOS for this booking (Fix 11).
  /// Stays true until a `SosResolved` event arrives.
  final bool sosActive;

  const ScheduledBookingDetailLoaded(
    this.booking, {
    this.isRefreshing = false,
    this.unreadChatCount = 0,
    this.sosActive = false,
  });

  ScheduledBookingDetailLoaded copyWith({
    BookingDetail? booking,
    bool? isRefreshing,
    int? unreadChatCount,
    bool? sosActive,
  }) =>
      ScheduledBookingDetailLoaded(
        booking ?? this.booking,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        unreadChatCount: unreadChatCount ?? this.unreadChatCount,
        sosActive: sosActive ?? this.sosActive,
      );

  @override
  List<Object?> get props =>
      [booking, isRefreshing, unreadChatCount, sosActive];
}

class ScheduledBookingDetailError extends ScheduledBookingDetailState {
  final String message;
  const ScheduledBookingDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Spine-of-the-flow cubit for the Scheduled Trip detail screen.
///
/// Reuses [GetBookingDetailUC] (originally written for the instant flow,
/// but the endpoint is shared) so we never duplicate the REST contract.
///
/// Realtime policy (Fix 11 — refined from "always refetch"):
///
///  * `BookingStatusChanged`, `BookingCancelled`, `BookingPaymentChanged`,
///    `BookingTripStarted`, `BookingTripEnded` → full REST refetch.
///  * `HelperLocationUpdate` → IGNORED here (this is a high-frequency GPS
///    stream consumed directly by the live-tracking screen).
///  * `ChatMessage` → bump local unread counter only. The chat opens via
///    its own cubit which fetches messages from REST.
///  * `SosTriggered` → flip [ScheduledBookingDetailLoaded.sosActive] true.
///    `SosResolved` → flip it back false.
///
/// Polling fallback (Fix 6): when the SignalR connection isn't healthy
/// AND the booking is in a "live" state (waiting on helper, in
/// reassignment, awaiting payment, in-progress), the cubit periodically
/// hits the lightweight `GET /user/bookings/{id}/status` endpoint. If the
/// status drifts from the cached one, we trigger a full detail refetch.
/// The polling timer is cancelled the moment the hub reconnects.
class ScheduledBookingDetailCubit extends Cubit<ScheduledBookingDetailState> {
  ScheduledBookingDetailCubit({
    required this.getBookingDetailUC,
    required this.getBookingStatusUC,
    required this.hubService,
  }) : super(const ScheduledBookingDetailInitial());

  final GetBookingDetailUC getBookingDetailUC;
  final GetBookingStatusUC getBookingStatusUC;
  final BookingTrackingHubService hubService;

  StreamSubscription<BookingRealtimeBusEvent>? _busSub;
  StreamSubscription<HubConnectionState>? _hubStateSub;
  Timer? _pollTimer;
  String? _watchedBookingId;

  // Statuses that justify a polling fallback when the hub is down.
  static const _livePollStatuses = <BookingStatus>{
    BookingStatus.pendingHelperResponse,
    BookingStatus.reassignmentInProgress,
    BookingStatus.confirmedAwaitingPayment,
    BookingStatus.inProgress,
  };

  Future<void> load(String bookingId) async {
    if (isClosed) return;

    final current = state;
    final preservedUnread =
        current is ScheduledBookingDetailLoaded ? current.unreadChatCount : 0;
    final preservedSos =
        current is ScheduledBookingDetailLoaded ? current.sosActive : false;

    if (current is ScheduledBookingDetailLoaded &&
        current.booking.bookingId == bookingId) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const ScheduledBookingDetailLoading());
    }

    final result = await getBookingDetailUC(bookingId);
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(ScheduledBookingDetailError(failure.message));
      },
      (detail) {
        emit(ScheduledBookingDetailLoaded(
          detail,
          unreadChatCount: preservedUnread,
          sosActive: preservedSos,
        ));
        _ensureWatching(bookingId);
        _reconcilePolling();
      },
    );
  }

  /// Force a silent re-fetch (used by pull-to-refresh and after the
  /// user runs a write action like cancel/pay).
  Future<void> refresh() async {
    final s = state;
    if (s is ScheduledBookingDetailLoaded) {
      await load(s.booking.bookingId);
    } else if (_watchedBookingId != null) {
      await load(_watchedBookingId!);
    }
  }

  /// Reset the unread-chat badge — called by the screen when the user
  /// opens the chat sheet.
  void markChatRead() {
    final s = state;
    if (s is ScheduledBookingDetailLoaded && s.unreadChatCount > 0) {
      emit(s.copyWith(unreadChatCount: 0));
    }
  }

  /// Lets the screen dismiss the SOS banner if the helper resolved it
  /// out-of-band (e.g. via REST status sync).
  void clearSosBanner() {
    final s = state;
    if (s is ScheduledBookingDetailLoaded && s.sosActive) {
      emit(s.copyWith(sosActive: false));
    }
  }

  void _ensureWatching(String bookingId) {
    if (_watchedBookingId == bookingId && _busSub != null) return;
    _watchedBookingId = bookingId;

    unawaited(_attachHub());

    _busSub?.cancel();
    _busSub = BookingRealtimeEventBus.instance.stream.listen(
      (e) => _onBusEvent(e, bookingId),
    );

    // Listen to hub connection-state transitions so we can prefer the
    // realtime feed over the polling timer the moment we reconnect.
    _hubStateSub?.cancel();
    _hubStateSub = hubService.connectionStateStream.listen((_) {
      _reconcilePolling();
    });
  }

  Future<void> _attachHub() async {
    try {
      await hubService.ensureConnected();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ScheduledBookingDetailCubit] ensureConnected failed: $e');
      }
    }
  }

  void _onBusEvent(BookingRealtimeBusEvent event, String bookingId) {
    // High-frequency GPS stream — never refetch the booking on this.
    if (event is BusHelperLocationUpdate) return;

    if (event is BusChatMessage && event.event.bookingId == bookingId) {
      final s = state;
      if (s is ScheduledBookingDetailLoaded) {
        // Don't refetch on chat — the screen is informational; the chat
        // detail screen pulls messages from REST itself.
        emit(s.copyWith(unreadChatCount: s.unreadChatCount + 1));
      }
      return;
    }

    String? affected;
    String? tag;

    if (event is BusBookingStatusChanged &&
        event.event.bookingId == bookingId) {
      affected = event.event.bookingId;
      tag = 'status';
    } else if (event is BusBookingCancelled &&
        event.event.bookingId == bookingId) {
      affected = event.event.bookingId;
      tag = 'cancelled';
    } else if (event is BusBookingPaymentChanged &&
        event.event.bookingId == bookingId) {
      affected = event.event.bookingId;
      tag = 'payment';
    } else if (event is BusBookingTripStarted &&
        event.event.bookingId == bookingId) {
      affected = event.event.bookingId;
      tag = 'tripStarted';
    } else if (event is BusBookingTripEnded &&
        event.event.bookingId == bookingId) {
      affected = event.event.bookingId;
      tag = 'tripEnded';
    }

    if (affected != null) {
      if (kDebugMode) {
        debugPrint(
          '[ScheduledBookingDetailCubit] realtime hint=$tag → refetching '
          'GET /user/bookings/$affected',
        );
      }
      unawaited(load(affected));
    }
  }

  /// Decides whether the polling timer should be on or off based on the
  /// current booking status and hub connection state. Idempotent.
  void _reconcilePolling() {
    if (isClosed) return;
    final s = state;
    if (s is! ScheduledBookingDetailLoaded) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    final status = s.booking.status;
    if (!_livePollStatuses.contains(status)) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    // If the hub is healthy we don't need polling — REST refetch happens
    // on every realtime event.
    if (hubService.isConnected) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    // Tighter cadence while we're waiting on a time-sensitive helper
    // response, looser once we're confirmed and just waiting for the
    // trip window.
    final interval = status == BookingStatus.pendingHelperResponse
        ? const Duration(seconds: 10)
        : const Duration(seconds: 20);

    if (_pollTimer != null) return; // Already running.
    _pollTimer = Timer.periodic(interval, (_) => _pollTick());
  }

  Future<void> _pollTick() async {
    if (isClosed) return;
    final s = state;
    if (s is! ScheduledBookingDetailLoaded) return;
    final cachedStatus = s.booking.status;
    final id = s.booking.bookingId;

    final result = await getBookingStatusUC(id);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (kDebugMode) {
          debugPrint(
            '[ScheduledBookingDetailCubit] poll error: ${failure.message}',
          );
        }
      },
      (statusResp) {
        if (statusResp.status != cachedStatus) {
          if (kDebugMode) {
            debugPrint(
              '[ScheduledBookingDetailCubit] poll status drift '
              '${cachedStatus.raw} → ${statusResp.status.raw}; refetching',
            );
          }
          unawaited(load(id));
        }
      },
    );
  }

  /// Hook called by [ScheduledBookingDetailScreen] when SOS streams the
  /// hub aren't surfaced through the bus today (the bus only carries
  /// bookings/chat/location/reports). The screen subscribes to the hub
  /// directly and forwards events here.
  void onSosTriggered() {
    final s = state;
    if (s is ScheduledBookingDetailLoaded && !s.sosActive) {
      emit(s.copyWith(sosActive: true));
    }
  }

  void onSosResolved() {
    final s = state;
    if (s is ScheduledBookingDetailLoaded && s.sosActive) {
      emit(s.copyWith(sosActive: false));
    }
  }

  @override
  Future<void> close() {
    _busSub?.cancel();
    _hubStateSub?.cancel();
    _pollTimer?.cancel();
    return super.close();
  }
}
