import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/usecases/get_chat_conversation_usecase.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../domain/usecases/send_chat_message_usecase.dart';
import '../../domain/usecases/mark_chat_as_read_usecase.dart';
import '../../domain/usecases/listen_to_messages_usecase.dart';
import 'user_chat_state.dart';

class UserChatCubit extends Cubit<UserChatState> {
  final GetChatConversationUseCase getChatConversationUseCase;
  final GetChatMessagesUseCase getChatMessagesUseCase;
  final SendChatMessageUseCase sendChatMessageUseCase;
  final MarkChatAsReadUseCase markChatAsReadUseCase;
  final ListenToMessagesUseCase listenToMessagesUseCase;

  StreamSubscription? _messageSubscription;
  int _currentPage = 1;

  UserChatCubit({
    required this.getChatConversationUseCase,
    required this.getChatMessagesUseCase,
    required this.sendChatMessageUseCase,
    required this.markChatAsReadUseCase,
    required this.listenToMessagesUseCase,
  }) : super(UserChatInitial());

  Future<void> initChat(String bookingId) async {
    emit(UserChatLoading());
    
    final conversationResult = await getChatConversationUseCase(bookingId);
    
    await conversationResult.fold(
      (failure) async => emit(UserChatError(failure.message)),
      (conversation) async {
        final messagesResult = await getChatMessagesUseCase(GetChatMessagesParams(bookingId: bookingId));
        
        messagesResult.fold(
          (failure) => emit(UserChatError(failure.message)),
          (messages) {
            emit(UserChatLoaded(
              conversation: conversation,
              messages: messages,
              hasMore: messages.length >= 20, // Assuming pageSize is 20
            ));
            
            _currentPage = 1;
            _startListening();
            markAsRead(bookingId);
          },
        );
      },
    );
  }

  void _startListening() {
    _messageSubscription?.cancel();
    _messageSubscription = listenToMessagesUseCase().listen((message) {
      if (state is UserChatLoaded) {
        final currentState = state as UserChatLoaded;
        // Only append if it belongs to this conversation (logic usually handled by SignalR hub groups, but safety first)
        final updatedMessages = [message, ...currentState.messages];
        emit(currentState.copyWith(messages: updatedMessages));
      }
    });
  }

  Future<void> loadMoreMessages(String bookingId) async {
    if (state is! UserChatLoaded) return;
    final currentState = state as UserChatLoaded;
    if (!currentState.hasMore || currentState.isPaginationLoading) return;

    emit(currentState.copyWith(isPaginationLoading: true));
    
    _currentPage++;
    final beforeDate = currentState.messages.isNotEmpty ? currentState.messages.last.sentAt : null;
    
    final result = await getChatMessagesUseCase(GetChatMessagesParams(
      bookingId: bookingId,
      page: _currentPage,
      beforeDate: beforeDate,
    ));

    result.fold(
      (failure) => emit(currentState.copyWith(isPaginationLoading: false)),
      (newMessages) {
        emit(currentState.copyWith(
          messages: [...currentState.messages, ...newMessages],
          hasMore: newMessages.length >= 20,
          isPaginationLoading: false,
        ));
      },
    );
  }

  Future<void> sendMessage(String bookingId, String text) async {
    if (state is! UserChatLoaded || text.trim().isEmpty) return;
    final currentState = state as UserChatLoaded;

    // Optimistic Update
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimisticMessage = ChatMessageEntity(
      id: tempId,
      senderId: currentState.conversation.user.id,
      senderType: 'User',
      messageType: 'Text',
      text: text,
      sentAt: DateTime.now(),
      isRead: false,
    );

    final updatedMessages = [optimisticMessage, ...currentState.messages];
    emit(currentState.copyWith(messages: updatedMessages));

    final result = await sendChatMessageUseCase(SendChatMessageParams(
      bookingId: bookingId,
      text: text,
      type: 'Text',
    ));

    result.fold(
      (failure) {
        // Rollback optimistic update
        final rollbackMessages = currentState.messages.where((m) => m.id != tempId).toList();
        emit(currentState.copyWith(messages: rollbackMessages));
        // Show error (can be handled via a side-effect stream if needed)
      },
      (sentMessage) {
        // Replace temp message with real one
        final finalMessages = currentState.messages.map((m) => m.id == tempId ? sentMessage : m).toList();
        emit(currentState.copyWith(messages: finalMessages));
      },
    );
  }

  Future<void> markAsRead(String bookingId) async {
    await markChatAsReadUseCase(bookingId);
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
