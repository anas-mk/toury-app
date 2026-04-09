import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/helper_auth_repository.dart';

class HelperLogoutUseCase {
  final HelperAuthRepository repository;

  HelperLogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}
