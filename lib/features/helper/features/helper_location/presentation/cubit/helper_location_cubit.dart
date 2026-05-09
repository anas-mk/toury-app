import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toury/features/helper/features/helper_location/domain/entities/signalr_connection_state.dart';
import '../../data/services/helper_location_tracking_service.dart';
import '../../domain/entities/helper_location_entities.dart';
import '../../domain/usecases/helper_location_usecases.dart';
import '../../../helper_bookings/domain/entities/helper_availability_state.dart';

abstract class HelperLocationState extends Equatable {
  const HelperLocationState();
  @override
  List<Object?> get props => [];
}

class HelperLocationInitial extends HelperLocationState {}

class HelperLocationTracking extends HelperLocationState {
  final HelperLocation location;
  final SignalRConnectionState connectionState;
  const HelperLocationTracking({
    required this.location,
    required this.connectionState,
  });

  @override
  List<Object?> get props => [location, connectionState];
}

class HelperLocationPermissionDenied extends HelperLocationState {}

class HelperLocationError extends HelperLocationState {
  final String message;
  const HelperLocationError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Cubit for Helper Location UI.
/// 
/// This Cubit is a thin wrapper around [HelperLocationTrackingService].
/// It displays the current location and delegates commands to the singleton service.
class HelperLocationCubit extends Cubit<HelperLocationState> {
  final HelperLocationTrackingService _trackingService;
  final GetLocationStatusUseCase _getStatusUseCase;

  StreamSubscription? _locationSubscription;

  HelperLocationCubit({
    required HelperLocationTrackingService trackingService,
    required GetLocationStatusUseCase getLocationStatusUseCase,
  })  : _trackingService = trackingService,
        _getStatusUseCase = getLocationStatusUseCase,
        super(HelperLocationInitial()) {
    
    // Listen to the centralized service
    _locationSubscription = _trackingService.locationStream.listen((location) {
      if (!isClosed) {
        emit(HelperLocationTracking(
          location: location,
          connectionState: _trackingService.currentSignalRState,
        ));
      }
    });
  }

  /// Entry point after login or on dashboard init.
  Future<bool> initialize(String token, {HelperAvailabilityState? availability}) async {
    final ok = await _trackingService.updateTrackingState(
      token: token,
      availability: availability,
    );
    if (!ok && !isClosed) {
      emit(HelperLocationPermissionDenied());
    }
    return ok;
  }

  /// Start tracking for a specific trip.
  Future<bool> startTripTracking(String token, String bookingId) async {
    final ok = await _trackingService.updateTrackingState(
      token: token,
      bookingId: bookingId,
    );
    if (!ok && !isClosed) {
      emit(HelperLocationPermissionDenied());
    }
    return ok;
  }

  /// End trip tracking and return to normal background tracking (if online).
  Future<void> stopTripTracking() async {
    await _trackingService.updateTrackingState(bookingId: null);
  }

  /// Update availability (Online/Offline/etc).
  Future<bool> setAvailabilityState(HelperAvailabilityState availability) async {
    final ok = await _trackingService.updateTrackingState(availability: availability);
    if (!ok && !isClosed) {
      emit(HelperLocationPermissionDenied());
    }
    return ok;
  }

  /// Manually trigger a status refresh (e.g. on pull-to-refresh).
  Future<void> refreshStatus() async {
    try {
      await _getStatusUseCase.execute();
      // You could emit a new state here if needed, or just let the service handle updates.
    } catch (e) {
      if (!isClosed) emit(HelperLocationError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    // NOTE: We do NOT stop the _trackingService here because it is a singleton 
    // that should continue running even if this specific Cubit is destroyed 
    // (e.g. during page navigation).
    return super.close();
  }
}