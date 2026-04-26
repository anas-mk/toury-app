import 'dart:async';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import '../../../../../../core/config/api_config.dart';

enum SignalRConnectionState { connecting, connected, disconnected, error }

class HelperLocationSignalRService {
  HubConnection? _hubConnection;
  final _stateController = StreamController<SignalRConnectionState>.broadcast();
  Stream<SignalRConnectionState> get stateStream => _stateController.stream;
  
  SignalRConnectionState _currentState = SignalRConnectionState.disconnected;
  SignalRConnectionState get currentState => _currentState;

  void _updateState(SignalRConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> connect(String token) async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    _updateState(SignalRConnectionState.connecting);

    final httpOptions = HttpConnectionOptions(
      accessTokenFactory: () async => token,
    );

    _hubConnection = HubConnectionBuilder()
        .withUrl(ApiConfig.bookingHub, options: httpOptions)
        .withAutomaticReconnect()
        .build();

    _hubConnection!.onclose(({error}) {
      _updateState(SignalRConnectionState.disconnected);
    });

    _hubConnection!.onreconnecting(({error}) {
      _updateState(SignalRConnectionState.connecting);
    });

    _hubConnection!.onreconnected(({connectionId}) {
      _updateState(SignalRConnectionState.connected);
    });

    try {
      await _hubConnection!.start();
      _updateState(SignalRConnectionState.connected);
    } catch (e) {
      _updateState(SignalRConnectionState.error);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _updateState(SignalRConnectionState.disconnected);
  }

  Future<void> sendLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speedKmh,
    double? accuracyMeters,
  }) async {
    if (_hubConnection?.state != HubConnectionState.Connected) {
      throw Exception('SignalR not connected');
    }

    await _hubConnection!.invoke('SendLocation', args: [
      {
        'latitude': lat,
        'longitude': lng,
        'heading': heading,
        'speedKmh': speedKmh,
        'accuracyMeters': accuracyMeters,
        'timestamp': DateTime.now().toIso8601String(),
      }
    ]);
  }

  void dispose() {
    _stateController.close();
    disconnect();
  }
}
