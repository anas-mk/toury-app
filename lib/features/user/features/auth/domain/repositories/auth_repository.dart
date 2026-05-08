import 'dart:io';
import 'package:dartz/dartz.dart';
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

  // Update Profile with Profile Image
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userName,
    required String userId,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    required String country,
    File? profileImage,
  });

  /// Partial update: only the fields the caller passes are sent to the
  /// backend (`PUT /Auth/update-profile`). Used by the new profile screen
  /// which lets users edit one field at a time.
  Future<Either<Failure, UserEntity>> patchProfile({
    String? userName,
    String? phoneNumber,
    String? gender,
    DateTime? birthDate,
    String? country,
    File? profileImage,
  });

  // Google Authentication
  Future<Either<Failure, Map<String, dynamic>>> googleLogin(String email);

  // Forgot Password & Reset Password
  Future<Either<Failure, Map<String, dynamic>>> forgotPassword(String email);
  Future<Either<Failure, Map<String, dynamic>>> resendVerificationCode(String email);

  Future<Either<Failure, Map<String, dynamic>>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  // Local storage methods
  Future<Either<Failure, UserEntity?>> getCachedUser();
  Future<Either<Failure, void>> logout();

  Future<Either<Failure, Map<String, dynamic>>> verifyRegistrationCode({
    required String email,
    required String code
  });
}
