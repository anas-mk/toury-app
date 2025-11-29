import 'package:dartz/dartz.dart';
import 'package:toury/features/tourist/features/auth/data/models/user_model.dart';
import '../../../../../../core/errors/failures.dart';
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

  // Google Authentication
  Future<Either<Failure, Map<String, dynamic>>> googleLogin(String email);

  Future<Either<Failure, UserModel>> verifyGoogleCode({
    required String email,
    required String code,
  });

  //  Added: Local storage methods
  Future<Either<Failure, UserEntity?>> getCachedUser();
  Future<Either<Failure, void>> logout();
}