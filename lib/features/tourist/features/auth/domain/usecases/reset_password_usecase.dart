import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return await repository.resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }
}