import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../errors/exceptions.dart';

/// [AuthInterceptor]
///
/// Responsibilities:
///   1. Attach JWT token to every non-auth request.
///   2. Handle 401 (Unauthorized) globally — throw [UnauthorizedException].
///   3. Handle 403 (Forbidden)   globally — throw [ForbiddenException].
///
/// The Cubit layer must NEVER handle auth-routing logic.
/// Navigation to login screen after 401/403 should be wired via a listener
/// on the root navigator (e.g. BlocListener on AuthCubit / global stream).
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // ── Skip token attachment for auth-scoped routes ──────────────────────────
    final path = options.path;
    final isAuthRoute = path.contains('/auth/') ||
        path.contains('/Auth/') ||
        path.contains('login') ||
        path.contains('register');

    if (!isAuthRoute) {
      final token = await _resolveToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ── Intercept 401 at response level (some APIs return 401 as 2xx body) ───
    if (response.statusCode == 401) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: UnauthorizedException(
            _extractMessage(response.data) ?? 'Session expired. Please log in again.',
          ),
        ),
        true,
      );
      return;
    }

    if (response.statusCode == 403) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: ForbiddenException(
            _extractMessage(response.data) ?? 'You do not have permission to perform this action.',
          ),
        ),
        true,
      );
      return;
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      final message = _extractMessage(err.response?.data) ??
          'Session expired. Please log in again.';
      return handler.next(
        err.copyWith(error: UnauthorizedException(message)),
      );
    }

    if (statusCode == 403) {
      final message = _extractMessage(err.response?.data) ??
          'You do not have permission to perform this action.';
      return handler.next(
        err.copyWith(error: ForbiddenException(message)),
      );
    }

    return handler.next(err);
  }

  // ── Private Helpers ──────────────────────────────────────────────────────────

  /// Resolves the bearer token from SharedPreferences.
  /// Helper token takes priority over tourist token.
  Future<String?> _resolveToken() async {
    final prefs = await SharedPreferences.getInstance();

    final helperJson = prefs.getString('helper');
    if (helperJson != null) {
      final data = jsonDecode(helperJson) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) return token;
    }

    final userJson = prefs.getString('user');
    if (userJson != null) {
      final data = jsonDecode(userJson) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) return token;
    }

    return null;
  }

  /// Safely extracts a human-readable message from the response body.
  String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
  }
}
