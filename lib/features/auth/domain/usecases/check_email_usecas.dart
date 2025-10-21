import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class CheckEmailUseCase {
  final AuthRepository repository;

  CheckEmailUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      return Left(ValidationFailure('Invalid email'));
    }
    return await repository.checkEmail(email);
  }
}
