import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/helper_auth_repository.dart';

class ResendHelperLoginOtpUseCase {
  final HelperAuthRepository repository;

  ResendHelperLoginOtpUseCase(this.repository);

  Future<Either<Failure, Unit>> call(String email) async {
    return await repository.resendLoginOtp(email);
  }
}
