import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import 'package:toury/core/models/tracking/tracking_point_entity.dart';
import '../../domain/entities/tracking_entity.dart';
import '../../domain/usecases/get_latest_location_usecase.dart';
import '../../domain/usecases/get_tracking_history_usecase.dart';
import 'helper_tracking_state.dart';

class HelperTrackingCubit extends Cubit<HelperTrackingState> {
  final GetLatestLocationUseCase getLatestLocationUseCase;
  final GetTrackingHistoryUseCase getTrackingHistoryUseCase;
  final BookingTrackingHubService hubService;
  final AuthService authService;

  StreamSubscription? _signalrSubscription;

  HelperTrackingCubit({
    required this.getLatestLocationUseCase,
    required this.getTrackingHistoryUseCase,
    required this.hubService,
    required this.authService,
  }) : super(HelperTrackingInitial());

  Future<void> startTracking(String bookingId) async {
    emit(HelperTrackingLoading());

    // 1. Load History & Latest (HTTP)
    final historyResult = await getTrackingHistoryUseCase(bookingId);
    final latestResult = await getLatestLocationUseCase(bookingId);

    historyResult.fold(
      (failure) => emit(HelperTrackingError(failure.message)),
      (history) {
        final latest = latestResult.getOrElse(() => history.isNotEmpty ? history.last : TrackingPointEntity(latitude: 0, longitude: 0, timestamp: DateTime.now())); 
        
        final initialTracking = TrackingEntity(
          history: history,
          latestPoint: latest.latitude != 0 ? latest : null,
          status: 'Connecting...',
        );

        emit(HelperTrackingLive(tracking: initialTracking));

        // 2. Connect SignalR
        _connectSignalR(bookingId);
      },
    );
  }

  Future<void> _connectSignalR(String bookingId) async {
    try {
      final token = authService.getToken();
      if (token == null) throw Exception('Unauthorized');

      await hubService.connect(bookingId, token);

      _signalrSubscription?.cancel();
      _signalrSubscription = hubService.updateStream.listen((update) {
        if (state is HelperTrackingLive) {
          final current = (state as HelperTrackingLive).tracking;
          
          final newHistory = List<TrackingPointEntity>.from(current.history);
          newHistory.add(update.point);

          emit((state as HelperTrackingLive).copyWith(
            tracking: TrackingEntity(
              latestPoint: update.point,
              history: newHistory,
              status: update.status ?? current.status,
              distanceToTarget: update.distanceToTarget ?? current.distanceToTarget,
              etaMinutes: update.etaMinutes ?? current.etaMinutes,
            ),
          ));
        }
      });
    } catch (e) {
      emit(HelperTrackingError('SignalR Connection Failed: $e'));
    }
  }

  void toggleFollow(bool follow) {
    if (state is HelperTrackingLive) {
      emit((state as HelperTrackingLive).copyWith(isFollowing: follow));
    }
  }

  @override
  Future<void> close() {
    _signalrSubscription?.cancel();
    hubService.disconnect();
    return super.close();
  }
}
