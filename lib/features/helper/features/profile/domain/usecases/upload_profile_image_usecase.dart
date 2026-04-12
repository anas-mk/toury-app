import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class UploadProfileImageUseCase {
  final ProfileRepository repository;
  UploadProfileImageUseCase(this.repository);

  Future<Either<Failure, String>> call(
    File image, {
    CancelToken? cancelToken,
  }) {
    return repository.uploadProfileImage(
      image: image,
      cancelToken: cancelToken,
    );
  }
}
