import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class DeleteCertificateUseCase {
  final ProfileRepository repository;
  DeleteCertificateUseCase(this.repository);

  Future<Either<Failure, Unit>> call(
    String certificateId, {
    CancelToken? cancelToken,
  }) {
    return repository.deleteCertificate(
      certificateId: certificateId,
      cancelToken: cancelToken,
    );
  }
}
