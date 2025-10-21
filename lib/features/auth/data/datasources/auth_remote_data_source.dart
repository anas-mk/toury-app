import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:toury/core/config/api_config.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> checkEmail(String email);
  Future<UserModel> verifyPassword(String email, String password);
  Future<UserModel> register({
    required String email,
    required String userName,
    required String password,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    required String country,
  });
  Future<Map<String, dynamic>> forgotPassword(String email);
  Future<UserModel?> getCurrentUser(String token);
  Future<void> logout(String token);

  // Google Authentication
  Future<Map<String, dynamic>> googleLogin(String email);
  Future<Map<String, dynamic>> googleRegister({
    required String email,
    required String googleId,
    required String name,
  });
  Future<UserModel> verifyGoogleToken(String idToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl(this.dio);

  // ---------------- LOGIN CHECK EMAIL ----------------
  @override
  Future<Map<String, dynamic>> checkEmail(String email) async {
    try {
      final response = await dio.post(
        ApiConfig.loginEndpoint,
        data: {"email": email},
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        //  action
        return {
          'message': data['message'] ?? '',
          'action': data['action'] ?? '',
          'email': data['email'] ?? email,
        };
      } else {
        throw Exception('Check email failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ----------------LOGIN VERIFY PASSWORD ----------------
  @override
  Future<UserModel> verifyPassword(String email, String password) async {
    try {
      final response = await dio.post(
        ApiConfig.verifyPassword,
        data: {"email": email, "password": password},
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return UserModel.fromJson(data);
      } else {
        throw Exception('Incorrect password');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ---------------- REGISTER ----------------
  @override
  Future<UserModel> register({
    required String email,
    required String userName,
    required String password,
    required String phoneNumber,
    required String gender,
    required DateTime birthDate,
    required String country,
  }) async {
    try {
      final response = await dio.post(
        ApiConfig.registerEndpoint,
        data: {
          "email": email,
          "userName": userName,
          "password": password,
          "phoneNumber": phoneNumber,
          "gender": gender,
          "birthDate": birthDate.toIso8601String(),
          "country": country,
        },
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return UserModel.fromJson(data);
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        throw Exception('This email is already registered');
      } else {
        throw Exception('Register failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ---------------- FORGOT PASSWORD ----------------
  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await dio.post(
        ApiConfig.forgotPasswordEndpoint,
        data: {"email": email},
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return {
          'message': data['message'] ?? 'Password reset email sent',
          'success': data['success'] ?? true,
        };
      } else {
        throw Exception('Failed to send reset email');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ---------------- GET CURRENT USER ----------------
  @override
  Future<UserModel?> getCurrentUser(String token) async {
    try {
      final response = await dio.get(
        ApiConfig.profileEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            ...ApiConfig.defaultHeaders,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return UserModel.fromJson(data);
      } else {
        return null;
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ---------------- LOGOUT ----------------
  @override
  Future<void> logout(String token) async {
    try {
      await dio.post(
        ApiConfig.logoutEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            ...ApiConfig.defaultHeaders,
          },
        ),
      );
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ---------------- GOOGLE LOGIN ----------------
  @override
  Future<Map<String, dynamic>> googleLogin(String email) async {
    try {
      final response = await dio.post(
        ApiConfig.googleLogin,
        data: {"email": email},
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return {
          'message': data['message'] ?? 'Google login successful',
          'action': data['action'] ?? 'login_success',
        };
      } else {
        throw Exception('Google login failed');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ---------------- GOOGLE REGISTER ----------------
  @override
  Future<Map<String, dynamic>> googleRegister({
    required String email,
    required String googleId,
    required String name,
  }) async {
    try {
      final response = await dio.post(
        ApiConfig.googleRegister,
        data: {
          "email": email,
          "googleId": googleId,
          "name": name,
        },
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        return {
          'message': data['message'] ?? 'Google registration successful',
          'action': data['action'] ?? 'code_sent',
        };
      } else {
        throw Exception('Google registration failed');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }


  // ---------------- VERIFY GOOGLE TOKEN ----------------
  @override
  Future<UserModel> verifyGoogleToken(String idToken) async {
    try {
      final response = await dio.post(
        ApiConfig.verifyGoogleToken,
        data: {"idToken": idToken},
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return UserModel.fromJson(data);
      } else {
        throw Exception('Google token verification failed');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ---------------- PRIVATE ERROR HANDLER ----------------
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      switch (statusCode) {
        case 400:
          return 'Bad request. Please check your input.';
        case 401:
          return 'Invalid credentials. Please try again.';
        case 403:
          return 'Access denied. Please contact support.';
        case 404:
          return 'Service not found. Please try again later.';
        case 409:
          return 'Email already exists. Please use a different email.';
        case 422:
          return 'Invalid data provided. Please check your information.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Error ${statusCode}: ${data ?? 'Unknown error'}';
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    } else {
      return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}
