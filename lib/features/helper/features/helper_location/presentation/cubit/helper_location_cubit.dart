import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/services/helper_location_signalr_service.dart';
import '../../data/services/helper_location_tracker.dart';
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

  const HelperLocationTracking({
    required this.location,
    required this.connectionState,
    this.isUsingFallback = false,
  });

  @override
  List<Object?> get props => [location, connectionState, isUsingFallback];
}

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
  
  // Optimization: Debouncing and thresholding
  DateTime? _lastApiUpdateTime;
  HelperLocation? _lastUpdateLocation;
  static const Duration _updateThreshold = Duration(seconds: 10);
  static const double _distanceThresholdMeters = 10.0;

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
    
    // Prevent duplicate tracking
    if (_locationSubscription != null) return;

    try {
      await connectUseCase.execute(token);
      if (isClosed) return;

      await tracker.startTracking(intervalSeconds: 10);
      _locationSubscription = tracker.locationStream.listen((location) async {
        if (isClosed) return;

        bool shouldUpdateBackend = _shouldUpdateBackend(location);
        bool fallback = false;

        if (shouldUpdateBackend) {
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
          
          _lastApiUpdateTime = DateTime.now();
          _lastUpdateLocation = location;
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
      if (!isClosed) {
        emit(HelperLocationError(e.toString()));
      }
    }
  }

  bool _shouldUpdateBackend(HelperLocation newLoc) {
    if (_lastApiUpdateTime == null || _lastUpdateLocation == null) return true;

    final timeDiff = DateTime.now().difference(_lastApiUpdateTime!);
    if (timeDiff < _updateThreshold) return false;

    // Optional: Add distance threshold check here if needed
    // For now, time threshold + distanceFilter in tracker is enough
    return true;
  }

  Future<void> stopTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await tracker.stopTracking();
    await disconnectUseCase.execute();
    if (!isClosed) {
      emit(HelperLocationInitial());
    }
  }

  Future<void> reconnect(String token) async {
    if (isClosed) return;
    await connectUseCase.execute(token);
  }

  @override
  Future<void> close() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _signalRSubscription?.cancel();
    _signalRSubscription = null;
    return super.close();
  }
}
