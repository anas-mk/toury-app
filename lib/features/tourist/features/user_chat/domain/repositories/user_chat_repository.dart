import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/chat_entities.dart';

abstract class UserChatRepository {
  Future<Either<Failure, ChatConversationEntity>> getConversation(String bookingId);
  
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    String bookingId, {
    int page = 1,
    DateTime? beforeDate,
  });

  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String bookingId,
    required String text,
    required String type,
  });

  Future<Either<Failure, void>> markAsRead(String bookingId);

  Stream<ChatMessageEntity> listenIncomingMessages();
}
