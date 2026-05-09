import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  // ✅ Update Profile with Profile Image
  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userName,
    required String? userId,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    required String country,
    File? profileImage,
  }) async {
    try {
      // Get current user to retrieve token
      final cachedUser = await localDataSource.getCurrentUser();

      if (cachedUser == null || cachedUser.token == null) {
        return Left(CacheFailure('No user logged in'));
      }

      final updatedUser = await remoteDataSource.updateProfile(
        token: cachedUser.token!,
        userId: cachedUser.userId,
        userName: userName,
        phoneNumber: phoneNumber,
        gender: gender,
        birthDate: birthDate,
        country: country,
        profileImage: profileImage,
      );

      // Cache the updated user
      await localDataSource.cacheUser(updatedUser);

      return Right(updatedUser);
    } catch (e) {
      return Left(ServerFailure(_cleanErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> patchProfile({
    String? userName,
    String? phoneNumber,
    String? gender,
    DateTime? birthDate,
    String? country,
    File? profileImage,
  }) async {
    try {
      final cachedUser = await localDataSource.getCurrentUser();

      if (cachedUser == null || cachedUser.token == null) {
        return Left(CacheFailure('No user logged in'));
      }
      final userId = cachedUser.userId;
      if (userId == null || userId.isEmpty) {
        return Left(CacheFailure('Cached user is missing userId'));
      }

      var updatedUser = await remoteDataSource.patchProfile(
        token: cachedUser.token!,
        userId: userId,
        userName: userName,
        phoneNumber: phoneNumber,
        gender: gender,
        birthDate: birthDate,
        country: country,
        profileImage: profileImage,
      );

      // Backend frequently omits unrelated fields from a partial update
      // response (e.g. updating just the name returns the user without
      // `profileImageUrl`, which `UserModel.fromJson` then resolves to the
      // hard-coded "default" placeholder). Merge the previous values back
      // in so the locally-cached user keeps its real photo / metadata
      // unless the caller explicitly changed those fields.
      updatedUser = updatedUser.copyWith(
        profileImageUrl: profileImage != null
            ? updatedUser.profileImageUrl
            : (_isDefaultOrEmpty(updatedUser.profileImageUrl)
                ? cachedUser.profileImageUrl
                : updatedUser.profileImageUrl),
        phoneNumber: phoneNumber ??
            (updatedUser.phoneNumber.isEmpty
                ? cachedUser.phoneNumber
                : updatedUser.phoneNumber),
        userName: userName ??
            (updatedUser.userName.isEmpty
                ? cachedUser.userName
                : updatedUser.userName),
        gender: gender ??
            (updatedUser.gender.isEmpty
                ? cachedUser.gender
                : updatedUser.gender),
        country: country ??
            (updatedUser.country.isEmpty
                ? cachedUser.country
                : updatedUser.country),
        birthDate: birthDate ?? updatedUser.birthDate ?? cachedUser.birthDate,
      );

      await localDataSource.cacheUser(updatedUser);
      return Right(updatedUser);
    } catch (e) {
      return Left(ServerFailure(_cleanErrorMessage(e.toString())));
    }
  }

  /// Treats the static "default avatar" URL as "no image" so a partial
  /// patch can fall back to the previous URL the user actually uploaded.
  bool _isDefaultOrEmpty(String? url) {
    if (url == null || url.isEmpty) return true;
    return url.contains('default.png') ||
        url.contains('e87ab0a15b2b65662020e614f7e05ef1');
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> checkEmail(String email) async {
    try {
      final result = await remoteDataSource.checkEmail(email);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_cleanErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyPassword(
      String email,
      String password,
      ) async {
    try {
      final user = await remoteDataSource.verifyPassword(email, password);
      await localDataSource.cacheUser(user);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(_cleanErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String userName,
    required String password,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    required String country,
  }) async {
    try {
      final user = await remoteDataSource.register(
        email: email,
        userName: userName,
        password: password,
        phoneNumber: phoneNumber,
        gender: gender,
        birthDate: birthDate,
        country: country,
      );
      await localDataSource.cacheUser(user);
      return Right(user);
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('VERIFICATION_NEEDED:')) {
        return Left(ServerFailure(errorMessage));
      }
      return Left(ServerFailure(_cleanErrorMessage(errorMessage)));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyRegistrationCode({
    required String email,
    required String code,
  }) async {
    try {
      final result = await remoteDataSource.verifyRegistrationCode(
        email: email,
        code: code,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_cleanErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> googleLogin(
      String email,
      ) async {
    try {
      final result = await remoteDataSource.googleLogin(email);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_cleanErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> forgotPassword(
      String email,
      ) async {
    try {
      final result = await remoteDataSource.forgotPassword(email);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_cleanErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final result = await remoteDataSource.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_cleanErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> resendVerificationCode(
      String email) async {
    try {
      final result = await remoteDataSource.resendVerificationCode(email);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_cleanErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCachedUser() async {
    try {
      final user = await localDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(CacheFailure(_cleanErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(_cleanErrorMessage(e.toString())));
    }
  }

  String _cleanErrorMessage(String message) {
    return message.replaceAll('Exception: ', '');
  }
}
