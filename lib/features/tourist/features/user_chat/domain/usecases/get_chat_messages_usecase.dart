import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/chat_entities.dart';
import '../repositories/user_chat_repository.dart';

class GetChatMessagesUseCase implements UseCase<List<ChatMessageEntity>, GetChatMessagesParams> {
  final UserChatRepository repository;

  GetChatMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> call(GetChatMessagesParams params) async {
    return await repository.getMessages(
      params.bookingId,
      page: params.page,
      beforeDate: params.beforeDate,
    );
  }
}

class GetChatMessagesParams {
  final String bookingId;
  final int page;
  final DateTime? beforeDate;

  GetChatMessagesParams({
    required this.bookingId,
    this.page = 1,
    this.beforeDate,
  });
}
