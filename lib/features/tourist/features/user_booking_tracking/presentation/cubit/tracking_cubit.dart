import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signalr_netcore/hub_connection.dart';

import '../../../../../../core/models/tracking/tracking_point_entity.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../helper/features/helper_booking_tracking/domain/usecases/get_latest_location_usecase.dart';
import '../../domain/entities/tracking_entity.dart';
import 'tracking_state.dart';

/// Live-tracking driver for the user side.
///
/// Lifecycle (Fix 7 — Live Tracking Priming):
///   1. On `startTracking`: ensure the hub is connected, then immediately
///      prime the map with `GET /api/booking/{id}/tracking/latest`. This
///      stops the user from looking at an empty map between screen open
///      and the first SignalR push.
///   2. Subscribe to `HelperLocationUpdate` for the live stream.
///   3. On hub reconnect (Disconnected → Connected) we **re-prime** from
///      `/latest` so any movement the user missed during the gap is
///      reflected before realtime resumes.
class TrackingCubit extends Cubit<TrackingState> {
  final GetLatestLocationUseCase getTrackingUseCase;
  final BookingTrackingHubService hubService;

  StreamSubscription? _locationSubscription;
  StreamSubscription<HubConnectionState>? _connectionSubscription;
  String? _currentBookingId;
  bool _wasDisconnected = false;

  TrackingCubit({required this.getTrackingUseCase, required this.hubService})
      : super(TrackingInitial());

  Future<void> startTracking(String bookingId) async {
    _currentBookingId = bookingId;
    emit(TrackingLoading());

    try {
      await hubService.ensureConnected();
    } catch (_) {
      // Network may be flaky — REST priming below still works.
    }

    await _primeFromLatest(bookingId, isInitial: true);
    _attachRealtimeSubscriptions(bookingId);
  }

  Future<void> _primeFromLatest(
    String bookingId, {
    required bool isInitial,
  }) async {
    final result = await getTrackingUseCase(bookingId);
    result.fold(
      (failure) {
        if (isInitial) {
          emit(TrackingError(failure.message));
        }
        // On reconnect prime failures, keep the previous active state —
        // SignalR will push fresh points once it's back.
      },
      (point) {
        final current = state;
        if (current is TrackingActive) {
          emit(current.copyWith(latestPoint: point));
        } else {
          final tracking = TrackingEntity(
            bookingId: bookingId,
            status: 'Tracking',
            latestPoint: point,
          );
          emit(TrackingActive(tracking: tracking, latestPoint: point));
        }
      },
    );
  }

  void _attachRealtimeSubscriptions(String bookingId) {
    _locationSubscription?.cancel();
    _locationSubscription = hubService.helperLocationUpdateStream
        .where((event) => event.bookingId == bookingId)
        .listen((event) {
      final currentState = state;
      if (currentState is! TrackingActive) return;
      final latestPoint = TrackingPointEntity(
        latitude: event.latitude,
        longitude: event.longitude,
        heading: event.heading,
        speed: event.speedKmh,
        timestamp:
            event.capturedAt ?? event.occurredAt ?? DateTime.now().toUtc(),
      );
      final updatedTracking = TrackingEntity(
        bookingId: bookingId,
        status: event.phase ?? currentState.tracking.status,
        latestPoint: latestPoint,
        history: [
          ...currentState.tracking.history,
          if (currentState.latestPoint != null) currentState.latestPoint!,
        ],
        distanceToTarget:
            event.distanceToDestinationKm ?? event.distanceToPickupKm,
        etaMinutes:
            event.etaToDestinationMinutes ?? event.etaToPickupMinutes,
      );
      emit(currentState.copyWith(
        tracking: updatedTracking,
        latestPoint: latestPoint,
      ));
    });

    _connectionSubscription?.cancel();
    _connectionSubscription =
        hubService.connectionStateStream.listen((connState) {
      final id = _currentBookingId;
      if (id == null) return;
      if (connState == HubConnectionState.Disconnected ||
          connState == HubConnectionState.Reconnecting ||
          connState == HubConnectionState.Disconnecting) {
        _wasDisconnected = true;
      } else if (connState == HubConnectionState.Connected) {
        if (_wasDisconnected) {
          _wasDisconnected = false;
          // Re-prime so we don't miss movement that happened while we
          // were offline.
          unawaited(_primeFromLatest(id, isInitial: false));
        }
      }
      // Connecting → ignore; we'll wait for Connected.
    });
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    return super.close();
  }
}
