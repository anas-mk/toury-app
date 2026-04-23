import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../../tourist/features/user_booking/domain/entities/message_entity.dart';
import '../../domain/usecases/helper_chat_usecases.dart';
import 'helper_chat_state.dart';

class HelperChatCubit extends Cubit<HelperChatState> {
  final GetHelperChatInfoUseCase getChatInfoUseCase;
  final GetHelperMessagesUseCase getMessagesUseCase;
  final SendHelperMessageUseCase sendMessageUseCase;
  final MarkHelperMessagesReadUseCase markAsReadUseCase;

  HelperChatCubit({
    required this.getChatInfoUseCase,
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.markAsReadUseCase,
  }) : super(HelperChatInitial());

  int _currentPage = 1;
  final int _pageSize = 20;
  String? _bookingId;

  Future<void> initChat(String bookingId) async {
    _bookingId = bookingId;
    _currentPage = 1;
    emit(HelperChatLoading());

    final infoResult = await getChatInfoUseCase(bookingId);
    
    infoResult.fold(
      (failure) => emit(HelperChatError(failure.message)),
      (chatInfo) async {
        final messagesResult = await getMessagesUseCase(bookingId, page: _currentPage, pageSize: _pageSize);
        
        messagesResult.fold(
          (failure) => emit(HelperChatError(failure.message)),
          (messages) {
            emit(HelperChatLoaded(
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
    if (currentState is! HelperChatLoaded || currentState.isLoadingMore || currentState.hasReachedMax) return;

    emit(currentState.copyWith(isLoadingMore: true));
    _currentPage++;

    final result = await getMessagesUseCase(
      _bookingId!,
      page: _currentPage,
      pageSize: _pageSize,
      before: currentState.messages.last.createdAt.toIso8601String(),
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
    if (currentState is! HelperChatLoaded || _bookingId == null) return;

    // Optimistic UI
    final tempId = const Uuid().v4();
    final optimisticMessage = MessageEntity(
      id: tempId,
      text: text,
      messageType: messageType,
      createdAt: DateTime.now(),
      senderId: 'current_helper',
      senderRole: 'Helper',
      isSending: true,
    );

    final updatedMessages = List<MessageEntity>.from(currentState.messages)..insert(0, optimisticMessage);
    emit(currentState.copyWith(messages: updatedMessages));

    final result = await sendMessageUseCase(_bookingId!, text: text, messageType: messageType);

    result.fold(
      (failure) {
        final failedMessages = state is HelperChatLoaded 
          ? (state as HelperChatLoaded).messages.map((m) => m.id == tempId ? m.copyWith(isSending: false, isFailed: true) : m).toList()
          : updatedMessages;
        if (state is HelperChatLoaded) emit((state as HelperChatLoaded).copyWith(messages: failedMessages));
      },
      (sentMessage) {
        final successMessages = state is HelperChatLoaded
          ? (state as HelperChatLoaded).messages.map((m) => m.id == tempId ? sentMessage : m).toList()
          : updatedMessages;
        if (state is HelperChatLoaded) emit((state as HelperChatLoaded).copyWith(messages: successMessages));
      },
    );
  }

  Future<void> markAsRead(String bookingId) async {
    await markAsReadUseCase(bookingId);
  }
}
