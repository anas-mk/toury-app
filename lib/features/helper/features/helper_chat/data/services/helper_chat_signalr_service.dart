import 'dart:async';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import '../../../../../../core/config/api_config.dart';
import '../models/helper_chat_models.dart';

enum ChatSignalRState { connecting, connected, disconnected, error }

class HelperChatSignalRService {
  HubConnection? _hubConnection;
  
  final _stateController = StreamController<ChatSignalRState>.broadcast();
  Stream<ChatSignalRState> get stateStream => _stateController.stream;
  
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  Stream<ChatMessageModel> get messageStream => _messageController.stream;

  ChatSignalRState _currentState = ChatSignalRState.disconnected;
  ChatSignalRState get currentState => _currentState;

  void _updateState(ChatSignalRState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> connect(String token) async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    _updateState(ChatSignalRState.connecting);

    final httpOptions = HttpConnectionOptions(
      accessTokenFactory: () async => token,
    );

    _hubConnection = HubConnectionBuilder()
        .withUrl(ApiConfig.bookingHub, options: httpOptions)
        .withAutomaticReconnect()
        .build();

    // Listen for messages
    _hubConnection!.on('ReceiveChatMessage', (args) {
      if (args != null && args.isNotEmpty) {
        final data = args[0] as Map<String, dynamic>;
        _messageController.add(ChatMessageModel.fromJson(data));
      }
    });

    _hubConnection!.onclose(({error}) {
      _updateState(ChatSignalRState.disconnected);
    });

    _hubConnection!.onreconnecting(({error}) {
      _updateState(ChatSignalRState.connecting);
    });

    _hubConnection!.onreconnected(({connectionId}) {
      _updateState(ChatSignalRState.connected);
    });

    try {
      await _hubConnection!.start();
      _updateState(ChatSignalRState.connected);
    } catch (e) {
      _updateState(ChatSignalRState.error);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _updateState(ChatSignalRState.disconnected);
  }

  Future<void> joinBookingRoom(String bookingId) async {
    if (_hubConnection?.state != HubConnectionState.Connected) return;
    await _hubConnection!.invoke('JoinBookingRoom', args: [bookingId]);
  }

  Future<void> leaveBookingRoom(String bookingId) async {
    if (_hubConnection?.state != HubConnectionState.Connected) return;
    await _hubConnection!.invoke('LeaveBookingRoom', args: [bookingId]);
  }

  void dispose() {
    _stateController.close();
    _messageController.close();
    disconnect();
  }
}
