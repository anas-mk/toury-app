import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/helper_auth_repository.dart';
import '../../data/models/helper_login_response_model.dart';

class HelperLoginUseCase {
  final HelperAuthRepository repository;

  HelperLoginUseCase(this.repository);

  Future<Either<Failure, HelperLoginResponseModel>> call({
    required String email,
    required String password,
  }) async {
    return await repository.login(email: email, password: password);
  }
}
