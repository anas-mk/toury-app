import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import 'package:toury/core/models/tracking/tracking_point_model.dart';

abstract class TrackingRemoteDataSource {
  Future<TrackingPointModel> getLatestLocation(String bookingId);
  Future<List<TrackingPointModel>> getTrackingHistory(String bookingId);
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  final Dio dio;

  TrackingRemoteDataSourceImpl({required this.dio});

  @override
  Future<TrackingPointModel> getLatestLocation(String bookingId) async {
    try {
      final response = await dio.get(ApiConfig.getLatestLocation(bookingId));
      if (response.data == null) {
        throw ServerException('No location data available');
      }
      return TrackingPointModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ServerException('Booking not found');
      } else if (e.response?.statusCode == 403) {
        throw ServerException('Not authorized to track this booking');
      }
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<TrackingPointModel>> getTrackingHistory(String bookingId) async {
    try {
      final response = await dio.get(ApiConfig.getTrackingHistory(bookingId));
      final List<dynamic> items = response.data['items'] ?? response.data ?? [];
      return items.map((json) => TrackingPointModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
