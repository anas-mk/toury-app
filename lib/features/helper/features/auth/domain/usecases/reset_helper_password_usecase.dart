import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/helper_auth_repository.dart';

class ResetHelperParams {
  final String email;
  final String code;
  final String newPassword;

  ResetHelperParams({
    required this.email,
    required this.code,
    required this.newPassword,
  });
}

class ResetHelperPasswordUseCase {
  final HelperAuthRepository repository;

  ResetHelperPasswordUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(ResetHelperParams params) async {
    return await repository.resetPassword(
      email: params.email,
      code: params.code,
      newPassword: params.newPassword,
    );
  }
}
