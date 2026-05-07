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

  StreamSubscription? _stateSubscription;
  StreamSubscription? _busSubscription;
  String? _currentBookingId;
  
  // Debounce timer for "Mark as Read" to minimize API calls
  Timer? _markReadDebounce;

  HelperChatCubit({
    required this.getConversationUseCase,
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.markReadUseCase,
    required this.connectChatUseCase,
    required this.signalRService,
  }) : super(HelperChatInitial());

  /// Initial Load: Fetch messages ONLY once when opening the chat
  Future<void> init(String bookingId, String token) async {
    _currentBookingId = bookingId;
    emit(HelperChatLoading());

    // 1. Connect SignalR (Primary Source of Truth)
    try {
      await connectChatUseCase(token);
      await signalRService.joinBookingRoom(bookingId);
    } catch (e) {
      debugPrint('SignalR Join Room Error: $e');
    }

    // 2. Initial Data Load (Conversation + Page 1 Messages)
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
            
            // Mark as read once on initial open
            _triggerMarkAsRead();
            
            // 3. Start Listening to real-time events
            _listenToState();
            _listenToBus();
          },
        );
      },
    );
  }

  /// Manual Fallback: Re-fetch first page if user pulls to refresh
  Future<void> refresh() async {
    if (_currentBookingId == null || state is! HelperChatLoaded) return;
    final s = state as HelperChatLoaded;

    final results = await Future.wait([
      getConversationUseCase(_currentBookingId!),
      getMessagesUseCase(_currentBookingId!, pageSize: 20),
    ]);

    final convRes = results[0] as Either<Failure, ConversationEntity>;
    final msgRes = results[1] as Either<Failure, List<ChatMessageEntity>>;

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

  /// Listen to the Global Realtime Bus for pushed messages (Primary Source)
  void _listenToBus() {
    _busSubscription?.cancel();
    _busSubscription = BookingRealtimeEventBus.instance.stream.listen((event) {
      if (event is BusChatMessage && event.event.bookingId == _currentBookingId) {
        _handleIncomingPush(event.event);
      }
    });
  }

  /// Appends incoming messages directly to the UI without re-fetching
  void _handleIncomingPush(ChatMessagePushEvent push) {
    if (state is! HelperChatLoaded) return;
    final s = state as HelperChatLoaded;

    // Convert push event to entity model
    final msgId = push.messageId ?? push.eventId;
    
    // PREVENT DUPLICATES: Check by ID before inserting
    if (s.messages.any((m) => m.id == msgId)) return;

    final msg = ChatMessageEntity(
      id: msgId,
      senderId: push.senderId ?? '',
      senderType: push.senderType ?? 'User',
      messageType: push.messageType ?? 'Text',
      text: push.text ?? push.preview ?? '',
      isRead: false,
      sentAt: push.sentAt ?? DateTime.now(),
    );

    // Update UI state directly with the new message
    emit(s.copyWith(messages: [msg, ...s.messages]));
    
    // Trigger debounced mark-as-read if message is from the other party
    if (msg.senderType.toLowerCase() == 'user') {
      _triggerMarkAsRead();
    }
  }

  /// Debounced strategy for "Mark as Read" to minimize network calls
  void _triggerMarkAsRead() {
    if (_currentBookingId == null) return;
    
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(seconds: 2), () {
      unawaited(markReadUseCase(_currentBookingId!));
    });
  }

  /// Pagination: Fetch older messages when scrolling
  Future<void> loadMore() async {
    if (state is! HelperChatLoaded || _currentBookingId == null) return;
    final s = state as HelperChatLoaded;
    if (s.hasReachedMax) return;

    final lastMessage = s.messages.last;
    final result = await getMessagesUseCase(
      _currentBookingId!, 
      before: lastMessage.sentAt, 
      pageSize: 20,
    );

    result.fold(
      (f) => null, // Silently handle pagination errors
      (newMessages) {
        if (newMessages.isEmpty) {
          emit(s.copyWith(hasReachedMax: true));
          return;
        }
        
        // Filter out duplicates (sanity check)
        final filtered = newMessages.where((nm) => !s.messages.any((m) => m.id == nm.id)).toList();
        
        emit(s.copyWith(
          messages: [...s.messages, ...filtered],
          hasReachedMax: newMessages.length < 20,
        ));
      },
    );
  }

  /// Sends a message using Optimistic UI
  Future<void> sendMessage(String text) async {
    if (state is! HelperChatLoaded || _currentBookingId == null) return;
    final s = state as HelperChatLoaded;

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
    
    // Instant UI update
    emit(s.copyWith(messages: [pendingMsg, ...s.messages]));

    final result = await sendMessageUseCase(_currentBookingId!, text);

    result.fold(
      (f) {
        // Handle failure: mark optimistic message as failed
        if (state is HelperChatLoaded) {
          final current = state as HelperChatLoaded;
          final updated = current.messages.map((m) {
            return m.id == tempId ? m.copyWith(isPending: false, isFailed: true) : m;
          }).toList();
          emit(current.copyWith(messages: updated));
        }
      },
      (sentMsg) {
        // Handle success: replace temp message with server response
        if (state is HelperChatLoaded) {
          final current = state as HelperChatLoaded;
          
          // If SignalR already pushed this message, just remove the temp one
          final alreadyInList = current.messages.any((m) => m.id == sentMsg.id);
          
          final updated = current.messages.map((m) {
            if (m.id == tempId) return alreadyInList ? null : sentMsg;
            return m;
          }).whereType<ChatMessageEntity>().toList();
          
          emit(current.copyWith(messages: updated));
        }
      },
    );
  }

  void _listenToState() {
    _stateSubscription?.cancel();
    _stateSubscription = signalRService.stateStream.listen((conState) {
      if (state is HelperChatLoaded) {
        emit((state as HelperChatLoaded).copyWith(connectionState: conState));
      }
    });
  }

  @override
  Future<void> close() {
    _stateSubscription?.cancel();
    _busSubscription?.cancel();
    _markReadDebounce?.cancel();
    if (_currentBookingId != null) {
      signalRService.leaveBookingRoom(_currentBookingId!);
    }
    return super.close();
  }
}
