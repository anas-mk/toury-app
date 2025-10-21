import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GoogleRegisterUseCase {
  final AuthRepository repository;

  GoogleRegisterUseCase(this.repository);

  Future<Either<Failure,Map<String, dynamic>>> call({
    required String googleId,
    required String name,
    required String email,

  }) async {
    if (googleId.isEmpty) {
      return Left(ValidationFailure('GoogleId is required'));
    }
    if (name.trim().isEmpty) {
      return Left(ValidationFailure('Username cannot be empty'));
    }
    if (email.trim().isEmpty) {
      return Left(ValidationFailure('email cannot be empty'));
    }

    return await repository.googleRegister(
      googleId: googleId,
      name: name,
     email: email,
    );
  }
}
