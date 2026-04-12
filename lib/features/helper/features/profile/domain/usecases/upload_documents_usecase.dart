import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/errors/failures.dart';
import '../repositories/profile_repository.dart';

class UploadDocumentsUseCase {
  final ProfileRepository repository;
  UploadDocumentsUseCase(this.repository);

  Future<Either<Failure, Unit>> call(
    UploadDocumentsParams params, {
    CancelToken? cancelToken,
  }) {
    return repository.uploadDocuments(
      nationalIdFront: params.nationalIdFront,
      nationalIdBack: params.nationalIdBack,
      criminalRecord: params.criminalRecord,
      drugTest: params.drugTest,
      cancelToken: cancelToken,
    );
  }
}

class UploadDocumentsParams extends Equatable {
  final File nationalIdFront;
  final File nationalIdBack;
  final File? criminalRecord;
  final File? drugTest;

  const UploadDocumentsParams({
    required this.nationalIdFront,
    required this.nationalIdBack,
    this.criminalRecord,
    this.drugTest,
  });

  @override
  List<Object?> get props => [
        nationalIdFront,
        nationalIdBack,
        criminalRecord,
        drugTest,
      ];
}
