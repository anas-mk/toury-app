import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signalr_netcore/hub_connection.dart';

import '../../data/models/location_models.dart';
import '../../domain/usecases/location_usecases.dart';

abstract class HelperLocationState extends Equatable {
  const HelperLocationState();
  @override
  List<Object?> get props => [];
}

class LocationInitial extends HelperLocationState {}

class LocationTracking extends HelperLocationState {
  final HelperLocationStatus? status;
  final InstantEligibility? eligibility;
  final HubConnectionState connectionState;
  final Position? lastPosition;
  final bool isUpdating;

  const LocationTracking({
    this.status,
    this.eligibility,
    this.connectionState = HubConnectionState.Disconnected,
    this.lastPosition,
    this.isUpdating = false,
  });

  LocationTracking copyWith({
    HelperLocationStatus? status,
    InstantEligibility? eligibility,
    HubConnectionState? connectionState,
    Position? lastPosition,
    bool? isUpdating,
  }) {
    return LocationTracking(
      status: status ?? this.status,
      eligibility: eligibility ?? this.eligibility,
      connectionState: connectionState ?? this.connectionState,
      lastPosition: lastPosition ?? this.lastPosition,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }

  @override
  List<Object?> get props => [status, eligibility, connectionState, lastPosition, isUpdating];
}

class LocationError extends HelperLocationState {
  final String message;
  const LocationError(this.message);
  @override
  List<Object?> get props => [message];
}

class HelperLocationCubit extends Cubit<HelperLocationState> {
  final SendLocationUseCase sendLocationUseCase;
  final GetLocationStatusUseCase getStatusUseCase;
  final GetInstantEligibilityUseCase getEligibilityUseCase;
  final ConnectLocationHubUseCase connectUseCase;
  final DisconnectLocationHubUseCase disconnectUseCase;
  final GetLocationConnectionStateUseCase connectionStateUseCase;

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<HubConnectionState>? _connectionSubscription;
  Timer? _statusTimer;
  DateTime? _lastUpdateTime;

  HelperLocationCubit({
    required this.sendLocationUseCase,
    required this.getStatusUseCase,
    required this.getEligibilityUseCase,
    required this.connectUseCase,
    required this.disconnectUseCase,
    required this.connectionStateUseCase,
  }) : super(LocationInitial());

  Future<void> startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(const LocationError('Location services are disabled.'));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(const LocationError('Location permissions are denied.'));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      emit(const LocationError('Location permissions are permanently denied.'));
      return;
    }

    emit(const LocationTracking());

    // Connect SignalR
    await connectUseCase();
    _connectionSubscription = connectionStateUseCase().listen((state) {
      if (this.state is LocationTracking) {
        emit((this.state as LocationTracking).copyWith(connectionState: state));
      }
    });

    // Start Location Streaming
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(_handlePositionUpdate);

    // Initial Data Fetch
    await refreshStatus();
    await refreshEligibility();

    // Periodic Status Refresh (e.g., every 60 seconds)
    _statusTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      refreshStatus();
    });
  }

  void _handlePositionUpdate(Position position) {
    if (state is! LocationTracking) return;

    final now = DateTime.now();
    // Throttle updates to at most once every 20 seconds unless moved significantly (handled by distanceFilter)
    if (_lastUpdateTime != null && now.difference(_lastUpdateTime!).inSeconds < 20) {
      return;
    }

    _lastUpdateTime = now;
    final update = HelperLocationUpdate(
      latitude: position.latitude,
      longitude: position.longitude,
      heading: position.heading,
      speedKmh: position.speed * 3.6,
      accuracyMeters: position.accuracy,
    );

    sendLocationUseCase(update);
    emit((state as LocationTracking).copyWith(lastPosition: position));
  }

  Future<void> refreshStatus() async {
    if (state is! LocationTracking) return;
    final result = await getStatusUseCase();
    result.fold(
      (failure) => null, // Silently fail for background updates
      (status) => emit((state as LocationTracking).copyWith(status: status)),
    );
  }

  Future<void> refreshEligibility() async {
    if (state is! LocationTracking) return;
    emit((state as LocationTracking).copyWith(isUpdating: true));
    final result = await getEligibilityUseCase();
    result.fold(
      (failure) => emit(LocationError(failure.message)),
      (eligibility) => emit((state as LocationTracking).copyWith(eligibility: eligibility, isUpdating: false)),
    );
  }

  Future<void> stopTracking() async {
    _statusTimer?.cancel();
    _positionSubscription?.cancel();
    _connectionSubscription?.cancel();
    await disconnectUseCase();
    emit(LocationInitial());
  }

  @override
  Future<void> close() {
    _statusTimer?.cancel();
    _positionSubscription?.cancel();
    _connectionSubscription?.cancel();
    return super.close();
  }
}
