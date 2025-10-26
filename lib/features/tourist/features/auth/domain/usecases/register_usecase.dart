import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String userName,
    required String password,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    required String country,
  }) async {
    //  Validation logic
    if (email.isEmpty || !email.contains('@')) {
      return Left(ValidationFailure('Invalid email'));
    }
    if (password.length < 6) {
      return Left(ValidationFailure('Password must be at least 6 characters'));
    }
    if (userName.trim().isEmpty) {
      return Left(ValidationFailure('Username cannot be empty'));
    }
    if (phoneNumber.trim().isEmpty) {
      return Left(ValidationFailure('Phone number cannot be empty'));
    }

    //  Call repository
    return await repository.register(
      email: email,
      userName: userName,
      password: password,
      phoneNumber: phoneNumber,
      gender: gender,
      birthDate: birthDate,
      country: country,
    );
  }
}
