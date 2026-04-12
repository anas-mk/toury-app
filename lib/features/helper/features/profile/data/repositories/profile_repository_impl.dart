import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/car_entity.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../../domain/entities/helper_status_entity.dart';
import '../../domain/entities/helper_eligibility_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

/// Bridges the data layer (models, remote source) and the domain layer.
///
/// Error mapping strategy:
///   [ValidationException]    → [ValidationFailure]
///   [UnauthorizedException]  → [UnauthorizedFailure]
///   [ForbiddenException]     → [ForbiddenFailure]
///   [ServerException]        → [ServerFailure]
///   Anything else            → [ServerFailure]
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  // ── Internal error mapper ────────────────────────────────────────────────────

  Failure _mapException(Object e) {
    if (e is ValidationException) return ValidationFailure(e.message);
    if (e is UnauthorizedException) return UnauthorizedFailure(e.message);
    if (e is ForbiddenException) return ForbiddenFailure(e.message);
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return ServerFailure(e.toString());
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, HelperProfileEntity>> getProfile({
    CancelToken? cancelToken,
  }) async {
    try {
      final model =
          await remoteDataSource.getProfile(cancelToken: cancelToken);
      return Right(model); // model IS-A HelperProfileEntity
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, HelperStatusEntity>> getStatus({
    CancelToken? cancelToken,
  }) async {
    try {
      final statusModel =
          await remoteDataSource.getStatus(cancelToken: cancelToken);
      return Right(statusModel);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, HelperEligibilityEntity>> checkEligibility({
    CancelToken? cancelToken,
  }) async {
    try {
      final eligibilityModel =
          await remoteDataSource.checkEligibility(cancelToken: cancelToken);
      return Right(eligibilityModel);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  // ── Update Basic Info ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, HelperProfileEntity>> updateBasicInfo({
    required String fullName,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final model = await remoteDataSource.updateBasicInfo(
        fullName: fullName,
        phoneNumber: phoneNumber,
        gender: gender,
        birthDate: birthDate,
        cancelToken: cancelToken,
      );
      return Right(model);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  // ── Media Uploads ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> uploadProfileImage({
    required File image,
    CancelToken? cancelToken,
  }) async {
    try {
      final url = await remoteDataSource.uploadProfileImage(
        image: image,
        cancelToken: cancelToken,
      );
      return Right(url);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadSelfie({
    required File image,
    CancelToken? cancelToken,
  }) async {
    try {
      final url = await remoteDataSource.uploadSelfie(
        image: image,
        cancelToken: cancelToken,
      );
      return Right(url);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> uploadDocuments({
    required File nationalIdFront,
    required File nationalIdBack,
    File? criminalRecord,
    File? drugTest,
    CancelToken? cancelToken,
  }) async {
    try {
      await remoteDataSource.uploadDocuments(
        nationalIdFront: nationalIdFront,
        nationalIdBack: nationalIdBack,
        criminalRecord: criminalRecord,
        drugTest: drugTest,
        cancelToken: cancelToken,
      );
      return const Right(unit);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  // ── Car ─────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, CarEntity>> addOrUpdateCar({
    required String brand,
    required String model,
    required String color,
    required String licensePlate,
    required String energyType,
    required String carType,
    File? carLicenseFront,
    File? carLicenseBack,
    CancelToken? cancelToken,
  }) async {
    try {
      final carModel = await remoteDataSource.addOrUpdateCar(
        brand: brand,
        model: model,
        color: color,
        licensePlate: licensePlate,
        energyType: energyType,
        carType: carType,
        carLicenseFront: carLicenseFront,
        carLicenseBack: carLicenseBack,
        cancelToken: cancelToken,
      );
      return Right(carModel); // CarModel IS-A CarEntity
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCar({
    CancelToken? cancelToken,
  }) async {
    try {
      await remoteDataSource.deleteCar(cancelToken: cancelToken);
      return const Right(unit);
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  // ── Certificates ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, CertificateEntity>> addCertificate({
    required String name,
    String? issuingOrganization,
    DateTime? issueDate,
    DateTime? expiryDate,
    File? certificateFile,
    CancelToken? cancelToken,
  }) async {
    try {
      final certModel = await remoteDataSource.addCertificate(
        name: name,
        issuingOrganization: issuingOrganization,
        issueDate: issueDate,
        expiryDate: expiryDate,
        certificateFile: certificateFile,
        cancelToken: cancelToken,
      );
      return Right(certModel); // CertificateModel IS-A CertificateEntity
    } catch (e) {
      return Left(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCertificate({
    required String certificateId,
    CancelToken? cancelToken,
  }) async {
    try {
      await remoteDataSource.deleteCertificate(
        certificateId: certificateId,
        cancelToken: cancelToken,
      );
      return const Right(unit);
    } catch (e) {
      return Left(_mapException(e));
    }
  }
}
