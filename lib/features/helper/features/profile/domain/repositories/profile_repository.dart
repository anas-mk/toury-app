import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/car_entity.dart';
import '../entities/certificate_entity.dart';
import '../entities/helper_profile_entity.dart';
import '../entities/helper_status_entity.dart';
import '../entities/helper_eligibility_entity.dart';

/// Contract for all Helper Profile operations.
/// Implemented in the data layer — never imported by the presentation layer directly.
abstract class ProfileRepository {
  // ── Read ────────────────────────────────────────────────────────────────────

  /// Fetch the full helper profile.
  Future<Either<Failure, HelperProfileEntity>> getProfile({
    CancelToken? cancelToken,
  });

  /// Fetch the helper's current account status string.
  Future<Either<Failure, HelperStatusEntity>> getStatus({
    CancelToken? cancelToken,
  });

  /// Check whether the helper is eligible to accept tours.
  Future<Either<Failure, HelperEligibilityEntity>> checkEligibility({
    CancelToken? cancelToken,
  });

  // ── Update Basic Info ────────────────────────────────────────────────────────

  Future<Either<Failure, HelperProfileEntity>> updateBasicInfo({
    required String fullName,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    CancelToken? cancelToken,
  });

  // ── Media Uploads ────────────────────────────────────────────────────────────

  Future<Either<Failure, String>> uploadProfileImage({
    required File image,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, String>> uploadSelfie({
    required File image,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, Unit>> uploadDocuments({
    required File nationalIdFront,
    required File nationalIdBack,
    File? criminalRecord,
    File? drugTest,
    CancelToken? cancelToken,
  });

  // ── Car ─────────────────────────────────────────────────────────────────────

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
  });

  Future<Either<Failure, Unit>> deleteCar({
    CancelToken? cancelToken,
  });

  // ── Certificates ─────────────────────────────────────────────────────────────

  Future<Either<Failure, CertificateEntity>> addCertificate({
    required String name,
    String? issuingOrganization,
    DateTime? issueDate,
    DateTime? expiryDate,
    File? certificateFile,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, Unit>> deleteCertificate({
    required String certificateId,
    CancelToken? cancelToken,
  });
}
