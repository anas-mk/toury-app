import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../repositories/interview_repository.dart';

class SubmitAnswerParams {
  final String interviewId;
  final int questionIndex;
  final File videoFile;

  SubmitAnswerParams({
    required this.interviewId,
    required this.questionIndex,
    required this.videoFile,
  });
}

class SubmitAnswerUseCase implements UseCase<Unit, SubmitAnswerParams> {
  final InterviewRepository repository;

  SubmitAnswerUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SubmitAnswerParams params, {CancelToken? cancelToken}) async {
    return await repository.submitAnswer(
      params.interviewId,
      params.questionIndex,
      params.videoFile,
      cancelToken: cancelToken,
    );
  }
}
