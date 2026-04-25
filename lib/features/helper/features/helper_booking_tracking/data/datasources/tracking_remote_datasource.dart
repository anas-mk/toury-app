import 'package:dio/dio.dart';
import '../../../../../../core/errors/exceptions.dart';
import 'package:toury/core/models/tracking/tracking_point_model.dart';

abstract class HelperTrackingRemoteDataSource {
  Future<TrackingPointModel> getLatestLocation(String bookingId);
  Future<List<TrackingPointModel>> getTrackingHistory(String bookingId);
}

class HelperTrackingRemoteDataSourceImpl implements HelperTrackingRemoteDataSource {
  final Dio dio;

  HelperTrackingRemoteDataSourceImpl({required this.dio});

  @override
  Future<TrackingPointModel> getLatestLocation(String bookingId) async {
    try {
      final response = await dio.get('/api/booking/$bookingId/tracking/latest');
      if (response.statusCode == 200 && response.data != null) {
        return TrackingPointModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to load latest location');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) throw ServerException('Not a participant in this booking');
      if (e.response?.statusCode == 404) throw ServerException('Booking not found');
      throw ServerException(e.message ?? 'Server Error');
    }
  }

  @override
  Future<List<TrackingPointModel>> getTrackingHistory(String bookingId) async {
    try {
      final response = await dio.get('/api/booking/$bookingId/tracking/history');
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data;
        return list.map((e) => TrackingPointModel.fromJson(e)).toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) throw ServerException('Not a participant in this booking');
      throw ServerException(e.message ?? 'Server Error');
    }
  }
}
