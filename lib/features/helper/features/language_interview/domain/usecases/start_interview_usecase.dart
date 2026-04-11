import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../../data/models/interview_model.dart';
import '../repositories/interview_repository.dart';

class StartInterviewUseCase implements UseCase<InterviewModel, String> {
  final InterviewRepository repository;

  StartInterviewUseCase(this.repository);

  @override
  Future<Either<Failure, InterviewModel>> call(String code, {CancelToken? cancelToken}) async {
    return await repository.startInterview(code, cancelToken: cancelToken);
  }
}
