import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../domain/entities/tracking_entity.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import '../../domain/usecases/get_latest_location_usecase.dart';
import '../../domain/usecases/get_tracking_history_usecase.dart';
import '../../domain/repositories/tracking_repository.dart';
import 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  final GetLatestLocationUseCase getLatestLocationUseCase;
  final GetTrackingHistoryUseCase getTrackingHistoryUseCase;
  final TrackingRepository repository;
  final BookingTrackingHubService hubService;
  final AuthService authService;

  StreamSubscription? _trackingSubscription;

  TrackingCubit({
    required this.getLatestLocationUseCase,
    required this.getTrackingHistoryUseCase,
    required this.repository,
    required this.hubService,
    required this.authService,
  }) : super(TrackingInitial());

  Future<void> startTracking(String bookingId) async {
    emit(TrackingLoading());

    // 1. Load History & Latest from HTTP
    final historyResult = await getTrackingHistoryUseCase(bookingId);
    final latestResult = await getLatestLocationUseCase(bookingId);

    final history = historyResult.fold((_) => <TrackingPointEntity>[], (h) => h);
    final latest = latestResult.fold((_) => null, (l) => l);

    final initialTracking = TrackingEntity(
      bookingId: bookingId,
      latestPoint: latest,
      history: history,
      status: 'Loading...',
    );

    emit(TrackingLive(tracking: initialTracking));

    // 2. Connect SignalR
    final token = authService.getToken();
    if (token == null) {
      emit(const TrackingError('Authentication token not found'));
      return;
    }

    try {
      await hubService.connect(bookingId, token);
      
      _trackingSubscription?.cancel();
      _trackingSubscription = repository.listenToTrackingUpdates(bookingId).listen((update) {
        if (state is TrackingLive) {
          final currentTracking = (state as TrackingLive).tracking;
          
          final updatedHistory = List<TrackingPointEntity>.from(currentTracking.history);
          if (currentTracking.latestPoint != null) {
             updatedHistory.add(currentTracking.latestPoint!);
          }

          emit((state as TrackingLive).copyWith(
            tracking: TrackingEntity(
              bookingId: bookingId,
              latestPoint: update.point,
              history: updatedHistory,
              status: update.status ?? currentTracking.status,
              distanceToTarget: update.distanceToTarget ?? currentTracking.distanceToTarget,
              etaMinutes: update.etaMinutes ?? currentTracking.etaMinutes,
            ),
          ));
        }
      });
    } catch (e) {
      // If SignalR fails, we still have the HTTP data
      // In a real app, we might want to poll HTTP as fallback
    }
  }

  @override
  Future<void> close() {
    _trackingSubscription?.cancel();
    hubService.disconnect();
    return super.close();
  }
}
