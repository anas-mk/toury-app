import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/user_chat_entities.dart';

abstract class UserChatRepository {
  Future<Either<Failure, ChatConversationEntity>> getConversation(String bookingId);
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    String bookingId, {
    DateTime? beforeDateTime,
    int page = 1,
    int pageSize = 50,
  });
  Future<Either<Failure, ChatMessageEntity>> sendMessage(String bookingId, String text, String messageType);
  Future<Either<Failure, void>> markAsRead(String bookingId);
}
