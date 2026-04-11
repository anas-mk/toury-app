import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/language_model.dart';
import '../../data/models/interview_model.dart';

abstract class InterviewRepository {
  Future<Either<Failure, List<LanguageModel>>> getLanguages({CancelToken? cancelToken});
  Future<Either<Failure, InterviewModel>> startInterview(String code, {CancelToken? cancelToken});
  Future<Either<Failure, InterviewModel>> getInterview(String id, {CancelToken? cancelToken});
  Future<Either<Failure, Unit>> submitAnswer(String id, int questionIndex, File videoFile, {CancelToken? cancelToken});
  Future<Either<Failure, Unit>> submitInterview(String id, {CancelToken? cancelToken});
  
  /// Fetches the fresh interview status to validate if submission is allowed.
  Future<Either<Failure, String>> getInterviewStatus(String id, {CancelToken? cancelToken});
}
