import 'dart:async';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

import '../../config/api_config.dart';
import 'package:toury/core/models/tracking/tracking_point_model.dart';
import 'package:toury/core/models/tracking/tracking_update.dart';
import 'package:flutter/foundation.dart';

class BookingTrackingHubService {
  HubConnection? _hubConnection;
  
  // Stream Controllers for different event types
  final _locationController = StreamController<TrackingUpdate>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _requestController = StreamController<Map<String, dynamic>>.broadcast();
  final _dashboardController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();

  BookingTrackingHubService();

  // Public Getters for Streams
  Stream<TrackingUpdate> get locationStream => _locationController.stream;
  @Deprecated('Use locationStream instead')
  Stream<TrackingUpdate> get updateStream => _locationController.stream;
  
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get requestStream => _requestController.stream;
  Stream<Map<String, dynamic>> get dashboardStream => _dashboardController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;

  Future<void> connect(String token) async {
    final hubUrl = ApiConfig.bookingHub;
    
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 15000])
        .build();

    _hubConnection?.onclose(({error}) {
      debugPrint('📡 SignalR Disconnected: $error');
    });

    _hubConnection?.onreconnecting(({error}) {
      debugPrint('📡 SignalR Reconnecting...');
    });

    _hubConnection?.onreconnected(({connectionId}) {
      debugPrint('📡 SignalR Reconnected. ID: $connectionId');
      // No manual join needed per spec §5.2
    });

    _registerHandlers();

    try {
      await _hubConnection?.start();
      debugPrint('📡 SignalR: Connected to $hubUrl');
    } catch (e) {
      debugPrint('📡 SignalR Error: $e');
      rethrow;
    }
  }

  void _registerHandlers() {
    if (_hubConnection == null) return;

    // 1. Location & Tracking
    _hubConnection!.on('HelperLocationUpdate', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        final point = TrackingPointModel.fromJson(data['point'] ?? data);
        
        _locationController.add(TrackingUpdate(
          point: point,
          status: data['status'],
          distanceToTarget: data['distanceToTarget'] != null ? (data['distanceToTarget'] as num).toDouble() : null,
          etaMinutes: data['etaMinutes'] != null ? (data['etaMinutes'] as num).toInt() : null,
        ));
      }
    });

    // 2. Booking Status & Lifecycle
    _hubConnection!.on('BookingStatusChanged', (args) => _statusController.add(args!.first as Map<String, dynamic>));
    _hubConnection!.on('BookingCancelled', (args) => _statusController.add(args!.first as Map<String, dynamic>));
    _hubConnection!.on('BookingPaymentChanged', (args) => _statusController.add(args!.first as Map<String, dynamic>));
    _hubConnection!.on('BookingTripStarted', (args) => _statusController.add(args!.first as Map<String, dynamic>));
    _hubConnection!.on('BookingTripEnded', (args) => _statusController.add(args!.first as Map<String, dynamic>));

    // 3. Helper Requests
    _hubConnection!.on('RequestIncoming', (args) => _requestController.add(args!.first as Map<String, dynamic>));
    _hubConnection!.on('RequestRemoved', (args) => _requestController.add(args!.first as Map<String, dynamic>));

    // 4. Helper Dashboard & Availability
    _hubConnection!.on('HelperDashboardChanged', (args) => _dashboardController.add(args!.first as Map<String, dynamic>));
    _hubConnection!.on('HelperAvailabilityChanged', (args) => _dashboardController.add(args!.first as Map<String, dynamic>));
    _hubConnection!.on('HelperApprovalChanged', (args) => _dashboardController.add(args!.first as Map<String, dynamic>));
    _hubConnection!.on('HelperBanStatusChanged', (args) => _dashboardController.add(args!.first as Map<String, dynamic>));
    _hubConnection!.on('HelperSuspensionChanged', (args) => _dashboardController.add(args!.first as Map<String, dynamic>));

    // 5. Chat
    _hubConnection!.on('ChatMessage', (args) => _chatController.add(args!.first as Map<String, dynamic>));

    // 6. Diagnostics
    _hubConnection!.on('Pong', (args) => debugPrint('📡 SignalR Pong: ${args!.first}'));
  }

  Future<void> sendLocation(double lat, double lng, {double? heading, double? speedKmh, double? accuracyMeters}) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      // Build args as non-nullable; pass 0 for missing optional values — server ignores them if null-equivalent.
      final List<Object> args = [lat, lng, heading ?? 0.0, speedKmh ?? 0.0, accuracyMeters ?? 0.0];
      await _hubConnection!.invoke('SendLocation', args: args);
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }
}
