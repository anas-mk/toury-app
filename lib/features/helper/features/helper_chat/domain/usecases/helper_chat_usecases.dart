import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_chat_entities.dart';
import '../repositories/helper_chat_repository.dart';

class GetConversationUseCase {
  final HelperChatRepository repository;
  GetConversationUseCase(this.repository);

  Future<Either<Failure, ConversationEntity>> call(String bookingId) {
    return repository.getConversation(bookingId);
  }
}

class GetMessagesUseCase {
  final HelperChatRepository repository;
  GetMessagesUseCase(this.repository);

  Future<Either<Failure, List<ChatMessageEntity>>> call(
    String bookingId, {
    DateTime? before,
    int page = 1,
    int pageSize = 50,
  }) {
    return repository.getMessages(
      bookingId,
      before: before,
      page: page,
      pageSize: pageSize,
    );
  }
}

class SendMessageUseCase {
  final HelperChatRepository repository;
  SendMessageUseCase(this.repository);

  Future<Either<Failure, ChatMessageEntity>> call(String bookingId, String text) {
    return repository.sendMessage(bookingId, text);
  }
}

class MarkReadUseCase {
  final HelperChatRepository repository;
  MarkReadUseCase(this.repository);

  Future<Either<Failure, void>> call(String bookingId) {
    return repository.markAsRead(bookingId);
  }
}

class ConnectChatUseCase {
  final HelperChatRepository repository;
  ConnectChatUseCase(this.repository);

  Future<void> call(String token) {
    return repository.connectSignalR(token);
  }
}
