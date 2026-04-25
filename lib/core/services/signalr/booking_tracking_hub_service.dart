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
  final _updateController = StreamController<TrackingUpdate>.broadcast();

  BookingTrackingHubService();

  Stream<TrackingUpdate> get updateStream => _updateController.stream;

  Future<void> connect(String bookingId, String token) async {
    final hubUrl = '${ApiConfig.baseUrl}${ApiConfig.trackingHubUrl}';
    
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose(({error}) {
      debugPrint('📡 SignalR Disconnected: $error');
    });

    _hubConnection?.onreconnecting(({error}) {
      debugPrint('📡 SignalR Reconnecting...');
    });

    _hubConnection?.onreconnected(({connectionId}) {
      debugPrint('📡 SignalR Reconnected. ID: $connectionId');
      _joinBookingGroup(bookingId);
    });

    // Register Handlers
    _hubConnection?.on('HelperLocationUpdate', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        final point = TrackingPointModel.fromJson(data['point'] ?? data);
        
        _updateController.add(TrackingUpdate(
          point: point,
          status: data['status'],
          distanceToTarget: data['distanceToTarget'] != null ? (data['distanceToTarget'] as num).toDouble() : null,
          etaMinutes: data['etaMinutes'] != null ? (data['etaMinutes'] as num).toInt() : null,
        ));
      }
    });

    _hubConnection?.on('BookingTripStarted', (arguments) {
       debugPrint('📡 SignalR: Trip Started');
       // Handle trip started event if needed
    });

    _hubConnection?.on('BookingTripEnded', (arguments) {
       debugPrint('📡 SignalR: Trip Ended');
       // Handle trip ended event if needed
    });

    try {
      await _hubConnection?.start();
      debugPrint('📡 SignalR: Connected');
      await _joinBookingGroup(bookingId);
    } catch (e) {
      debugPrint('📡 SignalR Error: $e');
      rethrow;
    }
  }

  Future<void> _joinBookingGroup(String bookingId) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      await _hubConnection?.invoke('JoinBookingGroup', args: [bookingId]);
      debugPrint('📡 SignalR: Joined group booking:$bookingId');
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
    await _updateController.close();
  }
}
