import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../domain/usecases/send_chat_message_usecase.dart';
import 'user_chat_state.dart';

class UserChatCubit extends Cubit<UserChatState> {
  final GetChatMessagesUseCase getMessagesUseCase;
  final SendChatMessageUseCase sendMessageUseCase;
  final BookingTrackingHubService hubService;

  StreamSubscription? _chatSubscription;

  UserChatCubit({
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.hubService,
  }) : super(UserChatInitial());

  Future<void> loadMessages(String bookingId) async {
    emit(ChatLoading());
    final result = await getMessagesUseCase(
      GetChatMessagesParams(bookingId: bookingId),
    );
    result.fold((failure) => emit(ChatError(failure.message)), (messages) {
      emit(ChatLoaded(messages: messages));
      _subscribeToNewMessages(bookingId);
    });
  }

  void _subscribeToNewMessages(String bookingId) {
    _chatSubscription?.cancel();
    unawaited(hubService.ensureConnected());
    _chatSubscription = hubService.chatMessageStream
        .where((event) => event.bookingId == bookingId)
        .listen((event) {
          final currentState = state;
          if (currentState is! ChatLoaded) return;
          final messageId = event.messageId;
          if (messageId == null || messageId.isEmpty) return;
          if (currentState.messages.any((m) => m.id == messageId)) return;

          final message = ChatMessageEntity(
            id: messageId,
            senderId: event.senderId ?? '',
            senderType: event.senderType ?? '',
            messageType: event.messageType ?? 'Text',
            text: event.preview ?? '',
            sentAt: event.sentAt ?? DateTime.now().toUtc(),
            isRead: false,
          );
          emit(
            currentState.copyWith(
              messages: [message, ...currentState.messages],
            ),
          );
        });
  }

  Future<void> sendMessage(String bookingId, String text) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      emit(currentState.copyWith(isSending: true));
      final result = await sendMessageUseCase(
        SendChatMessageParams(bookingId: bookingId, text: text, type: 'Text'),
      );
      result.fold((failure) => emit(ChatError(failure.message)), (newMessage) {
        emit(
          ChatLoaded(
            messages: [newMessage, ...currentState.messages],
            isSending: false,
          ),
        );
      });
    }
  }

  @override
  Future<void> close() {
    _chatSubscription?.cancel();
    return super.close();
  }
}
