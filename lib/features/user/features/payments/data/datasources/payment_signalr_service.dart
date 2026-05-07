import 'dart:async';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import '../../../../../../core/config/api_config.dart';

class PaymentSignalRService {
  HubConnection? _hubConnection;
  final _paymentUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get paymentUpdates => _paymentUpdateController.stream;

  Future<void> connect(String token) async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          '${ApiConfig.baseUrl}/hubs/payments',
          options: HttpConnectionOptions(
            accessTokenFactory: () => Future.value(token),
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on('BookingPaymentChanged', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _paymentUpdateController.add(data);
      }
    });

    try {
      await _hubConnection?.start();
    } catch (e) {
      // Handle connection error
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _hubConnection = null;
  }
}
