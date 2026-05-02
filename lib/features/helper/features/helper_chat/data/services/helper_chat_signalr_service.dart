import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../../../core/services/realtime/booking_realtime_event_bus.dart';
import '../models/helper_chat_models.dart';

enum ChatSignalRState { connecting, connected, disconnected, error }

/// A proxy service that taps into the global [BookingRealtimeEventBus] 
/// instead of opening its own redundant SignalR connection.
///
/// This ensures we only have one socket open to `/hubs/booking` (managed 
/// by BookingTrackingHubService) while still providing a dedicated 
/// stream for the Helper Chat module.
class HelperChatSignalRService {
  final _stateController = StreamController<ChatSignalRState>.broadcast();
  Stream<ChatSignalRState> get stateStream => _stateController.stream;
  
  final _messageController = StreamController<ChatMessageModel>.broadcast();
  Stream<ChatMessageModel> get messageStream => _messageController.stream;

  ChatSignalRState _currentState = ChatSignalRState.disconnected;
  ChatSignalRState get currentState => _currentState;

  StreamSubscription? _busSubscription;

  HelperChatSignalRService() {
    _init();
  }

  void _init() {
    _busSubscription = BookingRealtimeEventBus.instance.stream.listen((event) {
      if (event is BusChatMessage) {
        final ev = event.event;
        // Convert ChatMessagePushEvent to ChatMessageModel
        final model = ChatMessageModel(
          id: ev.messageId ?? ev.eventId,
          senderId: ev.senderId ?? '',
          senderType: ev.senderType ?? '',
          messageType: ev.messageType ?? 'text',
          text: ev.text ?? ev.preview ?? '',
          sentAt: ev.sentAt ?? DateTime.now(),
          isRead: false,
        );
        debugPrint('📡 [HelperChat-Proxy] Received message for booking=${ev.bookingId}');
        _messageController.add(model);
      }
    });
    
    // Always report as connected if the global bus is attached, 
    // though the state is mostly managed by the primary hub service.
    _updateState(ChatSignalRState.connected);
  }

  void _updateState(ChatSignalRState state) {
    _currentState = state;
    _stateController.add(state);
  }

  /// No-op in the proxy implementation as the primary hub handles lifecycle.
  Future<void> connect(String token) async {
    _updateState(ChatSignalRState.connected);
  }

  /// No-op in the proxy implementation.
  Future<void> disconnect() async {
    _updateState(ChatSignalRState.disconnected);
  }

  /// No-op: Primary hub usually joins the room automatically on booking accept/start.
  Future<void> joinBookingRoom(String bookingId) async {
    // If specific room joining is needed, we could delegate to BookingTrackingHubService 
    // here, but the logs show messages are already arriving via the global connection.
  }

  /// No-op.
  Future<void> leaveBookingRoom(String bookingId) async {
  }

  void dispose() {
    _busSubscription?.cancel();
    _stateController.close();
    _messageController.close();
  }
}
