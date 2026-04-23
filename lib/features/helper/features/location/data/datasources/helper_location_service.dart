import 'dart:async';
import 'package:dio/dio.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/services/auth_service.dart';
import '../models/location_models.dart';

abstract class HelperLocationService {
  Future<void> updateLocation(HelperLocationUpdate update);
  Future<HelperLocationStatus> getStatus();
  Future<InstantEligibility> getInstantEligibility();
  Stream<HubConnectionState> get connectionState;
  Future<void> connect();
  Future<void> disconnect();
}

class HelperLocationServiceImpl implements HelperLocationService {
  final Dio dio;
  final AuthService authService;
  HubConnection? _hubConnection;
  final _connectionStateController = StreamController<HubConnectionState>.broadcast();

  HelperLocationServiceImpl({required this.dio, required this.authService});

  @override
  Stream<HubConnectionState> get connectionState => _connectionStateController.stream;

  @override
  Future<void> connect() async {
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) return;

    final token = authService.getToken();
    final hubUrl = '${ApiConfig.baseUrl}/hubs/booking';

    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl, options: HttpConnectionOptions(
          accessTokenFactory: () async => token ?? '',
        ))
        .withAutomaticReconnect()
        .build();

    _hubConnection!.onclose(({error}) {
      _connectionStateController.add(HubConnectionState.Disconnected);
    });

    _hubConnection!.onreconnecting(({error}) {
      _connectionStateController.add(HubConnectionState.Reconnecting);
    });

    _hubConnection!.onreconnected(({connectionId}) {
      _connectionStateController.add(HubConnectionState.Connected);
    });

    try {
      await _hubConnection!.start();
      _connectionStateController.add(HubConnectionState.Connected);
    } catch (e) {
      _connectionStateController.add(HubConnectionState.Disconnected);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }

  @override
  Future<void> updateLocation(HelperLocationUpdate update) async {
    // Try SignalR first
    if (_hubConnection != null && _hubConnection!.state == HubConnectionState.Connected) {
      try {
        await _hubConnection!.invoke('SendLocation', args: [update.toJson()]);
        print('📡 SignalR: Location updated successfully');
        return;
      } catch (e) {
        print('📡 SignalR: Failed to send location, falling back to HTTP: $e');
      }
    }

    // Fallback to HTTP
    await dio.post('/helper/location/update', data: update.toJson());
    print('🌐 HTTP: Location updated successfully (Fallback)');
  }

  @override
  Future<HelperLocationStatus> getStatus() async {
    final response = await dio.get('/helper/location/status');
    return HelperLocationStatus.fromJson(response.data);
  }

  @override
  Future<InstantEligibility> getInstantEligibility() async {
    final response = await dio.get('/helper/location/instant-eligibility');
    return InstantEligibility.fromJson(response.data);
  }
}
