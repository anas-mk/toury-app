import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatEntity>> getChatInfo(String bookingId);
  Future<Either<Failure, List<MessageEntity>>> getMessages(String bookingId, {int page = 1, int pageSize = 20, DateTime? before});
  Future<Either<Failure, MessageEntity>> sendMessage(String bookingId, String text, String messageType);
  Future<Either<Failure, Unit>> markAsRead(String bookingId);
}
