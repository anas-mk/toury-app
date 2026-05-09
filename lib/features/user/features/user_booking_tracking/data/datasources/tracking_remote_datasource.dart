import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import 'package:toury/core/models/tracking/tracking_point_model.dart';

abstract class TrackingRemoteDataSource {
  /// Returns the latest known helper position for the booking, or
  /// `null` if the helper hasn't streamed any GPS sample yet (typical
  /// in the brief window between accept and `/start`, or before the
  /// first throttled sample).
  Future<TrackingPointModel?> getLatestLocation(String bookingId);
  Future<List<TrackingPointModel>> getTrackingHistory(String bookingId);
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  final Dio dio;

  TrackingRemoteDataSourceImpl({required this.dio});

  @override
  Future<TrackingPointModel?> getLatestLocation(String bookingId) async {
    try {
      final response = await dio.get(
        ApiConfig.getLatestLocation(bookingId),
      );
      final body = response.data;
      // Backend wraps every response in an `ApiResponse<T>` envelope:
      //   { success: bool, message: string, data: T? }
      //
      // When no GPS sample has been recorded yet the backend returns
      // HTTP 200 with `data: null` and a friendly message. We surface
      // that as `null` to the caller so the UI can show a calm
      // "Heading your way" placeholder instead of an error.
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner == null) return null;
        if (inner is Map<String, dynamic>) {
          return TrackingPointModel.fromJson(inner);
        }
      }
      // Unexpected envelope shape — log it once so we can spot a
      // backend contract change without crashing the live page.
      if (kDebugMode) {
        debugPrint(
          '[Tracking] /tracking/latest unexpected body shape: $body',
        );
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // 404 is "booking not found" per backend confirmation — not
        // "no samples yet". Treat as a real error.
        throw ServerException('Booking not found');
      }
      if (e.response?.statusCode == 403) {
        throw ServerException('Not authorized to track this booking');
      }
      throw ServerException(
        e.response?.data?['message'] ?? e.message ?? 'Server error',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[Tracking] /tracking/latest parse error: $e\n$st');
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<TrackingPointModel>> getTrackingHistory(String bookingId) async {
    try {
      final response = await dio.get(
        ApiConfig.getTrackingHistory(bookingId),
      );
      final body = response.data;
      // Same envelope shape — `data` is either a list of points
      // or an object with `items` for paginated history.
      List<dynamic> rawItems;
      if (body is Map<String, dynamic>) {
        final inner = body['data'];
        if (inner is List) {
          rawItems = inner;
        } else if (inner is Map<String, dynamic> && inner['items'] is List) {
          rawItems = inner['items'] as List;
        } else {
          rawItems = const [];
        }
      } else if (body is List) {
        rawItems = body;
      } else {
        rawItems = const [];
      }
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(TrackingPointModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['message'] ?? e.message ?? 'Server error',
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
