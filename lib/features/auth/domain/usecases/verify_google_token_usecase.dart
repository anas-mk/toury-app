import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyGoogleTokenUseCase {
  final AuthRepository repository;

  VerifyGoogleTokenUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String googleToken) async {
    if (googleToken.isEmpty) {
      return Left(ValidationFailure('Google token is required'));
    }
    return await repository.verifyGoogleToken(googleToken);
  }
}
