import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../repositories/user_chat_repository.dart';

class MarkChatAsReadUseCase implements UseCase<void, String> {
  final UserChatRepository repository;

  MarkChatAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String bookingId) async {
    return await repository.markAsRead(bookingId);
  }
}
