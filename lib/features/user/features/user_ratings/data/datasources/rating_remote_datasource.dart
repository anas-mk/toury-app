import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/rating_model.dart';

abstract class RatingRemoteDataSource {
  Future<void> rateHelper({
    required String bookingId,
    required int stars,
    required String comment,
    required List<String> tags,
  });

  Future<Map<String, dynamic>> getBookingRatingState(String bookingId);

  Future<List<RatingModel>> getHelperRatings(
    String helperId, {
    int page = 1,
    int pageSize = 10,
  });

  Future<RatingSummaryModel> getHelperRatingSummary(String helperId);

  Future<RatingSummaryModel> getUserRatingSummary(String userId);
}

class RatingRemoteDataSourceImpl implements RatingRemoteDataSource {
  final Dio dio;

  RatingRemoteDataSourceImpl({required this.dio});

  @override
  Future<void> rateHelper({
    required String bookingId,
    required int stars,
    required String comment,
    required List<String> tags,
  }) async {
    try {
      await dio.post(
        ApiConfig.rateHelper(bookingId),
        data: {
          'stars': stars,
          'comment': comment,
          'tags': tags,
        },
      );
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getBookingRatingState(String bookingId) async {
    try {
      final response = await dio.get(ApiConfig.getBookingRatingState(bookingId));
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<RatingModel>> getHelperRatings(
    String helperId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await dio.get(
        ApiConfig.getHelperRatings(helperId, page: page, pageSize: pageSize),
      );
      final List<dynamic> items = response.data['items'] ?? [];
      return items.map((json) => RatingModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RatingSummaryModel> getHelperRatingSummary(String helperId) async {
    try {
      final response = await dio.get(ApiConfig.getHelperRatingSummary(helperId));
      return RatingSummaryModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<RatingSummaryModel> getUserRatingSummary(String userId) async {
    try {
      final response = await dio.get(ApiConfig.getUserRatingSummary(userId));
      return RatingSummaryModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
