import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Map<String, dynamic>>> checkEmail(String email) async {
    try {
      final result = await remoteDataSource.checkEmail(email);
      return Right(result); // result = { message, action, email }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await remoteDataSource.verifyPassword(email, password);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
      return Right(user);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
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
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
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
      return Right(user);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      return Left(ServerFailure(message));
    }
  }






}
