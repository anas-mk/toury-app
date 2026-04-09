import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/helper_auth_response_model.dart';
import '../repositories/helper_auth_repository.dart';

class VerifyHelperEmailUseCase {
  final HelperAuthRepository repository;

  VerifyHelperEmailUseCase(this.repository);

  Future<Either<Failure, HelperAuthResponseModel>> call({
    required String email,
    required String code,
  }) async {
    return await repository.verifyEmail(email: email, code: code);
  }
}
