import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class VerifyCodeUseCase {
  final AuthRepository repository;

  VerifyCodeUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String email,
    required String code,
  }) async {
    return await repository.verifyRegistrationCode(
      email: email,
      code: code,
    );
  }
}

// auth_repository.dart - Add this method to the abstract class:
/*
  Future<Either<Failure, Map<String, dynamic>>> verifyRegistrationCode({
    required String email,
    required String code,
  });
*/