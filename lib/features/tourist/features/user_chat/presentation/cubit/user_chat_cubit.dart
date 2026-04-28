import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/user_chat_signalr_service.dart';
import '../../domain/entities/user_chat_entities.dart';
import '../../domain/usecases/user_chat_usecases.dart';

abstract class UserChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserChatInitial extends UserChatState {}

class UserChatLoading extends UserChatState {}

class UserChatLoaded extends UserChatState {
  final ChatConversationEntity conversation;
  final List<ChatMessageEntity> messages;
  final bool hasReachedMax;
  final UserChatSignalRState connectionState;

  UserChatLoaded({
    required this.conversation,
    required this.messages,
    required this.hasReachedMax,
    required this.connectionState,
  });

  UserChatLoaded copyWith({
    ChatConversationEntity? conversation,
    List<ChatMessageEntity>? messages,
    bool? hasReachedMax,
    UserChatSignalRState? connectionState,
  }) {
    return UserChatLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      connectionState: connectionState ?? this.connectionState,
    );
  }

  @override
  List<Object?> get props => [conversation, messages, hasReachedMax, connectionState];
}

class UserChatError extends UserChatState {
  final String message;
  UserChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserChatCubit extends Cubit<UserChatState> {
  final GetChatConversationUseCase getConversationUseCase;
  final GetChatMessagesUseCase getMessagesUseCase;
  final SendChatMessageUseCase sendMessageUseCase;
  final MarkChatAsReadUseCase markReadUseCase;
  final UserChatSignalRService signalRService;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _stateSubscription;
  String? _currentBookingId;

  UserChatCubit({
    required this.getConversationUseCase,
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.markReadUseCase,
    required this.signalRService,
  }) : super(UserChatInitial());

  Future<void> init(String bookingId, String token) async {
    _currentBookingId = bookingId;
    emit(UserChatLoading());

    // 1. Connect SignalR
    try {
      await signalRService.connect(token);
      await signalRService.joinBookingRoom(bookingId);
    } catch (e) {
      // Don't fail the whole chat if SignalR fails
    }

    // 2. Load Conversation Metadata
    final convRes = await getConversationUseCase(bookingId);
    
    convRes.fold(
      (f) => emit(UserChatError(f.message)),
      (conv) async {
        // 3. Load Initial Messages
        final msgRes = await getMessagesUseCase(bookingId);
        
        msgRes.fold(
          (f) => emit(UserChatError(f.message)),
          (messages) {
            emit(UserChatLoaded(
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
      if (state is UserChatLoaded) {
        final s = state as UserChatLoaded;
        if (msg.senderId != s.conversation.user.id) {
           markRead(_currentBookingId!);
        }
        
        if (!s.messages.any((m) => m.id == msg.id)) {
           emit(s.copyWith(messages: [msg as ChatMessageEntity, ...s.messages]));
        }
      }
    });
  }

  void _listenToState() {
    _stateSubscription?.cancel();
    _stateSubscription = signalRService.stateStream.listen((conState) {
      if (state is UserChatLoaded) {
        emit((state as UserChatLoaded).copyWith(connectionState: conState));
      }
    });
  }

  Future<void> loadMore() async {
    if (state is! UserChatLoaded || _currentBookingId == null) return;
    final s = state as UserChatLoaded;
    if (s.hasReachedMax) return;

    final lastMessage = s.messages.last;
    final result = await getMessagesUseCase(_currentBookingId!, beforeDateTime: lastMessage.sentAt);

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
    if (state is! UserChatLoaded || _currentBookingId == null) return;
    final s = state as UserChatLoaded;

    final pendingMsg = ChatMessageEntity(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      senderId: s.conversation.user.id,
      senderType: 'User',
      messageType: 'Text',
      text: text,
      isRead: false,
      sentAt: DateTime.now(),
      isPending: true,
    );
    
    emit(s.copyWith(messages: [pendingMsg, ...s.messages]));

    final result = await sendMessageUseCase(_currentBookingId!, text);

    result.fold(
      (f) {
        final updatedMessages = (state as UserChatLoaded).messages.where((m) => m.id != pendingMsg.id).toList();
        emit((state as UserChatLoaded).copyWith(messages: updatedMessages));
      },
      (sentMsg) {
        final updatedMessages = (state as UserChatLoaded).messages.map((m) => m.id == pendingMsg.id ? sentMsg : m).toList();
        emit((state as UserChatLoaded).copyWith(messages: updatedMessages));
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
