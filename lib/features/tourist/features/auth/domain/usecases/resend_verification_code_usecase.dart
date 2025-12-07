import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ResendVerificationCodeUseCase {
  final AuthRepository repository;

  ResendVerificationCodeUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String email) async {
    return await repository.resendVerificationCode(email);
  }
}