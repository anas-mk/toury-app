import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/certificate_entity.dart';
import '../repositories/profile_repository.dart';

class AddCertificateUseCase {
  final ProfileRepository repository;
  AddCertificateUseCase(this.repository);

  Future<Either<Failure, CertificateEntity>> call(
    AddCertificateParams params, {
    CancelToken? cancelToken,
  }) {
    return repository.addCertificate(
      name: params.name,
      issuingOrganization: params.issuingOrganization,
      issueDate: params.issueDate,
      expiryDate: params.expiryDate,
      certificateFile: params.certificateFile,
      cancelToken: cancelToken,
    );
  }
}

class AddCertificateParams extends Equatable {
  final String name;
  final String? issuingOrganization;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final File? certificateFile;

  const AddCertificateParams({
    required this.name,
    this.issuingOrganization,
    this.issueDate,
    this.expiryDate,
    this.certificateFile,
  });

  @override
  List<Object?> get props => [
        name,
        issuingOrganization,
        issueDate,
        expiryDate,
        certificateFile,
      ];
}
