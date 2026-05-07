import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_chat_entities.dart';

abstract class HelperChatRepository {
  Future<Either<Failure, ConversationEntity>> getConversation(String bookingId);
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(
    String bookingId, {
    DateTime? before,
    int page = 1,
    int pageSize = 50,
  });
  Future<Either<Failure, ChatMessageEntity>> sendMessage(String bookingId, String text);
  Future<Either<Failure, void>> markAsRead(String bookingId);
  
  // Real-time
  Future<void> connectSignalR(String token);
  Future<void> disconnectSignalR();
  Stream<ChatMessageEntity> get messageStream;
}
