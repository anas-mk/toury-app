import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../repositories/interview_repository.dart';

class SubmitInterviewUseCase implements UseCase<Unit, String> {
  final InterviewRepository repository;

  SubmitInterviewUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String id, {CancelToken? cancelToken}) async {
    return await repository.submitInterview(id, cancelToken: cancelToken);
  }
}
