import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/chat_entities.dart';
import '../repositories/user_chat_repository.dart';

class GetChatConversationUseCase implements UseCase<ChatConversationEntity, String> {
  final UserChatRepository repository;

  GetChatConversationUseCase(this.repository);

  @override
  Future<Either<Failure, ChatConversationEntity>> call(String bookingId) async {
    return await repository.getConversation(bookingId);
  }
}
