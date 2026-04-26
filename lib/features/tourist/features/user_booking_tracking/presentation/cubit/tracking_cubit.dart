import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../helper/features/helper_booking_tracking/domain/usecases/get_latest_location_usecase.dart';
import '../../domain/entities/tracking_entity.dart';
import 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  final GetLatestLocationUseCase getTrackingUseCase;
  final BookingTrackingHubService hubService;

  StreamSubscription? _locationSubscription;

  TrackingCubit({
    required this.getTrackingUseCase,
    required this.hubService,
  }) : super(TrackingInitial());

  Future<void> startTracking(String bookingId) async {
    emit(TrackingLoading());
    final result = await getTrackingUseCase(bookingId);
    
    result.fold(
      (failure) => emit(TrackingError(failure.message)),
      (point) {
        final tracking = TrackingEntity(
          bookingId: bookingId,
          status: 'Tracking',
          latestPoint: point,
        );
        emit(TrackingActive(tracking: tracking, latestPoint: point));
        
        // Listen for real-time updates
        _locationSubscription?.cancel();
        _locationSubscription = hubService.locationStream.listen((update) {
          final currentState = state;
          if (currentState is TrackingActive) {
            emit(currentState.copyWith(
              tracking: currentState.tracking, // We can keep or update eta
              latestPoint: update.point,
            ));
          }
        });
      },
    );
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
