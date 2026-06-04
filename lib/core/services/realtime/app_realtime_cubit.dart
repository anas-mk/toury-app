import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/user/features/user_booking/domain/entities/booking_detail_entity.dart';
import '../../../features/user/features/user_booking/presentation/cubits/booking_status_cubit.dart';
import '../../../features/user/features/user_booking/presentation/cubits/my_bookings_cubit.dart';
import '../../di/injection_container.dart';
import '../auth_service.dart';
import '../ratings/pending_rating_tracker.dart';
import '../signalr/booking_hub_events.dart';
import 'booking_realtime_event_bus.dart';

/// Phase 3 — App-wide realtime canonical state.
///
/// The cubit does NOT open a second SignalR connection. It only listens
/// to the existing [BookingRealtimeEventBus.instance.stream] (which is
/// already attached in `main.dart`) and translates bus events into:
///
///   1. A short-lived `lastTripEnded` event consumed by the rating
///      overlay (Phase 4).
///   2. Side-effect refreshes against existing cubits whose public APIs
///      we MUST NOT change. We simply call their existing refresh
///      methods (`startPollingForActive`, `refreshActiveBooking`,
///      `refreshBookings`) on relevant events. This keeps Home, History
///      and Booking Detail in sync without duplicating subscription logic
///      inside each screen.
///
/// All bus events are logged with the `[RT-app]` prefix per the brief.
class AppRealtimeCubit extends Cubit<AppRealtimeState> {
  AppRealtimeCubit() : super(const AppRealtimeState.initial());

  StreamSubscription<BookingRealtimeBusEvent>? _busSub;

  /// Cubits the orchestrator can refresh on relevant events. They are
  /// registered lazily because cubits are factories (per-page lifetime),
  /// so the *currently mounted* page's cubit is the one we want to push
  /// updates into.
  final List<MyBookingsCubit> _myBookingsCubits = [];
  final List<BookingStatusCubit> _bookingStatusCubits = [];

  /// Kicks off the bus subscription. Safe to call multiple times.
  void attach() {
    if (_busSub != null) return;
    _log('attach', 'subscribing to BookingRealtimeEventBus.stream');
    _busSub = BookingRealtimeEventBus.instance.stream.listen(_handle);
  }

  Future<void> detach() async {
    await _busSub?.cancel();
    _busSub = null;
    _myBookingsCubits.clear();
    _bookingStatusCubits.clear();
    _log('detach', 'subscription cancelled');
  }

  /// Page-level cubits register / unregister themselves so we can fan
  /// realtime events out to every active screen at once.
  void registerMyBookings(MyBookingsCubit cubit) {
    if (!_myBookingsCubits.contains(cubit)) _myBookingsCubits.add(cubit);
  }

  void unregisterMyBookings(MyBookingsCubit cubit) {
    _myBookingsCubits.remove(cubit);
  }

  void registerBookingStatus(BookingStatusCubit cubit) {
    if (!_bookingStatusCubits.contains(cubit)) {
      _bookingStatusCubits.add(cubit);
    }
  }

  void unregisterBookingStatus(BookingStatusCubit cubit) {
    _bookingStatusCubits.remove(cubit);
  }

  /// Tells every registered home-level cubit that a brand-new booking
  /// was just created on this device so they can re-fetch.
  ///
  /// The realtime bus delivers `BookingStatusChanged` updates for
  /// **subsequent** transitions (helper accepts, declines, …) but it
  /// does NOT deliver an event the moment a booking is created — that
  /// is purely a client-side action. Without this hook, the home page
  /// keeps showing "no active trip" until the user pulls-to-refresh,
  /// which feels broken right after they confirmed a booking.
  ///
  /// Call site: `BookingReviewPage` right after the cubit transitions
  /// into [InstantBookingCreated]. Safe to call multiple times — the
  /// downstream cubits are idempotent under reentrancy.
  void notifyBookingCreated(String bookingId) {
    _log('notifyBookingCreated', 'booking=$bookingId');
    _refreshAllMyBookings('booking-created');
    _refreshActiveOnAllBookingStatus('booking-created', bookingId);
  }

  void _handle(BookingRealtimeBusEvent event) {
    if (event is BusBookingStatusChanged) {
      _log(
        'status',
        'booking=${event.event.bookingId} '
            '${event.event.oldStatus} -> ${event.event.newStatus}',
      );
      _refreshAllMyBookings('status-changed');
      _refreshActiveOnAllBookingStatus('status-changed', event.event.bookingId);
      return;
    }
    if (event is BusBookingCancelled) {
      _log('cancelled', 'booking=${event.event.bookingId}');
      _refreshAllMyBookings('cancelled');
      _refreshActiveOnAllBookingStatus('cancelled', event.event.bookingId);
      return;
    }
    if (event is BusBookingPaymentChanged) {
      _log(
        'payment',
        'booking=${event.event.bookingId} status=${event.event.status}',
      );
      _refreshActiveOnAllBookingStatus('payment', event.event.bookingId);
      return;
    }
    if (event is BusBookingTripStarted) {
      _log('tripStarted', 'booking=${event.event.bookingId}');
      _refreshAllMyBookings('trip-started');
      _refreshActiveOnAllBookingStatus('trip-started', event.event.bookingId);
      return;
    }
    if (event is BusBookingTripEnded) {
      _log(
        'tripEnded',
        'booking=${event.event.bookingId} '
            'price=${event.event.finalPrice ?? '-'}',
      );
      final currentRole = sl<AuthService>().getRole();
      final isTouristSession = currentRole == 'tourist';

      // Rating overlay is tourist-only. In helper sessions, the helper
      // already rates traveler via helper flow; do not trigger tourist overlay.
      if (isTouristSession) {
        final bookingId = event.event.bookingId;
        if (bookingId.isNotEmpty) {
          unawaited(sl<PendingRatingTracker>().markPending(bookingId));
        }
        // Bubble trip-ended event only for tourist overlay consumption.
        emit(state.copyWith(lastTripEnded: event.event));
      }
      _refreshAllMyBookings('trip-ended');
      _refreshActiveOnAllBookingStatus('trip-ended', event.event.bookingId);
      return;
    }
    if (event is BusChatMessage) {
      _log('chat', 'booking=${event.event.bookingId}');
      // Chat unread tracking is intentionally left as TODO until a
      // dedicated read-receipts API exists. Logged so smoke tests can
      // confirm the wire is alive.
      return;
    }
    // Other bus types (helper location, reports, pong) are ignored at
    // the app level — page-scoped consumers (TripTrackingPage,
    // TrackingCubit) already subscribe to those streams directly.
  }

  void _refreshAllMyBookings(String reason) {
    for (final c in List<MyBookingsCubit>.from(_myBookingsCubits)) {
      if (c.isClosed) {
        _myBookingsCubits.remove(c);
        continue;
      }
      _log('refresh.myBookings', 'reason=$reason');
      // Public API: refreshBookings. Default page size matches the cubit.
      unawaited(c.refreshBookings());
    }
  }

  void _refreshActiveOnAllBookingStatus(String reason, String bookingId) {
    for (final c in List<BookingStatusCubit>.from(_bookingStatusCubits)) {
      if (c.isClosed) {
        _bookingStatusCubits.remove(c);
        continue;
      }
      _log(
        'refresh.bookingStatus',
        'reason=$reason booking=$bookingId',
      );
      // Prefer the targeted refresh when we know the booking id.
      if (bookingId.isNotEmpty) {
        unawaited(c.refreshActiveBooking(bookingId));
      } else {
        unawaited(c.startPollingForActive());
      }
    }
  }

  void _log(String tag, String detail) {
    debugPrint('[RT-app] $tag $detail');
  }
}

/// Lightweight canonical state. Most consumers will only care about
/// `lastTripEnded` for the rating overlay; richer derived state can be
/// added in later phases without changing the cubit's public surface.
class AppRealtimeState {
  final BookingTripEndedEvent? lastTripEnded;

  /// Reserved for richer fan-in summaries in later passes (active
  /// booking, chat unread totals, recents). Kept null today so we don't
  /// promise more than the bus actually delivers.
  final BookingDetailEntity? activeBooking;

  const AppRealtimeState({this.lastTripEnded, this.activeBooking});

  const AppRealtimeState.initial()
      : lastTripEnded = null,
        activeBooking = null;

  AppRealtimeState copyWith({
    BookingTripEndedEvent? lastTripEnded,
    BookingDetailEntity? activeBooking,
  }) {
    return AppRealtimeState(
      lastTripEnded: lastTripEnded ?? this.lastTripEnded,
      activeBooking: activeBooking ?? this.activeBooking,
    );
  }
}