import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, MessageEntity>> call(String bookingId, String text, String messageType) {
    return repository.sendMessage(bookingId, text, messageType);
  }
}
