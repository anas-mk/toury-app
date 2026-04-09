import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/helper_auth_repository.dart';

class ForgotHelperPasswordUseCase {
  final HelperAuthRepository repository;

  ForgotHelperPasswordUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String email) async {
    return await repository.forgotPassword(email);
  }
}
