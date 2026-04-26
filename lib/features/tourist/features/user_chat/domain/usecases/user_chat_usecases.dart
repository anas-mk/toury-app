import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/user_chat_entities.dart';
import '../repositories/user_chat_repository.dart';

class GetChatConversationUseCase {
  final UserChatRepository repository;
  GetChatConversationUseCase(this.repository);

  Future<Either<Failure, ChatConversationEntity>> call(String bookingId) async {
    return await repository.getConversation(bookingId);
  }
}

class GetChatMessagesUseCase {
  final UserChatRepository repository;
  GetChatMessagesUseCase(this.repository);

  Future<Either<Failure, List<ChatMessageEntity>>> call(
    String bookingId, {
    DateTime? beforeDateTime,
    int page = 1,
    int pageSize = 50,
  }) async {
    return await repository.getMessages(
      bookingId,
      beforeDateTime: beforeDateTime,
      page: page,
      pageSize: pageSize,
    );
  }
}

class SendChatMessageUseCase {
  final UserChatRepository repository;
  SendChatMessageUseCase(this.repository);

  Future<Either<Failure, ChatMessageEntity>> call(
    String bookingId,
    String text, {
    String messageType = 'Text',
  }) async {
    return await repository.sendMessage(bookingId, text, messageType);
  }
}

class MarkChatAsReadUseCase {
  final UserChatRepository repository;
  MarkChatAsReadUseCase(this.repository);

  Future<Either<Failure, void>> call(String bookingId) async {
    return await repository.markAsRead(bookingId);
  }
}
