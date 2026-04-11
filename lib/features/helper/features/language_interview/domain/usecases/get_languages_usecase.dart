import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../../data/models/language_model.dart';
import '../repositories/interview_repository.dart';

class GetLanguagesUseCase implements UseCase<List<LanguageModel>, NoParams> {
  final InterviewRepository repository;

  GetLanguagesUseCase(this.repository);

  @override
  Future<Either<Failure, List<LanguageModel>>> call(NoParams params, {CancelToken? cancelToken}) async {
    return await repository.getLanguages(cancelToken: cancelToken);
  }
}
