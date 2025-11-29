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
      print('🔍 Checking email: $email');

      // ✅ Dio will automatically use baseUrl + endpoint
      final response = await dio.post(
        ApiConfig.loginEndpoint,
        data: {"email": email},
      );

      print('✅ Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data is String
            ? Map<String, dynamic>.from(jsonDecode(response.data))
            : Map<String, dynamic>.from(response.data);

        final Map<String, dynamic>? userData =
        data['data'] != null ? Map<String, dynamic>.from(data['data']) : null;

        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'action': data['action'] ?? '',
          'email': userData?['email'] ?? email,
          'userExists': userData?['userExists'] ?? false,
        };
      } else {
        throw Exception('Check email failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException in checkEmail: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      throw Exception(_handleDioError(e));
    } catch (e) {
      print('❌ Unknown error in checkEmail: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ---------------- VERIFY PASSWORD ----------------
  @override
  Future<UserModel> verifyPassword(String email, String password) async {
    try {
      print('🔐 Verifying password for: $email');

      final response = await dio.post(
        ApiConfig.verifyPassword,
        data: {"email": email, "password": password},
      );

      print('✅ Password verification response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data is String
            ? Map<String, dynamic>.from(jsonDecode(response.data))
            : Map<String, dynamic>.from(response.data);

        final Map<String, dynamic>? data =
        responseData['data'] != null ? Map<String, dynamic>.from(responseData['data']) : null;

        final Map<String, dynamic>? userData =
        data?['user'] != null ? Map<String, dynamic>.from(data!['user']) : null;

        if (userData == null) {
          throw Exception('Invalid response format: user not found');
        }

        final userJson = {
          ...userData,
          'token': data?['token'] ?? responseData['token'],
        };

        return UserModel.fromJson(userJson);
      } else if (response.statusCode == 401) {
        throw Exception('Incorrect password');
      } else {
        throw Exception('Login failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ DioException in verifyPassword: ${e.message}');
      throw Exception(_handleDioError(e));
    } catch (e) {
      print('❌ Unknown error in verifyPassword: $e');
      throw Exception('Unexpected error: $e');
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
      print('📝 Registering user: $email');

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
      );

      print('✅ Registration response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = response.data is String
            ? Map<String, dynamic>.from(jsonDecode(response.data))
            : Map<String, dynamic>.from(response.data);

        final userDataRaw = responseData['data']?['user'];
        final token = responseData['data']?['token'];

        if (userDataRaw == null) {
          throw Exception('Invalid response format: user not found');
        }

        final Map<String, dynamic> userData = Map<String, dynamic>.from(userDataRaw);

        final userJson = {
          ...userData,
          'token': token,
        };

        return UserModel.fromJson(userJson);
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        throw Exception('This email is already registered');
      } else {
        throw Exception('Register failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ DioException in register: ${e.message}');
      throw Exception(_handleDioError(e));
    } catch (e) {
      print('❌ Unknown error in register: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ---------------- GOOGLE LOGIN ----------------
  @override
  Future<Map<String, dynamic>> googleLogin(String email) async {
    try {
      print('🔐 Google login for: $email');

      final response = await dio.post(
        ApiConfig.googleLogin,
        data: {"email": email},
      );

      print('✅ Google login response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;
        return {
          'message': data['message'] ?? 'Google login successful',
          'action': data['action'] ?? 'login_success',
          'user': data['user'],
        };
      } else {
        throw Exception('Google login failed');
      }
    } on DioException catch (e) {
      print('❌ DioException in googleLogin: ${e.message}');
      throw Exception(_handleDioError(e));
    } catch (e) {
      print('❌ Unknown error in googleLogin: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ---------------- GOOGLE VERIFY CODE ----------------
  @override
  Future<UserModel> verifyGoogleCode({
    required String email,
    required String code,
  }) async {
    try {
      print('🔐 Verifying Google code for: $email');

      final response = await dio.post(
        ApiConfig.googleVerifyCode,
        data: {"email": email, "code": code},
      );

      print('✅ Google verification response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        return UserModel.fromJson(data['user']);
      } else {
        throw Exception('Google verification failed');
      }
    } on DioException catch (e) {
      print('❌ DioException in verifyGoogleCode: ${e.message}');
      throw Exception(_handleDioError(e));
    } catch (e) {
      print('❌ Unknown error in verifyGoogleCode: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // ---------------- PRIVATE ERROR HANDLER ----------------
  String _handleDioError(DioException e) {
    print('🔧 Handling Dio error: ${e.type}');

    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;

      print('📊 Status Code: $statusCode');
      print('📄 Response Data: $data');

      // ✅ Try to extract error message from response
      String errorMessage = 'Unknown error';

      if (data is Map) {
        errorMessage = data['message'] ??
            data['error'] ??
            data['title'] ??
            'Request failed';
      } else if (data is String) {
        errorMessage = data;
      }

      switch (statusCode) {
        case 400:
          return errorMessage.isNotEmpty ? errorMessage : 'Bad request. Please check your input.';
        case 401:
          return errorMessage.isNotEmpty ? errorMessage : 'Invalid credentials. Please try again.';
        case 403:
          return 'Access denied. Please contact support.';
        case 404:
          return 'Service not found. Please try again later.';
        case 409:
          return errorMessage.isNotEmpty ? errorMessage : 'Email already exists. Please use a different email.';
        case 422:
          return 'Invalid data provided. Please check your information.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return errorMessage.isNotEmpty ? errorMessage : 'Error $statusCode: ${data ?? 'Unknown error'}';
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