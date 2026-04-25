import '../entities/chat_entities.dart';
import '../repositories/user_chat_repository.dart';

class ListenToMessagesUseCase {
  final UserChatRepository repository;

  ListenToMessagesUseCase(this.repository);

  Stream<ChatMessageEntity> call() {
    return repository.listenIncomingMessages();
  }
}
