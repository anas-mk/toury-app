import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class GetChatInfoUseCase {
  final ChatRepository repository;

  GetChatInfoUseCase(this.repository);

  Future<Either<Failure, ChatEntity>> call(String bookingId) {
    return repository.getChatInfo(bookingId);
  }
}
