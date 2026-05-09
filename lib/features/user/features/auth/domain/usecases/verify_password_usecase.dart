import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyPasswordUseCase {
  final AuthRepository repository;

  VerifyPasswordUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String email, String password) async {
    if (password.isEmpty || password.length < 6) {
      return Left(ValidationFailure('Password must be at least 6 characters'));
    }
    return await repository.verifyPassword(email, password);
  }
}
