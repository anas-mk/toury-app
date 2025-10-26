import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/user_model.dart';
import '../repositories/auth_repository.dart';

class VerifyGoogleCodeUseCase {
  final AuthRepository repository;

  VerifyGoogleCodeUseCase(this.repository);

  Future<Either<Failure, UserModel>> call({
    required String email,
    required String code,
  }) async {
    return await repository.verifyGoogleCode(
      email: email,
      code: code,
    );
  }
}
