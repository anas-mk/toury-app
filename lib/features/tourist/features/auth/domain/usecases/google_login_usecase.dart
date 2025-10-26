import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class GoogleLoginUseCase {
  final AuthRepository repository;

  GoogleLoginUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String email) async {
    if (email.isEmpty) {
      return Left(ValidationFailure('Email is required'));
    }
    return await repository.googleLogin(email);
  }
}

