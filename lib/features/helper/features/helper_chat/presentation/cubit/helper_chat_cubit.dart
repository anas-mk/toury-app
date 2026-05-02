import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/services/helper_chat_signalr_service.dart';
import '../../domain/entities/helper_chat_entities.dart';
import '../../domain/usecases/helper_chat_usecases.dart';

import 'package:toury/core/services/realtime/booking_realtime_event_bus.dart';
import 'package:toury/core/services/signalr/booking_hub_events.dart';

abstract class HelperChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HelperChatInitial extends HelperChatState {}

class HelperChatLoading extends HelperChatState {}

class HelperChatLoaded extends HelperChatState {
  final ConversationEntity conversation;
  final List<ChatMessageEntity> messages;
  final bool hasReachedMax;
  final ChatSignalRState connectionState;

  HelperChatLoaded({
    required this.conversation,
    required this.messages,
    required this.hasReachedMax,
    required this.connectionState,
  });

  HelperChatLoaded copyWith({
    ConversationEntity? conversation,
    List<ChatMessageEntity>? messages,
    bool? hasReachedMax,
    ChatSignalRState? connectionState,
  }) {
    return HelperChatLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      connectionState: connectionState ?? this.connectionState,
    );
  }

  @override
  List<Object?> get props => [conversation, messages, hasReachedMax, connectionState];
}

class HelperChatError extends HelperChatState {
  final String message;
  HelperChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class HelperChatCubit extends Cubit<HelperChatState> {
  final GetConversationUseCase getConversationUseCase;
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final MarkReadUseCase markReadUseCase;
  final ConnectChatUseCase connectChatUseCase;
  final HelperChatSignalRService signalRService;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _busSubscription;
  String? _currentBookingId;
  Timer? _refreshTimer;

  HelperChatCubit({
    required this.getConversationUseCase,
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.markReadUseCase,
    required this.connectChatUseCase,
    required this.signalRService,
  }) : super(HelperChatInitial());

  Future<void> init(String bookingId, String token) async {
    _currentBookingId = bookingId;
    emit(HelperChatLoading());

    // 1. Connect SignalR
    await connectChatUseCase(token);
    await signalRService.joinBookingRoom(bookingId);

    // 2. Load Conversation Metadata & Initial Messages
    final results = await Future.wait([
      getConversationUseCase(bookingId),
      getMessagesUseCase(bookingId, pageSize: 20),
    ]);

    final convRes = results[0] as Either<Failure, ConversationEntity>;
    final msgRes = results[1] as Either<Failure, List<ChatMessageEntity>>;

    convRes.fold(
      (f) => emit(HelperChatError(f.message)),
      (conv) {
        msgRes.fold(
          (f) => emit(HelperChatError(f.message)),
          (messages) {
            emit(HelperChatLoaded(
              conversation: conv,
              messages: messages,
              hasReachedMax: messages.length < 20,
              connectionState: signalRService.currentState,
            ));
            
            markRead(bookingId);
            
            // 3. Start Listening
            _listenToMessages();
            _listenToState();
            _listenToBus();
            _startAutoRefresh();
          },
        );
      },
    );
  }

  void _listenToBus() {
    _busSubscription?.cancel();
    _busSubscription = BookingRealtimeEventBus.instance.stream.listen((event) {
      if (event is BusChatMessage && event.event.bookingId == _currentBookingId) {
        _handleIncomingPush(event.event);
      }
    });
  }

  void _handleIncomingPush(ChatMessagePushEvent push) {
    if (kDebugMode) {
      debugPrint('📩 HelperChatCubit: Received Push for ${push.bookingId}');
    }
    
    if (state is! HelperChatLoaded) return;
    final s = state as HelperChatLoaded;

    // Convert push event to entity
    final msg = ChatMessageEntity(
      id: push.messageId ?? push.eventId,
      senderId: push.senderId ?? '',
      senderType: push.senderType ?? 'User',
      messageType: push.messageType ?? 'Text',
      text: push.text ?? push.preview ?? '',
      isRead: false,
      sentAt: push.sentAt ?? DateTime.now(),
    );

    // Avoid duplicates
    if (!s.messages.any((m) => m.id == msg.id)) {
      emit(s.copyWith(messages: [msg, ...s.messages]));
      
      // Auto mark as read if it's from user
      if (msg.senderType.toLowerCase() == 'user') {
        markRead(_currentBookingId!);
      }

      // 🔄 Trigger a background refresh to sync perfectly with backend
      refresh();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      refresh();
    });
  }

  Future<void> refresh() async {
    if (_currentBookingId == null) return;
    
    final results = await Future.wait([
      getConversationUseCase(_currentBookingId!),
      getMessagesUseCase(_currentBookingId!, pageSize: 20),
    ]);

    final convRes = results[0] as Either<Failure, ConversationEntity>;
    final msgRes = results[1] as Either<Failure, List<ChatMessageEntity>>;

    if (state is HelperChatLoaded) {
      final s = state as HelperChatLoaded;
      convRes.fold(
        (_) => null,
        (conv) => msgRes.fold(
          (_) => null,
          (messages) => emit(s.copyWith(
            conversation: conv,
            messages: messages,
            hasReachedMax: messages.length < 20,
          )),
        ),
      );
    }
  }

  void _listenToMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = signalRService.messageStream.listen((msg) {
      if (state is HelperChatLoaded) {
        final s = state as HelperChatLoaded;
        
        // Mark as read if message is from the other party
        if (msg.senderType.toLowerCase() == 'user') {
          markRead(_currentBookingId!);
        }
        
        // Avoid duplicate messages (use messageId check)
        if (!s.messages.any((m) => m.id == msg.id)) {
           // SignalR is the SINGLE source of truth for incoming messages
           emit(s.copyWith(messages: [msg, ...s.messages]));
        }
      }
    });
  }

  void _listenToState() {
    _stateSubscription?.cancel();
    _stateSubscription = signalRService.stateStream.listen((conState) {
      if (state is HelperChatLoaded) {
        emit((state as HelperChatLoaded).copyWith(connectionState: conState));
      }
    });
  }

  Future<void> loadMore() async {
    if (state is! HelperChatLoaded || _currentBookingId == null) return;
    final s = state as HelperChatLoaded;
    if (s.hasReachedMax) return;

    final lastMessage = s.messages.last;
    final result = await getMessagesUseCase(_currentBookingId!, before: lastMessage.sentAt, pageSize: 20);

    result.fold(
      (f) => null,
      (newMessages) {
        if (newMessages.isEmpty) {
          emit(s.copyWith(hasReachedMax: true));
          return;
        }
        
        // Filter out duplicates if any
        final filtered = newMessages.where((nm) => !s.messages.any((m) => m.id == nm.id)).toList();
        
        emit(s.copyWith(
          messages: [...s.messages, ...filtered],
          hasReachedMax: newMessages.length < 20,
        ));
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (state is! HelperChatLoaded || _currentBookingId == null) return;
    final s = state as HelperChatLoaded;

    // 1. Optimistic UI: Add message locally instantly
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final pendingMsg = ChatMessageEntity(
      id: tempId,
      senderId: s.conversation.helper.id,
      senderType: 'Helper',
      messageType: 'Text',
      text: text,
      isRead: false,
      sentAt: DateTime.now(),
      isPending: true,
    );
    
    emit(s.copyWith(messages: [pendingMsg, ...s.messages]));

    // 2. Send to API
    final result = await sendMessageUseCase(_currentBookingId!, text);

    result.fold(
      (f) {
        if (state is HelperChatLoaded) {
          final currentLoaded = state as HelperChatLoaded;
          // Mark as failed instead of removing, or handle rollback
          final updatedMessages = currentLoaded.messages.map((m) {
            if (m.id == tempId) {
              return m.copyWith(isPending: false, isFailed: true);
            }
            return m;
          }).toList();
          emit(currentLoaded.copyWith(messages: updatedMessages));
        }
      },
      (sentMsg) {
        // DO NOT just replace the whole list, map carefully to preserve scroll position/state
        if (state is HelperChatLoaded) {
          final currentLoaded = state as HelperChatLoaded;
          
          // Check if SignalR already added this message
          final alreadyInList = currentLoaded.messages.any((m) => m.id == sentMsg.id);
          
          final updatedMessages = currentLoaded.messages.map((m) {
            // Replace the optimistic message with the real one from API if not already added by SignalR
            if (m.id == tempId) {
              return alreadyInList ? null : sentMsg;
            }
            return m;
          }).whereType<ChatMessageEntity>().toList();
          
          emit(currentLoaded.copyWith(messages: updatedMessages));
        }
      },
    );
  }

  /// Mark as read in background (unawaited) as requested
  void markRead(String bookingId) {
    unawaited(markReadUseCase(bookingId));
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _stateSubscription?.cancel();
    _busSubscription?.cancel();
    _refreshTimer?.cancel();
    if (_currentBookingId != null) {
      signalRService.leaveBookingRoom(_currentBookingId!);
    }
    return super.close();
  }
}
