import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/services/realtime/booking_realtime_event_bus.dart';
import '../../../../../../core/services/signalr/booking_hub_events.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../domain/entities/app_payment_method.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/create_instant_booking_request.dart';
import '../../domain/entities/helper_search_result.dart';
import '../../domain/entities/instant_search_request.dart';
import '../../domain/usecases/instant/cancel_instant_booking_uc.dart';
import '../../domain/usecases/instant/create_instant_booking_uc.dart';
import '../../domain/usecases/instant/get_alternatives_uc.dart';
import '../../domain/usecases/instant/get_booking_detail_uc.dart';
import '../../domain/usecases/instant/search_instant_helpers_uc.dart';
import 'instant_booking_state.dart';

/// Single source of truth for the Instant Trip Booking flow.
///
/// Replaces the old `BookingCubit.createInstant` path and the previous
/// stub `InstantBookingCubit`. Owns:
///   * helper search
///   * booking creation
///   * waiting / accepted / declined / cancelled transitions
///   * SignalR fan-in ([BookingRealtimeEventBus]) subscriptions while watching
///     a booking (shared across pages for the cubit lifetime)
class InstantBookingCubit extends Cubit<InstantBookingState> {
  InstantBookingCubit({
    required this.searchInstantHelpersUC,
    required this.createInstantBookingUC,
    required this.cancelInstantBookingUC,
    required this.getBookingDetailUC,
    required this.getAlternativesUC,
    required this.hubService,
  }) : super(const InstantBookingInitial());

  final SearchInstantHelpersUC searchInstantHelpersUC;
  final CreateInstantBookingUC createInstantBookingUC;
  final CancelInstantBookingUC cancelInstantBookingUC;
  final GetBookingDetailUC getBookingDetailUC;
  final GetAlternativesUC getAlternativesUC;
  final BookingTrackingHubService hubService;

  AppPaymentMethod _selectedPaymentMethod = AppPaymentMethod.cash;
  AppPaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;
  void setPaymentMethod(AppPaymentMethod m) {
    _selectedPaymentMethod = m;
  }

  StreamSubscription<BookingRealtimeBusEvent>? _statusSub;
  StreamSubscription<BookingRealtimeBusEvent>? _cancelledSub;

  /// `bookingId` we are currently watching — used so cross-talk from
  /// other bookings on the same hub is filtered out.
  String? _watchedBookingId;

  // ------------------------------------------------------------------
  // 1) Search instant helpers
  // ------------------------------------------------------------------
  Future<void> searchHelpers(InstantSearchRequest request) async {
    emit(const InstantBookingSearching());
    final result = await searchInstantHelpersUC(request);
    result.fold(
      (failure) => emit(InstantBookingError(failure.message)),
      (helpers) => emit(InstantBookingHelpersLoaded(helpers)),
    );
  }

  /// Caches a helpers list when the user navigates back (so we don't
  /// re-fire the search call). Optional; safe to ignore.
  void presentCachedHelpers(List<HelperSearchResult> helpers) {
    emit(InstantBookingHelpersLoaded(helpers));
  }

  // ------------------------------------------------------------------
  // 2) Create the booking
  // ------------------------------------------------------------------
  Future<void> createBooking(CreateInstantBookingRequest request) async {
    emit(const InstantBookingCreating());
    final result = await createInstantBookingUC(request);
    result.fold(
      (failure) => emit(InstantBookingError(failure.message)),
      (booking) {
        emit(InstantBookingCreated(booking));
        _startWatching(booking);
      },
    );
  }

  // ------------------------------------------------------------------
  // 3) Watch the booking until terminal status — used by WaitingForHelperPage
  // ------------------------------------------------------------------
  Future<void> startWatchingExisting(String bookingId) async {
    final result = await getBookingDetailUC(bookingId);
    result.fold(
      (failure) => emit(InstantBookingError(failure.message)),
      _startWatching,
    );
  }

  void _startWatching(BookingDetail booking) {
    _stopWatching();
    _watchedBookingId = booking.bookingId;
    emit(InstantBookingWaiting(booking));
    _attachSignalR(booking.bookingId);
  }

  Future<void> _attachSignalR(String bookingId) async {
    try {
      await hubService.ensureConnected();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ InstantBookingCubit: SignalR ensureConnected failed → $e');
      }
    }

    _statusSub = BookingRealtimeEventBus.instance.stream
        .where((e) {
          if (e is! BusBookingStatusChanged) return false;
          return e.event.bookingId == bookingId;
        })
        .cast<BusBookingStatusChanged>()
        .listen((e) => _onStatusChanged(e.event));

    _cancelledSub = BookingRealtimeEventBus.instance.stream
        .where((e) {
          if (e is! BusBookingCancelled) return false;
          return e.event.bookingId == bookingId;
        })
        .cast<BusBookingCancelled>()
        .listen((e) => _onCancelled(e.event));
  }

  /// Push / deep-link entry for [TripTrackingEntryPage] (no prior cubit tree).
  Future<void> hydrateForTripDeepLink(String bookingId) async {
    if (isClosed) return;
    final detail = await _fetchOrFail(bookingId);
    if (detail == null || isClosed) return;
    final s = detail.status;
    if (s == BookingStatus.completed) {
      if (!isClosed) {
        emit(const InstantBookingError('This trip has already ended.'));
      }
      return;
    }
    if (s == BookingStatus.inProgress || s.isFirm) {
      if (!isClosed) emit(InstantBookingAccepted(detail));
      return;
    }
    await _handleStatusFromDetail(detail);
  }

  /// Lightweight refresh for [TripTrackingPage] after `/start` — keeps the
  /// cubit on [InstantBookingAccepted] with the latest InProgress payload.
  Future<void> refreshLiveTripDetail(String bookingId) async {
    if (isClosed) return;
    final result = await getBookingDetailUC(bookingId);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (!isClosed) emit(InstantBookingError(failure.message));
      },
      (detail) {
        if (!isClosed) emit(InstantBookingAccepted(detail));
      },
    );
  }

  Future<void> _onStatusChanged(BookingStatusChangedEvent event) async {
    if (kDebugMode) {
      debugPrint(
        '📡 BookingStatusChanged: ${event.oldStatus} → ${event.newStatus}',
      );
    }
    await _refreshBooking(event.bookingId);
  }

  Future<void> _onCancelled(BookingCancelledEvent event) async {
    if (kDebugMode) {
      debugPrint('📡 BookingCancelled: ${event.reason}');
    }
    await _refreshBooking(event.bookingId);
  }

  Future<BookingDetail?> _fetchOrFail(String bookingId) async {
    if (isClosed) return null;
    final result = await getBookingDetailUC(bookingId);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        if (!isClosed) emit(InstantBookingError(failure.message));
        return null;
      },
      (detail) => detail,
    );
  }

  Future<void> _refreshBooking(String bookingId) async {
    if (isClosed) return;
    if (_watchedBookingId != null && bookingId != _watchedBookingId) return;
    final result = await getBookingDetailUC(bookingId);
    if (isClosed) return;
    result.fold(
      (failure) {
        if (!isClosed) emit(InstantBookingError(failure.message));
      },
      (detail) async {
        if (isClosed) return;
        await _handleStatusFromDetail(detail);
      },
    );
  }

  Future<void> _handleStatusFromDetail(BookingDetail detail) async {
    if (isClosed) return;
    final status = detail.status;
    if (status.isFirm) {
      if (!isClosed) emit(InstantBookingAccepted(detail));
      _stopWatching();
      return;
    }
    switch (status) {
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
      case BookingStatus.waitingForUserAction:
        await _emitDeclinedFromDetail(detail);
        break;
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
        if (!isClosed) _emitCancelled(detail.cancellationReason ?? 'Booking cancelled');
        break;
      case BookingStatus.inProgress:
      case BookingStatus.completed:
        if (!isClosed) emit(InstantBookingAccepted(detail));
        _stopWatching();
        break;
      default:
        if (!isClosed) emit(InstantBookingWaiting(detail));
        break;
    }
  }

  Future<void> _emitDeclinedFromDetail(BookingDetail detail) async {
    if (isClosed) return;
    final altResult = await getAlternativesUC(detail.bookingId);
    if (isClosed) return;
    altResult.fold(
      (failure) {
        if (!isClosed) emit(InstantBookingError(failure.message));
      },
      (alternatives) {
        if (!isClosed) emit(InstantBookingDeclined(detail, alternatives));
      },
    );
  }

  void _emitCancelled(String reason) {
    if (isClosed) return;
    emit(InstantBookingCancelled(reason));
    _stopWatching();
  }

  /// Syncs local state after another layer (e.g. [CancelBookingSheet])
  /// already called the cancel API.
  void acknowledgeUserCancellation(String reason) {
    if (!isClosed) _emitCancelled(reason);
  }

  // ------------------------------------------------------------------
  // 4) Cancel from the user side
  // ------------------------------------------------------------------
  Future<bool> cancelBooking(String bookingId, String reason) async {
    final result = await cancelInstantBookingUC(
      bookingId: bookingId,
      reason: reason,
    );
    return result.fold(
      (failure) {
        if (!isClosed) emit(InstantBookingError(failure.message));
        return false;
      },
      (_) {
        if (!isClosed) _emitCancelled(reason);
        return true;
      },
    );
  }

  // ------------------------------------------------------------------
  // 5) Cleanup
  // ------------------------------------------------------------------
  void _stopWatching() {
    _statusSub?.cancel();
    _statusSub = null;
    _cancelledSub?.cancel();
    _cancelledSub = null;
    _watchedBookingId = null;
  }

  /// Resets to initial — useful when the user backs out of the flow.
  void reset() {
    _stopWatching();
    emit(const InstantBookingInitial());
  }

  @override
  Future<void> close() {
    _stopWatching();
    return super.close();
  }
}
