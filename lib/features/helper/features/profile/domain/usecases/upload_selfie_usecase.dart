import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class UploadSelfieUseCase {
  final ProfileRepository repository;
  UploadSelfieUseCase(this.repository);

  Future<Either<Failure, String>> call(
    File image, {
    CancelToken? cancelToken,
  }) {
    return repository.uploadSelfie(
      image: image,
      cancelToken: cancelToken,
    );
  }
}
