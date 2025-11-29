import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

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
      // Cache user after successful login
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
      // Cache user after successful registration
      await localDataSource.cacheUser(user);
      return Right(user);
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
  Future<Either<Failure, UserModel>> verifyGoogleCode({
    required String email,
    required String code,
  }) async {
    try {
      final user = await remoteDataSource.verifyGoogleCode(
        email: email,
        code: code,
      );
      // ✅ Cache user after successful Google verification
      await localDataSource.cacheUser(user);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(_cleanErrorMessage(e.toString())));
    }
  }

  // ✅ Added: Get cached user
  @override
  Future<Either<Failure, UserEntity?>> getCachedUser() async {
    try {
      final user = await localDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(CacheFailure(_cleanErrorMessage(e.toString())));
    }
  }

  // ✅ Added: Logout method
  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(_cleanErrorMessage(e.toString())));
    }
  }

  // ✅ Added: Helper method to clean error messages
  String _cleanErrorMessage(String message) {
    return message.replaceAll('Exception: ', '');
  }
}