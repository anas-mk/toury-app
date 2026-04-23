import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/helper_login_response_model.dart';
import '../models/helper_auth_response_model.dart';
import '../../domain/usecases/register_helper_usecase.dart';

abstract class HelperAuthRemoteDataSource {
  Future<HelperAuthResponseModel> registerHelper(HelperRegisterParams params);
  Future<HelperLoginResponseModel> login({required String email, required String password});
  Future<HelperAuthResponseModel> verifyLoginOtp({required String email, required String code});
  Future<HelperAuthResponseModel> verifyEmail({required String email, required String code});
  Future<void> resendLoginOtp(String email);
  Future<void> resendRegistrationCode(String email);
  Future<void> logout();
  
  // Password Reset
  Future<Map<String, dynamic>> forgotPassword(String email);
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}

class HelperAuthRemoteDataSourceImpl implements HelperAuthRemoteDataSource {
  final Dio dio;

  HelperAuthRemoteDataSourceImpl(this.dio);

  @override
  Future<HelperAuthResponseModel> registerHelper(HelperRegisterParams params) async {
    try {
      final Map<String, dynamic> formDataMap = {
        'fullName': params.fullName,
        'email': params.email,
        'password': params.password,
        'phoneNumber': params.phoneNumber,
        'gender': params.gender,
        'hasCar': params.hasCar,
      };

      if (params.birthDate != null) {
        formDataMap['birthDate'] = params.birthDate!.toIso8601String();
      }

      // Add car details if hasCar is true
      if (params.hasCar) {
        if (params.carBrand != null) formDataMap['carBrand'] = params.carBrand;
        if (params.carModel != null) formDataMap['carModel'] = params.carModel;
        if (params.carColor != null) formDataMap['carColor'] = params.carColor;
        if (params.carLicensePlate != null) formDataMap['carLicensePlate'] = params.carLicensePlate;
        if (params.carEnergyType != null) formDataMap['carEnergyType'] = params.carEnergyType;
        if (params.carType != null) formDataMap['carType'] = params.carType;
      }

      // Profile Image
      if (params.profileImagePath != null) {
        formDataMap['profileImage'] = await MultipartFile.fromFile(params.profileImagePath!);
      }

      // Core Verification Documents
      if (params.selfieImagePath != null) {
        formDataMap['selfieImage'] = await MultipartFile.fromFile(params.selfieImagePath!);
      }
      if (params.nationalIdFrontPath != null) {
        formDataMap['nationalIdFront'] = await MultipartFile.fromFile(params.nationalIdFrontPath!);
      }
      if (params.nationalIdBackPath != null) {
        formDataMap['nationalIdBack'] = await MultipartFile.fromFile(params.nationalIdBackPath!);
      }
      if (params.criminalRecordFilePath != null) {
        formDataMap['criminalRecordFile'] = await MultipartFile.fromFile(params.criminalRecordFilePath!);
      }
      if (params.drugTestFilePath != null) {
        formDataMap['drugTestFile'] = await MultipartFile.fromFile(params.drugTestFilePath!);
      }

      // Car Documents
      if (params.carLicenseFrontPath != null) {
        formDataMap['carLicenseFront'] = await MultipartFile.fromFile(params.carLicenseFrontPath!);
      }
      if (params.carLicenseBackPath != null) {
        formDataMap['carLicenseBack'] = await MultipartFile.fromFile(params.carLicenseBackPath!);
      }
      if (params.personalLicensePath != null) {
        formDataMap['personalLicense'] = await MultipartFile.fromFile(params.personalLicensePath!);
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await dio.post(
        ApiConfig.helperRegister,
        data: formData,
      );
      return HelperAuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<HelperLoginResponseModel> login({required String email, required String password}) async {
    try {
      final response = await dio.post(
        ApiConfig.helperLogin,
        data: {"email": email, "password": password},
      );
      return HelperLoginResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<HelperAuthResponseModel> verifyLoginOtp({required String email, required String code}) async {
    try {
      final response = await dio.post(
        ApiConfig.helperVerifyLoginOtp,
        data: {"email": email, "code": code},
      );
      return HelperAuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<HelperAuthResponseModel> verifyEmail({required String email, required String code}) async {
    try {
      final response = await dio.post(
        ApiConfig.helperVerifyEmail,
        data: {"email": email, "code": code},
      );
      return HelperAuthResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<void> resendLoginOtp(String email) async {
    try {
      await dio.post(
        ApiConfig.helperLoginOtp,
        data: {"email": email},
      );
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<void> resendRegistrationCode(String email) async {
    try {
      await dio.post(
        ApiConfig.helperResendCode,
        data: {"email": email},
      );
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<void> logout() async {
    return;
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await dio.post(
        ApiConfig.helperForgotPassword,
        data: {"email": email},
      );
      return response.data;
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await dio.post(
        ApiConfig.helperResetPassword,
        data: {
          "email": email,
          "code": code,
          "newPassword": newPassword,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    }
  }

  String _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map) {
        return data['message'] ?? data['error'] ?? 'Request failed';
      }
      return 'Error ${e.response?.statusCode}';
    }
    return 'Connection error. Please try again.';
  }
}
