import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/datasources/interview_remote_data_source.dart';
import '../../data/models/language_model.dart';
import '../../data/models/interview_model.dart';
import '../../domain/repositories/interview_repository.dart';

class InterviewRepositoryImpl implements InterviewRepository {
  final InterviewRemoteDataSource remoteDataSource;

  InterviewRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<LanguageModel>>> getLanguages({CancelToken? cancelToken}) async {
    try {
      final languages = await remoteDataSource.getLanguages(cancelToken: cancelToken);
      return Right(languages);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InterviewModel>> startInterview(String code, {CancelToken? cancelToken}) async {
    try {
      final interview = await remoteDataSource.startInterview(code, cancelToken: cancelToken);
      return Right(interview);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InterviewModel>> getInterview(String id, {CancelToken? cancelToken}) async {
    try {
      final interview = await remoteDataSource.getInterview(id, cancelToken: cancelToken);
      return Right(interview);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> submitAnswer(String id, int questionIndex, File videoFile, {CancelToken? cancelToken}) async {
    try {
      await remoteDataSource.submitAnswer(id, questionIndex, videoFile, cancelToken: cancelToken);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> submitInterview(String id, {CancelToken? cancelToken}) async {
    try {
      await remoteDataSource.submitInterview(id, cancelToken: cancelToken);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getInterviewStatus(String id, {CancelToken? cancelToken}) async {
    try {
      final interview = await remoteDataSource.getInterview(id, cancelToken: cancelToken);
      return Right(interview.status);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
