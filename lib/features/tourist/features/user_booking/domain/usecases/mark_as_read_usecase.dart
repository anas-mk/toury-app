import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class MarkAsReadUseCase {
  final ChatRepository repository;

  MarkAsReadUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String bookingId) {
    return repository.markAsRead(bookingId);
  }
}
