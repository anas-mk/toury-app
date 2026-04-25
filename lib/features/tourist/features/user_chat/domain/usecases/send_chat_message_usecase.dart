import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/chat_entities.dart';
import '../repositories/user_chat_repository.dart';

class SendChatMessageUseCase implements UseCase<ChatMessageEntity, SendChatMessageParams> {
  final UserChatRepository repository;

  SendChatMessageUseCase(this.repository);

  @override
  Future<Either<Failure, ChatMessageEntity>> call(SendChatMessageParams params) async {
    return await repository.sendMessage(
      bookingId: params.bookingId,
      text: params.text,
      type: params.type,
    );
  }
}

class SendChatMessageParams {
  final String bookingId;
  final String text;
  final String type;

  SendChatMessageParams({
    required this.bookingId,
    required this.text,
    required this.type,
  });
}
