import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/helper_report_entities.dart';

abstract class HelperReportsRepository {
  Future<Either<Failure, List<HelperReportEntity>>> getCachedReports();
  Future<Either<Failure, void>> syncFromNotifications();
  Stream<HelperReportEntity> get resolutionEvents;
}

class GetCachedReportsUseCase {
  final HelperReportsRepository repository;
  GetCachedReportsUseCase(this.repository);

  Future<Either<Failure, List<HelperReportEntity>>> call() {
    return repository.getCachedReports();
  }
}

class SyncReportsUseCase {
  final HelperReportsRepository repository;
  SyncReportsUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.syncFromNotifications();
  }
}
