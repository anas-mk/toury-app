import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/usecases/get_chat_info_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final GetChatInfoUseCase getChatInfoUseCase;
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final MarkAsReadUseCase markAsReadUseCase;

  ChatCubit({
    required this.getChatInfoUseCase,
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.markAsReadUseCase,
  }) : super(ChatInitial());

  int _currentPage = 1;
  final int _pageSize = 20;
  String? _bookingId;

  Future<void> initChat(String bookingId) async {
    _bookingId = bookingId;
    _currentPage = 1;
    emit(ChatLoading());

    final infoResult = await getChatInfoUseCase(bookingId);
    
    infoResult.fold(
      (failure) => emit(ChatError(failure.message)),
      (chatInfo) async {
        final messagesResult = await getMessagesUseCase(bookingId, page: _currentPage, pageSize: _pageSize);
        
        messagesResult.fold(
          (failure) => emit(ChatError(failure.message)),
          (messages) {
            emit(ChatLoaded(
              chatInfo: chatInfo,
              messages: messages,
              hasReachedMax: messages.length < _pageSize,
            ));
            markAsRead(bookingId);
          },
        );
      },
    );
  }

  Future<void> loadMoreMessages() async {
    final currentState = state;
    if (currentState is! ChatLoaded || currentState.isLoadingMore || currentState.hasReachedMax) return;

    emit(currentState.copyWith(isLoadingMore: true));
    _currentPage++;

    final result = await getMessagesUseCase(
      _bookingId!,
      page: _currentPage,
      pageSize: _pageSize,
      before: currentState.messages.last.createdAt,
    );

    result.fold(
      (failure) => emit(currentState.copyWith(isLoadingMore: false)),
      (newMessages) {
        if (newMessages.isEmpty) {
          emit(currentState.copyWith(isLoadingMore: false, hasReachedMax: true));
        } else {
          emit(currentState.copyWith(
            isLoadingMore: false,
            messages: List.from(currentState.messages)..addAll(newMessages),
            hasReachedMax: newMessages.length < _pageSize,
          ));
        }
      },
    );
  }

  Future<void> sendMessage(String text, String messageType) async {
    final currentState = state;
    if (currentState is! ChatLoaded || _bookingId == null) return;

    // Optimistic UI
    final tempId = const Uuid().v4();
    final optimisticMessage = MessageEntity(
      id: tempId,
      text: text,
      messageType: messageType,
      createdAt: DateTime.now(),
      senderId: 'current_user', // This should ideally come from an Auth state
      senderRole: 'User',
      isSending: true,
    );

    final updatedMessages = List<MessageEntity>.from(currentState.messages)..insert(0, optimisticMessage);
    emit(currentState.copyWith(messages: updatedMessages));

    final result = await sendMessageUseCase(_bookingId!, text, messageType);

    result.fold(
      (failure) {
        final failedMessages = state is ChatLoaded 
          ? (state as ChatLoaded).messages.map((m) => m.id == tempId ? m.copyWith(isSending: false, isFailed: true) : m).toList()
          : updatedMessages;
        if (state is ChatLoaded) emit((state as ChatLoaded).copyWith(messages: failedMessages));
      },
      (sentMessage) {
        final successMessages = state is ChatLoaded
          ? (state as ChatLoaded).messages.map((m) => m.id == tempId ? sentMessage : m).toList()
          : updatedMessages;
        if (state is ChatLoaded) emit((state as ChatLoaded).copyWith(messages: successMessages));
      },
    );
  }

  Future<void> markAsRead(String bookingId) async {
    await markAsReadUseCase(bookingId);
  }
}
