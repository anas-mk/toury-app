import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/helper_auth_response_model.dart';
import '../repositories/helper_auth_repository.dart';

class VerifyHelperLoginOtpUseCase {
  final HelperAuthRepository repository;

  VerifyHelperLoginOtpUseCase(this.repository);

  Future<Either<Failure, HelperAuthResponseModel>> call({
    required String email,
    required String code,
  }) async {
    return await repository.verifyLoginOtp(email: email, code: code);
  }
}
