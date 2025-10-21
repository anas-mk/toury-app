import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> checkEmail(String email);
  Future<Either<Failure, UserEntity>> verifyPassword(
    String email,
    String password,
  );
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String userName,
    required String password,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    required String country,
  });
  Future<Either<Failure, String>> forgotPassword(String email);
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, void>> logout();

  // Google Authentication
  Future<Either<Failure, Map<String, dynamic>>> googleLogin(String email);
  Future<Either<Failure, Map<String, dynamic>>> googleRegister({
    required String googleId,
    required String name,
    required String email,
  });
  Future<Either<Failure, UserEntity>> verifyGoogleToken(String idToken);
}
