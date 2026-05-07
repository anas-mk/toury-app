import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../../core/services/location_service.dart' show LocationService;
import '../../../../../../core/services/auth_service.dart';
import '../../domain/entities/helper_location_entities.dart';
import '../../domain/entities/signalr_connection_state.dart';
import '../../domain/usecases/helper_location_usecases.dart';
import '../../../helper_bookings/domain/entities/helper_availability_state.dart';

/// Centralized service for Helper location tracking with strict Auth lifecycle.
class HelperLocationTrackingService {
  HelperLocationTrackingService({
    required LocationService coreLocationService,
    required AuthService authService,
    required StreamLocationUseCase streamUseCase,
    required UpdateLocationUseCase updateUseCase,
    required ConnectSignalRUseCase connectUseCase,
    required DisconnectSignalRUseCase disconnectUseCase,
    required Stream<SignalRConnectionState> signalRStateStream,
  })  : _coreLocationService = coreLocationService,
        _authService = authService,
        _streamUseCase = streamUseCase,
        _updateUseCase = updateUseCase,
        _connectUseCase = connectUseCase,
        _disconnectUseCase = disconnectUseCase {
    
    // 1. Listen to global SignalR state
    _signalRSubscription = signalRStateStream.listen((state) {
      _currentSignalRState = state;
      debugPrint('[HelperLocationService] SignalR State: ${state.name}');
    });

    // 2. Listen to Auth changes to handle token refresh or logout
    _authSubscription = _authService.authTokenChanges.listen((token) {
      debugPrint('[HelperLocationService] Token updated, refreshing tracking...');
      _authToken = token;
      if (_isTrackingStarted) {
        _restartTracking();
      }
    });

    // Initial token snapshot
    _authToken = _authService.getToken();
  }

  final LocationService _coreLocationService;
  final AuthService _authService;
  final StreamLocationUseCase _streamUseCase;
  final UpdateLocationUseCase _updateUseCase;
  final ConnectSignalRUseCase _connectUseCase;
  final DisconnectSignalRUseCase _disconnectUseCase;

  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<SignalRConnectionState>? _signalRSubscription;
  StreamSubscription<String>? _authSubscription;
  SignalRConnectionState _currentSignalRState = SignalRConnectionState.disconnected;
  SignalRConnectionState get currentSignalRState => _currentSignalRState;

  // State
  bool _isTrackingStarted = false;
  String? _activeBookingId;
  String? _authToken;
  HelperAvailabilityState _availability = HelperAvailabilityState.offline;

  // Throttling & Guards
  DateTime? _lastApiUpdateTime;
  HelperLocation? _lastUpdateLocation;
  bool _isRequestInFlight = false;

  // Broadcast stream for UI (Cubit)
  final _locationController = StreamController<HelperLocation>.broadcast();
  Stream<HelperLocation> get locationStream => _locationController.stream;

  // Constants - Production Uber-like settings
  static const Duration _idleThrottle = Duration(seconds: 10);
  static const Duration _tripThrottle = Duration(seconds: 4);
  static const Duration _heartbeatInterval = Duration(seconds: 15); // Guaranteed interval
  static const double _idleDistanceThreshold = 10.0; // More sensitive
  static const double _tripDistanceThreshold = 5.0;

  bool get isTracking => _isTrackingStarted;
  String? get activeBookingId => _activeBookingId;

  /// Update the tracking parameters. If online or in a trip, tracking will start/update.
  Future<bool> updateTrackingState({
    String? token,
    String? bookingId,
    HelperAvailabilityState? availability,
  }) async {
    _authToken = token ?? _authToken ?? _authService.getToken();
    _activeBookingId = bookingId ?? _activeBookingId;
    if (availability != null) _availability = availability;

    final shouldBeTracking = _availability == HelperAvailabilityState.availableNow || _activeBookingId != null;

    if (shouldBeTracking) {
      return await _startTracking();
    } else {
      await _stopTracking();
      return true;
    }
  }

  Future<bool> _startTracking() async {
    // Ensure we have a token before doing ANYTHING
    if (_authToken == null || _authToken!.isEmpty) {
      _authToken = _authService.getToken();
    }

    if (_authToken == null || _authToken!.isEmpty) {
      debugPrint('[HelperLocationService] CRITICAL: Cannot start tracking without token.');
      return false;
    }

    if (_isTrackingStarted) return true;

    final hasPermission = await _coreLocationService.checkPermissions();
    if (!hasPermission) {
      debugPrint('[HelperLocationService] Permission denied. Aborting.');
      return false;
    }

    debugPrint('[HelperLocationService] Starting tracking session (Token: ${_authToken!.substring(0, 5)}...)');
    _isTrackingStarted = true;

    // 1. Ensure SignalR is connected
    try {
      await _connectUseCase.execute(_authToken!);
    } catch (e) {
      debugPrint('[HelperLocationService] SignalR connection failed: $e');
    }

    // 2. Start core GPS (Android Foreground Service)
    await _coreLocationService.startTracking();
    
    // 3. Subscribe to GPS updates
    _gpsSubscription?.cancel();
    _gpsSubscription = _coreLocationService.positionStream.listen(_handlePositionUpdate);
    
    return true;
  }

  Future<void> _restartTracking() async {
    await _stopTracking();
    await _startTracking();
  }

  Future<void> _stopTracking() async {
    if (!_isTrackingStarted) return;
    
    debugPrint('[HelperLocationService] Stopping tracking session...');
    _isTrackingStarted = false;
    
    await _gpsSubscription?.cancel();
    _gpsSubscription = null;
    
    await _disconnectUseCase.execute();
    
    _lastApiUpdateTime = null;
    _lastUpdateLocation = null;
  }

  void _handlePositionUpdate(Position position) {
    final speedMps = position.speed.isFinite ? position.speed : 0.0;
    final speedKmh = speedMps > 0 ? speedMps * 3.6 : 0.0;
    final helperLoc = HelperLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      bookingId: _activeBookingId,
      heading: position.heading,
      speedKmh: speedKmh,
      accuracyMeters: position.accuracy,
      timestamp: position.timestamp,
    );

    _locationController.add(helperLoc);
    _maybeUpdateBackend(helperLoc);
  }

  Future<void> _maybeUpdateBackend(HelperLocation location) async {
    if (_isRequestInFlight) return;

    final isTrip = _activeBookingId != null;
    final throttle = isTrip ? _tripThrottle : _idleThrottle;
    final distanceThreshold = isTrip ? _tripDistanceThreshold : _idleDistanceThreshold;

    final now = DateTime.now();

    // 1. Minimum Throttle Check
    if (_lastApiUpdateTime != null && now.difference(_lastApiUpdateTime!) < throttle) {
      return;
    }

    // 2. Movement vs Heartbeat Check
    bool shouldUpdate = false;
    if (_lastUpdateLocation != null) {
      final distance = Geolocator.distanceBetween(
        _lastUpdateLocation!.latitude,
        _lastUpdateLocation!.longitude,
        location.latitude,
        location.longitude,
      );
      
      if (distance >= distanceThreshold) {
        shouldUpdate = true;
      } 
      // Heartbeat: Force update every 30s to keep backend "fresh"
      else if (now.difference(_lastApiUpdateTime!) >= _heartbeatInterval) {
        debugPrint('[HelperLocationService] Heartbeat: Sending stationary update.');
        shouldUpdate = true;
      }
    } else {
      shouldUpdate = true; // First update
    }

    if (!shouldUpdate) return;

    // 3. Security Guard: Ensure we still have a token
    if (_authToken == null || _authToken!.isEmpty) return;

    _isRequestInFlight = true;
    try {
      if (_currentSignalRState == SignalRConnectionState.connected) {
        await _streamUseCase.execute(location);
      } else {
        await _updateUseCase.execute(location);
      }
      _lastApiUpdateTime = now;
      _lastUpdateLocation = location;
    } catch (e) {
      debugPrint('[HelperLocationService] Backend update failed: $e');
    } finally {
      _isRequestInFlight = false;
    }
  }

  void dispose() {
    _gpsSubscription?.cancel();
    _signalRSubscription?.cancel();
    _authSubscription?.cancel();
    _locationController.close();
  }
}

