import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class GoogleLoginUseCase {
  final AuthRepository repository;

  GoogleLoginUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String googleToken) async {
    if (googleToken.isEmpty) {
      return Left(ValidationFailure('Google token is required'));
    }
    return await repository.googleLogin(googleToken);
  }
}
