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

  // Google Authentication
  Future<Map<String, dynamic>> googleLogin(String email);

  Future<UserModel> verifyGoogleCode({
    required String email,
    required String code,
  });
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
          'user': data['user'], // Include user data if present
        };
      } else {
        throw Exception('Google login failed');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  // ---------------- GOOGLE VERIFY CODE ----------------
  @override
  Future<UserModel> verifyGoogleCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await dio.post(
        ApiConfig.googleVerifyCode,
        data: {"email": email, "code": code},
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        return UserModel.fromJson(data['user']);
      } else {
        throw Exception('Google verification failed');
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
