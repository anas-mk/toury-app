import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/helper_chat_signalr_service.dart';
import '../../domain/entities/helper_chat_entities.dart';
import '../../domain/usecases/helper_chat_usecases.dart';

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
  String? _currentBookingId;

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

    // 2. Load Conversation Metadata
    final convRes = await getConversationUseCase(bookingId);
    
    convRes.fold(
      (f) => emit(HelperChatError(f.message)),
      (conv) async {
        // 3. Load Initial Messages
        final msgRes = await getMessagesUseCase(bookingId);
        
        msgRes.fold(
          (f) => emit(HelperChatError(f.message)),
          (messages) {
            emit(HelperChatLoaded(
              conversation: conv,
              messages: messages,
              hasReachedMax: messages.length < 50,
              connectionState: signalRService.currentState,
            ));
            
            // Mark as read immediately
            markRead(bookingId);
            
            // 4. Start Listening
            _listenToMessages();
            _listenToState();
          },
        );
      },
    );
  }

  void _listenToMessages() {
    _messageSubscription?.cancel();
    _messageSubscription = signalRService.messageStream.listen((msg) {
      if (state is HelperChatLoaded) {
        final s = state as HelperChatLoaded;
        // Check if message belongs to current conversation
        // (Assuming backend sends room info or we trust the room join)
        if (msg.senderId != s.conversation.helper.id) {
           // It's a traveler message, mark as read
           markRead(_currentBookingId!);
        }
        
        // Add message to list if not already there (SignalR might send duplicate if we just sent it via HTTP)
        if (!s.messages.any((m) => m.id == msg.id)) {
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
    final result = await getMessagesUseCase(_currentBookingId!, before: lastMessage.sentAt);

    result.fold(
      (f) => null,
      (newMessages) {
        emit(s.copyWith(
          messages: [...s.messages, ...newMessages],
          hasReachedMax: newMessages.length < 50,
        ));
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (state is! HelperChatLoaded || _currentBookingId == null) return;
    final s = state as HelperChatLoaded;

    // Optimistic UI update
    final pendingMsg = ChatMessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: s.conversation.helper.id,
      senderType: 'helper',
      messageType: 'text',
      text: text,
      isRead: false,
      sentAt: DateTime.now(),
      isPending: true,
    );
    
    emit(s.copyWith(messages: [pendingMsg, ...s.messages]));

    final result = await sendMessageUseCase(_currentBookingId!, text);

    result.fold(
      (f) {
        // Remove pending message and show error
        final updatedMessages = s.messages.where((m) => m.id != pendingMsg.id).toList();
        emit(s.copyWith(messages: updatedMessages));
        // You might want to emit a specific error state or use a side effect
      },
      (sentMsg) {
        // Replace pending with actual
        final updatedMessages = s.messages.map((m) => m.id == pendingMsg.id ? sentMsg : m).toList();
        emit(s.copyWith(messages: updatedMessages));
      },
    );
  }

  Future<void> markRead(String bookingId) async {
    await markReadUseCase(bookingId);
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _stateSubscription?.cancel();
    if (_currentBookingId != null) {
      signalRService.leaveBookingRoom(_currentBookingId!);
    }
    return super.close();
  }
}
