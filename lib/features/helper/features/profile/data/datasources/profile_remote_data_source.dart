import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/car_model.dart';
import '../models/certificate_model.dart';
import '../models/helper_profile_model.dart';
import '../models/helper_eligibility_model.dart';
import '../models/helper_status_model.dart';

// ── Abstract contract ────────────────────────────────────────────────────────

abstract class ProfileRemoteDataSource {
  Future<HelperProfileModel> getProfile({CancelToken? cancelToken});
  Future<HelperStatusModel> getStatus({CancelToken? cancelToken});
  Future<HelperEligibilityModel> checkEligibility({CancelToken? cancelToken});

  Future<HelperProfileModel> updateBasicInfo({
    required String fullName,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    CancelToken? cancelToken,
  });

  Future<String> uploadProfileImage({
    required File image,
    CancelToken? cancelToken,
  });

  Future<String> uploadSelfie({
    required File image,
    CancelToken? cancelToken,
  });

  Future<void> uploadDocuments({
    required File nationalIdFront,
    required File nationalIdBack,
    File? criminalRecord,
    File? drugTest,
    CancelToken? cancelToken,
  });

  Future<CarModel> addOrUpdateCar({
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

  Future<void> deleteCar({CancelToken? cancelToken});

  Future<CertificateModel> addCertificate({
    required String name,
    String? issuingOrganization,
    DateTime? issueDate,
    DateTime? expiryDate,
    File? certificateFile,
    CancelToken? cancelToken,
  });

  Future<void> deleteCertificate({
    required String certificateId,
    CancelToken? cancelToken,
  });
}

// ── Implementation ───────────────────────────────────────────────────────────

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSourceImpl(this.dio);

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Extracts a human-readable message from any Dio error response body.
  String _handleDioError(DioException e) {
    if (CancelToken.isCancel(e)) return 'Request cancelled';
    final data = e.response?.data;
    if (data is Map) {
      return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    }
    return e.message ?? 'Connection error. Please try again.';
  }

  /// Converts a non-2xx response code into a typed [ServerException].
  void _assertSuccess(Response response) {
    final status = response.statusCode ?? 0;
    if (status == 400) {
      final data = response.data;
      final msg = data is Map
          ? (data['message'] ?? data['error'] ?? 'Validation error').toString()
          : 'Validation error';
      throw ValidationException(msg);
    }
    if (status == 401) throw UnauthorizedException();
    if (status == 403) throw ForbiddenException();
    if (status >= 400) {
      final data = response.data;
      final msg = data is Map
          ? (data['message'] ?? 'Request failed').toString()
          : 'Request failed';
      throw ServerException(msg);
    }
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  @override
  Future<HelperProfileModel> getProfile({CancelToken? cancelToken}) async {
    try {
      final response = await dio.get(
        ApiConfig.helperProfile,
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      return HelperProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<HelperStatusModel> getStatus({CancelToken? cancelToken}) async {
    try {
      final response = await dio.get(
        ApiConfig.helperStatus,
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      final data = response.data as Map<String, dynamic>;
      return HelperStatusModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<HelperEligibilityModel> checkEligibility({CancelToken? cancelToken}) async {
    try {
      final response = await dio.get(
        ApiConfig.helperEligibility,
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      final data = response.data as Map<String, dynamic>;
      return HelperEligibilityModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  // ── Update Basic Info ────────────────────────────────────────────────────────

  @override
  Future<HelperProfileModel> updateBasicInfo({
    required String fullName,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.put(
        ApiConfig.helperProfileBasicInfo,
        data: {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'gender': gender,
          'birthDate': birthDate.toIso8601String(),
        },
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      return HelperProfileModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  // ── Media Uploads ────────────────────────────────────────────────────────────

  @override
  Future<String> uploadProfileImage({
    required File image,
    CancelToken? cancelToken,
  }) async {
    try {
      final fileName = image.path.split('/').last;
      final formData = FormData.fromMap({
        'profileImage': await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        ),
      });
      final response = await dio.put(
        ApiConfig.helperProfileImage,
        data: formData,
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      final data = response.data;
      return (data is Map
          ? (data['profileImageUrl'] ?? data['data'] ?? '').toString()
          : '');
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<String> uploadSelfie({
    required File image,
    CancelToken? cancelToken,
  }) async {
    try {
      final fileName = image.path.split('/').last;
      final formData = FormData.fromMap({
        'selfieImage': await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        ),
      });
      final response = await dio.put(
        ApiConfig.helperProfileSelfie,
        data: formData,
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      final data = response.data;
      return (data is Map
          ? (data['selfieImageUrl'] ?? data['data'] ?? '').toString()
          : '');
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<void> uploadDocuments({
    required File nationalIdFront,
    required File nationalIdBack,
    File? criminalRecord,
    File? drugTest,
    CancelToken? cancelToken,
  }) async {
    try {
      final formDataMap = <String, dynamic>{
        'nationalIdFront': await MultipartFile.fromFile(
          nationalIdFront.path,
          filename: nationalIdFront.path.split('/').last,
        ),
        'nationalIdBack': await MultipartFile.fromFile(
          nationalIdBack.path,
          filename: nationalIdBack.path.split('/').last,
        ),
      };

      if (criminalRecord != null) {
        formDataMap['criminalRecordFile'] = await MultipartFile.fromFile(
          criminalRecord.path,
          filename: criminalRecord.path.split('/').last,
        );
      }
      if (drugTest != null) {
        formDataMap['drugTestFile'] = await MultipartFile.fromFile(
          drugTest.path,
          filename: drugTest.path.split('/').last,
        );
      }

      final response = await dio.put(
        ApiConfig.helperProfileDocuments,
        data: FormData.fromMap(formDataMap),
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  // ── Car ─────────────────────────────────────────────────────────────────────

  @override
  Future<CarModel> addOrUpdateCar({
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
      final formDataMap = <String, dynamic>{
        'brand': brand,
        'model': model,
        'color': color,
        'licensePlate': licensePlate,
        'energyType': energyType,
        'carType': carType,
      };

      if (carLicenseFront != null) {
        formDataMap['carLicenseFront'] = await MultipartFile.fromFile(
          carLicenseFront.path,
          filename: carLicenseFront.path.split('/').last,
        );
      }
      if (carLicenseBack != null) {
        formDataMap['carLicenseBack'] = await MultipartFile.fromFile(
          carLicenseBack.path,
          filename: carLicenseBack.path.split('/').last,
        );
      }

      final response = await dio.put(
        ApiConfig.helperProfileCar,
        data: FormData.fromMap(formDataMap),
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      final data = response.data;
      final carData = (data is Map && data['data'] is Map)
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return CarModel.fromJson(carData);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<void> deleteCar({CancelToken? cancelToken}) async {
    try {
      final response = await dio.delete(
        ApiConfig.helperProfileCarDelete,
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  // ── Certificates ─────────────────────────────────────────────────────────────

  @override
  Future<CertificateModel> addCertificate({
    required String name,
    String? issuingOrganization,
    DateTime? issueDate,
    DateTime? expiryDate,
    File? certificateFile,
    CancelToken? cancelToken,
  }) async {
    try {
      final formDataMap = <String, dynamic>{
        'name': name,
        if (issuingOrganization != null)
          'issuingOrganization': issuingOrganization,
        if (issueDate != null) 'issueDate': issueDate.toIso8601String(),
        if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
      };

      if (certificateFile != null) {
        formDataMap['certificateFile'] = await MultipartFile.fromFile(
          certificateFile.path,
          filename: certificateFile.path.split('/').last,
        );
      }

      final response = await dio.post(
        ApiConfig.helperProfileCertificates,
        data: FormData.fromMap(formDataMap),
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
      final data = response.data;
      final certData = (data is Map && data['data'] is Map)
          ? data['data'] as Map<String, dynamic>
          : data as Map<String, dynamic>;
      return CertificateModel.fromJson(certData);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<void> deleteCertificate({
    required String certificateId,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dio.delete(
        ApiConfig.helperProfileCertificateById(certificateId),
        cancelToken: cancelToken,
      );
      _assertSuccess(response);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }
}
