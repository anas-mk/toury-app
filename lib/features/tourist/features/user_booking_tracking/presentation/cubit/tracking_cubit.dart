import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/models/tracking/tracking_point_entity.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../helper/features/helper_booking_tracking/domain/usecases/get_latest_location_usecase.dart';
import '../../domain/entities/tracking_entity.dart';
import 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  final GetLatestLocationUseCase getTrackingUseCase;
  final BookingTrackingHubService hubService;

  StreamSubscription? _locationSubscription;

  TrackingCubit({required this.getTrackingUseCase, required this.hubService})
    : super(TrackingInitial());

  Future<void> startTracking(String bookingId) async {
    emit(TrackingLoading());
    try {
      await hubService.ensureConnected();
    } catch (_) {
      // Keep loading the latest REST point even if realtime is temporarily down.
    }
    final result = await getTrackingUseCase(bookingId);

    result.fold((failure) => emit(TrackingError(failure.message)), (point) {
      final tracking = TrackingEntity(
        bookingId: bookingId,
        status: 'Tracking',
        latestPoint: point,
      );
      emit(TrackingActive(tracking: tracking, latestPoint: point));

      // Listen for real-time updates
      _locationSubscription?.cancel();
      _locationSubscription = hubService.helperLocationUpdateStream
          .where((event) => event.bookingId == bookingId)
          .listen((event) {
            final currentState = state;
            if (currentState is TrackingActive) {
              final latestPoint = TrackingPointEntity(
                latitude: event.latitude,
                longitude: event.longitude,
                heading: event.heading,
                speed: event.speedKmh,
                timestamp:
                    event.capturedAt ??
                    event.occurredAt ??
                    DateTime.now().toUtc(),
              );
              final updatedTracking = TrackingEntity(
                bookingId: bookingId,
                status: event.phase ?? currentState.tracking.status,
                latestPoint: latestPoint,
                history: [
                  ...currentState.tracking.history,
                  if (currentState.latestPoint != null)
                    currentState.latestPoint!,
                ],
                distanceToTarget:
                    event.distanceToDestinationKm ?? event.distanceToPickupKm,
                etaMinutes:
                    event.etaToDestinationMinutes ?? event.etaToPickupMinutes,
              );
              emit(
                currentState.copyWith(
                  tracking: updatedTracking,
                  latestPoint: latestPoint,
                ),
              );
            }
          });
    });
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
