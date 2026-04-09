import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip token attachment for authentication routes
    if (options.path.contains('/auth/') || 
        options.path.contains('/Auth/') ||
        options.path.contains('login') || 
        options.path.contains('register')) {
      return handler.next(options);
    }

    final prefs = await SharedPreferences.getInstance();
    
    // Check for helper token first (as we are currently focusing on helper)
    final helperJson = prefs.getString('helper');
    String? token;
    
    if (helperJson != null) {
      final data = jsonDecode(helperJson);
      token = data['token'];
    }
    
    // Fallback to tourist token if helper token is not found
    if (token == null) {
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final data = jsonDecode(userJson);
        token = data['token'];
      }
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }
}
