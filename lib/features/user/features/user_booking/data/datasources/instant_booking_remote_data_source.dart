import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../domain/entities/create_instant_booking_request.dart';
import '../../domain/entities/instant_search_request.dart';
import '../models/alternatives_response_model.dart';
import '../models/booking_detail_response_model.dart';
import '../models/booking_status_response_model.dart';
import '../models/helper_booking_profile_model.dart';
import '../models/helper_search_result_model.dart';
import '../models/json_helpers.dart';

/// REST client for the Instant booking flow. All public methods either return
/// a parsed model or throw one of:
///   - [ServerException]        — wraps the backend's `message` for 400/5xx
///   - [UnauthorizedException]  — 401 (re-thrown from the auth interceptor)
///   - [ForbiddenException]     — 403 (re-thrown from the auth interceptor)
abstract class InstantBookingRemoteDataSource {
  Future<List<HelperSearchResultModel>> searchInstantHelpers(
    InstantSearchRequest request,
  );

  Future<HelperBookingProfileModel> getHelperBookingProfile(String helperId);

  Future<BookingDetailModel> createInstantBooking(
    CreateInstantBookingRequest request,
  );

  Future<BookingStatusResponseModel> getBookingStatus(String bookingId);

  Future<BookingDetailModel> getBookingDetail(String bookingId);

  Future<AlternativesResponseModel> getAlternatives(String bookingId);

  Future<BookingDetailModel> cancelBooking(String bookingId, String reason);
}

class InstantBookingRemoteDataSourceImpl
    implements InstantBookingRemoteDataSource {
  final Dio dio;
  InstantBookingRemoteDataSourceImpl(this.dio);

  @override
  Future<List<HelperSearchResultModel>> searchInstantHelpers(
    InstantSearchRequest request,
  ) async {
    return _run<List<HelperSearchResultModel>>(
      () async {
        final body = request.toJson();
        _logRequest('SEARCH', '🛰️', 'POST', ApiConfig.searchInstantHelpers, body);
        final res = await dio.post(
          ApiConfig.searchInstantHelpers,
          data: body,
        );
        _logResponse('SEARCH', '🛰️', res);
        _ensureSuccess(res);
        final envelope = envelopeData(res.data as Map<String, dynamic>);
        final list = (envelope['helpers'] as List?) ?? [];
        return list
            .whereType<Map<String, dynamic>>()
            .map(HelperSearchResultModel.fromJson)
            .toList();
      },
      label: 'searchInstantHelpers',
    );
  }

  @override
  Future<HelperBookingProfileModel> getHelperBookingProfile(
    String helperId,
  ) async {
    return _run<HelperBookingProfileModel>(
      () async {
        final url = ApiConfig.getHelperProfile(helperId);
        _logRequest('PROFILE', '👤', 'GET', url, null);
        final res = await dio.get(url);
        _logResponse('PROFILE', '👤', res);
        _ensureSuccess(res);
        return HelperBookingProfileModel.fromJson(
          envelopeData(res.data as Map<String, dynamic>),
        );
      },
      label: 'getHelperBookingProfile',
    );
  }

  @override
  Future<BookingDetailModel> createInstantBooking(
    CreateInstantBookingRequest request,
  ) async {
    return _run<BookingDetailModel>(
      () async {
        final body = request.toJson();
        _logRequest('CREATE', '🛎️', 'POST', ApiConfig.createInstantBooking, body);
        final res = await dio.post(
          ApiConfig.createInstantBooking,
          data: body,
        );
        _logResponse('CREATE', '🛎️', res);
        _ensureSuccess(res);
        return BookingDetailModel.fromJson(
          envelopeData(res.data as Map<String, dynamic>),
        );
      },
      label: 'createInstantBooking',
    );
  }

  @override
  Future<BookingStatusResponseModel> getBookingStatus(String bookingId) async {
    return _run<BookingStatusResponseModel>(
      () async {
        final url = ApiConfig.getBookingStatus(bookingId);
        _logRequest('STATUS', '📡', 'GET', url, null);
        final res = await dio.get(url);
        _logResponse('STATUS', '📡', res);
        _ensureSuccess(res);
        return BookingStatusResponseModel.fromJson(
          envelopeData(res.data as Map<String, dynamic>),
        );
      },
      label: 'getBookingStatus',
    );
  }

  @override
  Future<BookingDetailModel> getBookingDetail(String bookingId) async {
    return _run<BookingDetailModel>(
      () async {
        final url = ApiConfig.getBookingDetails(bookingId);
        _logRequest('DETAILS', '📄', 'GET', url, null);
        final res = await dio.get(url);
        _logResponse('DETAILS', '📄', res);
        _ensureSuccess(res);
        return BookingDetailModel.fromJson(
          envelopeData(res.data as Map<String, dynamic>),
        );
      },
      label: 'getBookingDetail',
    );
  }

  @override
  Future<AlternativesResponseModel> getAlternatives(String bookingId) async {
    return _run<AlternativesResponseModel>(
      () async {
        final url = ApiConfig.getAlternatives(bookingId);
        _logRequest('ALTERNATIVES', '🔄', 'GET', url, null);
        final res = await dio.get(url);
        _logResponse('ALTERNATIVES', '🔄', res);
        _ensureSuccess(res);
        return AlternativesResponseModel.fromJson(
          envelopeData(res.data as Map<String, dynamic>),
        );
      },
      label: 'getAlternatives',
    );
  }

  @override
  Future<BookingDetailModel> cancelBooking(
    String bookingId,
    String reason,
  ) async {
    return _run<BookingDetailModel>(
      () async {
        final url = ApiConfig.cancelBooking(bookingId);
        final body = {'reason': reason};
        _logRequest('CANCEL', '🛑', 'POST', url, body);
        final res = await dio.post(url, data: body);
        _logResponse('CANCEL', '🛑', res);
        _ensureSuccess(res);
        final data = envelopeData(res.data as Map<String, dynamic>);
        if (data['bookingType'] != null) {
          return BookingDetailModel.fromJson(data);
        }
        return getBookingDetail(bookingId);
      },
      label: 'cancelBooking',
    );
  }

  // ── Logging helpers ────────────────────────────────────────────────────────

  /// Logs the URL, method, headers, and request body in chunks small enough
  /// for the platform `print` ring buffer (debugPrint splits very long
  /// strings, but `jsonEncode` of a body with deep nesting can still get
  /// truncated on Android — split into 800-char lines just to be safe).
  void _logRequest(
    String tag,
    String emoji,
    String method,
    String url,
    Object? body,
  ) {
    if (!kDebugMode) return;
    final fullUrl = _absoluteUrl(url);
    debugPrint('$emoji [$tag] $method $fullUrl');
    final headers = dio.options.headers.entries
        .map((e) => '${e.key}: ${_redactHeader(e.key, e.value)}')
        .join('\n     ');
    if (headers.isNotEmpty) debugPrint('   headers=\n     $headers');
    if (body != null) {
      try {
        final encoded = jsonEncode(body);
        _logChunked('   body', encoded);
      } catch (_) {
        debugPrint('   body=$body');
      }
    }
  }

  void _logResponse(String tag, String emoji, Response res) {
    if (!kDebugMode) return;
    debugPrint('$emoji [$tag] ← status=${res.statusCode}');
    final data = res.data;
    String encoded;
    try {
      encoded = jsonEncode(data);
    } catch (_) {
      encoded = '$data';
    }
    _logChunked('   data', encoded);
  }

  void _logChunked(String label, String text) {
    const chunk = 800;
    if (text.length <= chunk) {
      debugPrint('$label=$text');
      return;
    }
    debugPrint('$label=(${text.length} chars)');
    for (var i = 0; i < text.length; i += chunk) {
      final end = (i + chunk).clamp(0, text.length);
      debugPrint('   …${text.substring(i, end)}');
    }
  }

  String _absoluteUrl(String path) {
    final base = dio.options.baseUrl;
    if (path.startsWith('http')) return path;
    if (base.isEmpty) return path;
    if (base.endsWith('/') && path.startsWith('/')) {
      return '$base${path.substring(1)}';
    }
    if (!base.endsWith('/') && !path.startsWith('/')) {
      return '$base/$path';
    }
    return '$base$path';
  }

  String _redactHeader(String key, Object? value) {
    final lower = key.toLowerCase();
    if (lower == 'authorization' || lower == 'cookie' || lower == 'x-api-key') {
      final s = value?.toString() ?? '';
      if (s.length <= 12) return '•••';
      return '${s.substring(0, 8)}…${s.substring(s.length - 4)}';
    }
    return value?.toString() ?? '';
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  /// Wraps [body] with consistent error handling.
  Future<T> _run<T>(Future<T> Function() body, {required String label}) async {
    try {
      return await body();
    } on DioException catch (e) {
      throw _mapDioException(e, label: label);
    } on UnauthorizedException {
      rethrow;
    } on ForbiddenException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('💥 [$label] unexpected error: $e');
      throw ServerException('Unexpected error');
    }
  }

  /// Throws [ServerException] when status is non-2xx (the auth interceptor
  /// would have already short-circuited 401/403 into typed exceptions).
  void _ensureSuccess(Response res) {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final message = _extractMessage(res.data) ?? 'Request failed ($code)';
    throw ServerException(message);
  }

  /// Translates a [DioException] to one of our domain-level exceptions.
  Exception _mapDioException(DioException e, {required String label}) {
    // Auth interceptor already rewrote 401/403 errors as Unauthorized/Forbidden.
    if (e.error is UnauthorizedException) return e.error as UnauthorizedException;
    if (e.error is ForbiddenException) return e.error as ForbiddenException;

    final code = e.response?.statusCode;
    if (code == 400) {
      final msg =
          _extractMessage(e.response?.data) ?? 'Invalid request';
      debugPrint('🚫 [$label] 400 → $msg');
      return ServerException(msg);
    }
    if (code == 404) {
      final msg = _extractMessage(e.response?.data) ?? 'Not found';
      return ServerException(msg);
    }
    if (code == 409) {
      final msg = _extractMessage(e.response?.data) ?? 'Conflict';
      return ServerException(msg);
    }
    if (code != null && code >= 500) {
      return ServerException('Server error. Please try again.');
    }

    final fallback = e.message ?? 'Network error';
    debugPrint('🌐 [$label] network error → $fallback');
    return ServerException(fallback);
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
      final err = data['error'];
      if (err is String && err.isNotEmpty) return err;
    }
    return null;
  }
}
