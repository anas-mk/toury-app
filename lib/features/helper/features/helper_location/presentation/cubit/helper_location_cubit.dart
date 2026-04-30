import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/services/helper_location_signalr_service.dart';
import '../../data/services/helper_location_tracker.dart';
import '../../domain/entities/helper_location_entities.dart';
import '../../domain/usecases/helper_location_usecases.dart';
import 'package:toury/features/helper/features/helper_bookings/domain/entities/helper_availability_state.dart';

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

  const HelperLocationTracking({
    required this.location,
    required this.connectionState,
    this.isUsingFallback = false,
  });

  @override
  List<Object?> get props => [location, connectionState, isUsingFallback];
}

class HelperLocationPermissionDenied extends HelperLocationState {}

class HelperLocationError extends HelperLocationState {
  final String message;
  const HelperLocationError(this.message);
  @override
  List<Object?> get props => [message];
}

class HelperLocationCubit extends Cubit<HelperLocationState> {
  final HelperLocationTracker tracker;
  final ConnectSignalRUseCase connectUseCase;
  final DisconnectSignalRUseCase disconnectUseCase;
  final StreamLocationUseCase streamUseCase;
  final UpdateLocationUseCase updateUseCase;
  final Stream<SignalRConnectionState> signalRStateStream;

  StreamSubscription? _locationSubscription;
  StreamSubscription? _signalRSubscription;
  SignalRConnectionState _currentSignalRState = SignalRConnectionState.disconnected;
  bool _trackingStarted = false;
  bool _locationRequestInFlight = false;
  HelperAvailabilityState _availabilityState = HelperAvailabilityState.offline;
  int _trackingSessionId = 0;

  // Optimization: Debouncing and thresholding
  DateTime? _lastApiUpdateTime;
  DateTime? _lastLocationSampleTime;
  HelperLocation? _lastUpdateLocation;
  static const Duration _apiThrottle = Duration(seconds: 8);
  static const Duration _sampleMinInterval = Duration(seconds: 3);
  static const double _distanceThresholdMeters = 25.0;

  HelperLocationCubit({
    required this.tracker,
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
        ));
      }
    });
  }

  Future<void> startTracking(String token) async {
    if (isClosed) return;
    if (_availabilityState != HelperAvailabilityState.availableNow) {
      debugPrint('[Location] startTracking skipped: availability=$_availabilityState');
      return;
    }

    // Prevent duplicate tracking
    if (_trackingStarted || _locationSubscription != null) {
      debugPrint('[Location] Tracking already started, skipping');
      return;
    }

    try {
      final sessionId = ++_trackingSessionId;
      _trackingStarted = true;
      await connectUseCase.execute(token);
      if (isClosed) return;

      await tracker.startTracking(intervalSeconds: 5);
      _locationSubscription = tracker.locationStream.listen((location) async {
        if (isClosed) return;
        if (sessionId != _trackingSessionId) {
          // Late event from an old tracking session: ignore completely.
          return;
        }
        if (_availabilityState != HelperAvailabilityState.availableNow) {
          return;
        }

        final now = DateTime.now();
        final sampledTooSoon = _lastLocationSampleTime != null &&
            now.difference(_lastLocationSampleTime!) < _sampleMinInterval;
        if (sampledTooSoon) {
          return;
        }
        _lastLocationSampleTime = now;

        final shouldUpdateBackend = _shouldUpdateBackend(location);
        bool fallback = false;

        if (shouldUpdateBackend) {
          if (_locationRequestInFlight) {
            debugPrint('[Location] Update skipped: in-flight');
          } else {
            _locationRequestInFlight = true;
            if (_currentSignalRState == SignalRConnectionState.connected) {
              try {
                await streamUseCase.execute(location);
              } catch (e) {
                fallback = true;
              }
            } else {
              fallback = true;
            }

            if (fallback) {
              try {
                await updateUseCase.execute(location);
              } catch (e) {
                // Silently handle fallback errors to avoid disrupting UI
              }
            }

            _locationRequestInFlight = false;
            _lastApiUpdateTime = DateTime.now();
            _lastUpdateLocation = location;
          }
        }

        if (!isClosed) {
          emit(HelperLocationTracking(
            location: location,
            connectionState: _currentSignalRState,
            isUsingFallback: fallback,
          ));
        }
      });
    } catch (e) {
      _trackingStarted = false;
      if (!isClosed) {
        emit(HelperLocationError(e.toString()));
      }
    }
  }

  bool _shouldUpdateBackend(HelperLocation newLoc) {
    if (_availabilityState != HelperAvailabilityState.availableNow) {
      return false;
    }

    if (_lastApiUpdateTime == null || _lastUpdateLocation == null) return true;

    final timeDiff = DateTime.now().difference(_lastApiUpdateTime!);
    if (timeDiff < _apiThrottle) return false;

    final prev = _lastUpdateLocation!;
    final movedMeters = tracker.distanceBetweenMeters(
      prev.latitude,
      prev.longitude,
      newLoc.latitude,
      newLoc.longitude,
    );
    return movedMeters >= _distanceThresholdMeters;
  }

  Future<void> stopTracking() async {
    _trackingSessionId++;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _trackingStarted = false;
    _locationRequestInFlight = false;
    await tracker.stopTracking();
    await disconnectUseCase.execute();
    if (!isClosed) {
      emit(HelperLocationInitial());
    }
  }

  void setAvailabilityState(HelperAvailabilityState status) {
    _availabilityState = status;
    if (status != HelperAvailabilityState.availableNow &&
        (_trackingStarted || _locationSubscription != null)) {
      unawaited(stopTracking());
    }
  }

  Future<void> reconnect(String token) async {
    if (isClosed) return;
    await connectUseCase.execute(token);
  }

  /// Full post-login init: request permission → get position → send to API → start 30s tracking.
  /// Returns true if permission was granted, false if denied.
  Future<bool> requestPermissionAndInitialize(String token) async {
    if (isClosed) return false;

    final hasPermission = await tracker.checkPermission();
    if (!hasPermission) {
      if (!isClosed) emit(HelperLocationPermissionDenied());
      return false;
    }

    // Immediately send current position
    try {
      final location = await tracker.getCurrentLocation();
      if (_availabilityState == HelperAvailabilityState.availableNow) {
        await updateUseCase.execute(location);
        _lastApiUpdateTime = DateTime.now();
        _lastUpdateLocation = location;
      }
      if (!isClosed) {
        emit(HelperLocationTracking(
          location: location,
          connectionState: _currentSignalRState,
        ));
      }
    } catch (_) {
      // Non-fatal: continue to start continuous tracking
    }

    // Start continuous tracking only when helper is online.
    await startTracking(token);
    return true;
  }

  @override
  Future<void> close() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _trackingStarted = false;
    await _signalRSubscription?.cancel();
    _signalRSubscription = null;
    return super.close();
  }
}