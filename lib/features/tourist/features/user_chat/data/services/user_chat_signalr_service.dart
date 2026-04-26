import 'dart:async';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import '../../../../../../core/config/api_config.dart';
import '../models/user_chat_models.dart';

enum UserChatSignalRState { connecting, connected, disconnected, error }

class UserChatSignalRService {
  HubConnection? _hubConnection;
  
  final _stateController = StreamController<UserChatSignalRState>.broadcast();
  Stream<UserChatSignalRState> get stateStream => _stateController.stream;
  
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  Stream<ChatMessageModel> get messageStream => _messageController.stream;

  UserChatSignalRState _currentState = UserChatSignalRState.disconnected;
  UserChatSignalRState get currentState => _currentState;

  void _updateState(UserChatSignalRState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> connect(String token) async {
    if (_hubConnection?.state == HubConnectionState.Connected) return;

    _updateState(UserChatSignalRState.connecting);

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
      _updateState(UserChatSignalRState.disconnected);
    });

    _hubConnection!.onreconnecting(({error}) {
      _updateState(UserChatSignalRState.connecting);
    });

    _hubConnection!.onreconnected(({connectionId}) {
      _updateState(UserChatSignalRState.connected);
    });

    try {
      await _hubConnection!.start();
      _updateState(UserChatSignalRState.connected);
    } catch (e) {
      _updateState(UserChatSignalRState.error);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _hubConnection?.stop();
    _updateState(UserChatSignalRState.disconnected);
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
