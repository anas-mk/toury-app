import 'dart:async';
import 'package:flutter/foundation.dart';
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

    // Listen for incoming messages.
    //
    // Backend wire-format (per Flutter-Booking-Realtime-Guide § 9.3):
    // event name `ChatMessage`, payload fields:
    //   { bookingId, conversationId, messageId, senderId, senderType,
    //     senderName, recipientId, recipientType, messageType,
    //     preview, sentAt }
    //
    // Note: `preview` is truncated to 100 chars on the server. We use
    // it as the initial body text — sufficient for typical chat msgs.
    // For long messages the consumer can re-fetch via REST if needed.
    //
    // The sender does NOT receive an echo for their own messages —
    // the cubit appends its own outgoing message from the POST
    // response directly.
    _hubConnection!.on('ChatMessage', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args[0];
      if (raw is! Map) return;
      final data = Map<String, dynamic>.from(raw);
      // Normalise the realtime payload onto the same shape our
      // [ChatMessageModel.fromJson] (used for REST history) expects.
      // Backend uses `messageId` here but `id` on the REST resource.
      data['id'] ??= data['messageId'];
      // The realtime event has `preview`; the REST row uses `text`.
      data['text'] ??= data['preview'];
      data['isRead'] ??= false;
      try {
        _messageController.add(ChatMessageModel.fromJson(data));
      } catch (_) {
        // Don't crash the stream on a malformed event — skip it.
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
    try {
      await _hubConnection!.invoke('JoinBookingRoom', args: [bookingId]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'UserChatSignalRService: JoinBookingRoom failed -> $e');
      }
    }
  }

  Future<void> leaveBookingRoom(String bookingId) async {
    if (_hubConnection?.state != HubConnectionState.Connected) return;
    try {
      await _hubConnection!.invoke('LeaveBookingRoom', args: [bookingId]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            'UserChatSignalRService: LeaveBookingRoom failed -> $e');
      }
    }
  }

  void dispose() {
    _stateController.close();
    _messageController.close();
    disconnect();
  }
}
