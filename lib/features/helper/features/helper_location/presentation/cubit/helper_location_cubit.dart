import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../../core/services/location_service.dart';
import '../../data/services/helper_location_signalr_service.dart';
import '../../domain/entities/helper_location_entities.dart';
import '../../domain/usecases/helper_location_usecases.dart';

abstract class HelperLocationState extends Equatable {
  const HelperLocationState();
  @override
  List<Object?> get props => [];
}

class HelperLocationInitial extends HelperLocationState {}

class HelperLocationTracking extends HelperLocationState {
  final HelperLocation location;
  final SignalRConnectionState connectionState;
  final bool isUsingFallback;
  final bool isEnabled;

  const HelperLocationTracking({
    required this.location,
    required this.connectionState,
    this.isUsingFallback = false,
    required this.isEnabled,
  });

  @override
  List<Object?> get props => [location, connectionState, isUsingFallback, isEnabled];
}

class HelperLocationPermissionDenied extends HelperLocationState {}

class HelperLocationError extends HelperLocationState {
  final String message;
  const HelperLocationError(this.message);
  @override
  List<Object?> get props => [message];
}

class HelperLocationCubit extends Cubit<HelperLocationState> {
  final LocationService locationService;
  final ConnectSignalRUseCase connectUseCase;
  final DisconnectSignalRUseCase disconnectUseCase;
  final StreamLocationUseCase streamUseCase;
  final UpdateLocationUseCase updateUseCase;
  final Stream<SignalRConnectionState> signalRStateStream;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription? _signalRSubscription;
  SignalRConnectionState _currentSignalRState = SignalRConnectionState.disconnected;
  
  bool _enabled = false;

  // Backend throttling (separate from LocationService's local stream throttling).
  DateTime? _lastBackendSendAt;
  HelperLocation? _lastBackendLocation;
  static const Duration _backendMinInterval = Duration(seconds: 4);
  static const double _backendMinDistanceMeters = 8.0;

  HelperLocationCubit({
    required this.locationService,
    required this.connectUseCase,
    required this.disconnectUseCase,
    required this.streamUseCase,
    required this.updateUseCase,
    required this.signalRStateStream,
  }) : super(HelperLocationInitial()) {
    _signalRSubscription = signalRStateStream.listen((state) {
      if (isClosed) return;
      _currentSignalRState = state;
      
      final currentState = this.state;
      if (currentState is HelperLocationTracking) {
        emit(HelperLocationTracking(
          location: currentState.location,
          connectionState: _currentSignalRState,
          isUsingFallback: currentState.isUsingFallback,
          isEnabled: currentState.isEnabled,
        ));
      }
    });
  }

  /// Enables location tracking for the helper session (idempotent).
  ///
  /// This is the ONLY entry point to start sending updates to the backend.
  /// UI pages must never call this from `build()`.
  Future<void> enable(String token) async {
    if (isClosed) return;

    if (_enabled && _positionSub != null) return;
    _enabled = true;

    try {
      await connectUseCase.execute(token);
      if (isClosed) return;

      await locationService.startTracking();
      _positionSub ??= locationService.positionStream.listen(
        (pos) => unawaited(_onPosition(pos)),
        onError: (e) {
          if (!isClosed) emit(HelperLocationError(e.toString()));
        },
        cancelOnError: false,
      );
    } catch (e) {
      if (!isClosed) {
        emit(HelperLocationError(e.toString()));
      }
    }
  }

  Future<void> _onPosition(Position pos) async {
    if (isClosed) return;

    final location = HelperLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      heading: pos.heading.isNaN ? null : pos.heading,
      speedKmh: pos.speed.isNaN ? null : (pos.speed * 3.6),
      accuracyMeters: pos.accuracy.isNaN ? null : pos.accuracy,
      timestamp: DateTime.now(),
    );

    final fallbackUsed = await _maybeSendToBackend(location);

    if (!isClosed) {
      emit(HelperLocationTracking(
        location: location,
        connectionState: _currentSignalRState,
        isUsingFallback: fallbackUsed,
        isEnabled: _enabled,
      ));
    }
  }

  bool _shouldSendToBackend(HelperLocation loc) {
    final now = DateTime.now();

    if (_lastBackendSendAt == null || _lastBackendLocation == null) return true;
    if (now.difference(_lastBackendSendAt!) < _backendMinInterval) return false;

    final last = _lastBackendLocation!;
    final distance = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      loc.latitude,
      loc.longitude,
    );
    if (distance < _backendMinDistanceMeters) return false;

    return true;
  }

  Future<bool> _maybeSendToBackend(HelperLocation loc) async {
    if (!_enabled) return false;
    if (!_shouldSendToBackend(loc)) return false;

    bool fallback = false;
    try {
      if (_currentSignalRState == SignalRConnectionState.connected) {
        await streamUseCase.execute(loc);
      } else {
        fallback = true;
      }
    } catch (_) {
      fallback = true;
    }

    if (fallback) {
      try {
        await updateUseCase.execute(loc);
      } catch (_) {
        // Swallow: backend failures should not kill the UI stream.
      }
    }

    _lastBackendSendAt = DateTime.now();
    _lastBackendLocation = loc;
    return fallback;
  }

  /// Disables tracking and backend updates.
  Future<void> disable() async {
    _enabled = false;

    await _positionSub?.cancel();
    _positionSub = null;

    await locationService.stopTracking();
    await disconnectUseCase.execute();

    _lastBackendSendAt = null;
    _lastBackendLocation = null;
    if (!isClosed) {
      emit(HelperLocationInitial());
    }
  }

  Future<void> reconnect(String token) async {
    if (isClosed) return;
    await connectUseCase.execute(token);
  }

  /// One-shot permission gate used before enabling "online" mode.
  Future<bool> requestPermissionAndInitialize(String token) async {
    if (isClosed) return false;

    final hasPermission = await locationService.checkPermissions();
    if (!hasPermission) {
      if (!isClosed) emit(HelperLocationPermissionDenied());
      return false;
    }

    // Kick a single update ASAP (best effort) then enable continuous tracking.
    try {
      final pos = await locationService.getCurrentPosition();
      if (pos != null) {
        final loc = HelperLocation(
          latitude: pos.latitude,
          longitude: pos.longitude,
          heading: pos.heading.isNaN ? null : pos.heading,
          speedKmh: pos.speed.isNaN ? null : (pos.speed * 3.6),
          accuracyMeters: pos.accuracy.isNaN ? null : pos.accuracy,
          timestamp: DateTime.now(),
        );
        await updateUseCase.execute(loc);
        _lastBackendSendAt = DateTime.now();
        _lastBackendLocation = loc;
        if (!isClosed) {
          emit(HelperLocationTracking(
            location: loc,
            connectionState: _currentSignalRState,
            isEnabled: true,
          ));
        }
      }
    } catch (_) {}

    await enable(token);
    return true;
  }

  @override
  Future<void> close() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _signalRSubscription?.cancel();
    _signalRSubscription = null;
    return super.close();
  }
}
