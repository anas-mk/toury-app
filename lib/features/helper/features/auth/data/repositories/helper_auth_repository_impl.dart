import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../models/helper_auth_response_model.dart';
import '../../domain/repositories/helper_auth_repository.dart';
import '../../domain/usecases/register_helper_usecase.dart';
import '../datasources/helper_auth_remote_data_source.dart';
import '../datasources/helper_local_data_source.dart';
import '../models/helper_login_response_model.dart';

class HelperAuthRepositoryImpl implements HelperAuthRepository {
  final HelperAuthRemoteDataSource remoteDataSource;
  final HelperLocalDataSource localDataSource;

  HelperAuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, HelperAuthResponseModel>> registerHelper(HelperRegisterParams params) async {
    try {
      final response = await remoteDataSource.registerHelper(params);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HelperLoginResponseModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(email: email, password: password);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HelperAuthResponseModel>> verifyLoginOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await remoteDataSource.verifyLoginOtp(email: email, code: code);
      if (response.data != null) {
        await localDataSource.cacheHelper(response.data!);
      }
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HelperAuthResponseModel>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await remoteDataSource.verifyEmail(email: email, code: code);
      if (response.data != null) {
        await localDataSource.cacheHelper(response.data!);
      }
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resendLoginOtp(String email) async {
    try {
      await remoteDataSource.resendLoginOtp(email);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> resendRegistrationCode(String email) async {
    try {
      await remoteDataSource.resendRegistrationCode(email);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearHelper();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> forgotPassword(String email) async {
    try {
      final response = await remoteDataSource.forgotPassword(email);
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await remoteDataSource.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
