import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<Either<Failure, String>> call(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      return Left(ValidationFailure('Invalid email'));
    }
    return await repository.forgotPassword(email);
  }
}
