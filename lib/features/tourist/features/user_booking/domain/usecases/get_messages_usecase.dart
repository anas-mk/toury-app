import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class GetMessagesUseCase {
  final ChatRepository repository;

  GetMessagesUseCase(this.repository);

  Future<Either<Failure, List<MessageEntity>>> call(
    String bookingId, {
    int page = 1,
    int pageSize = 20,
    DateTime? before,
  }) {
    return repository.getMessages(bookingId, page: page, pageSize: pageSize, before: before);
  }
}
