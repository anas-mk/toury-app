import 'package:dio/dio.dart';
import '../models/rating_models.dart';

abstract class HelperRatingsService {
  Future<void> submitUserRating(String bookingId, int stars, String? comment, List<String> tags);
  Future<RatingStatusModel> getBookingRatingStatus(String bookingId);
  Future<List<RatingModel>> getReceivedRatings({int page = 1, int pageSize = 20});
  Future<RatingSummaryModel> getRatingsSummary();
}

class HelperRatingsServiceImpl implements HelperRatingsService {
  final Dio dio;
  HelperRatingsServiceImpl(this.dio);

  @override
  Future<void> submitUserRating(String bookingId, int stars, String? comment, List<String> tags) async {
    await dio.post(
      '/helper/ratings/booking/$bookingId/user',
      data: {
        'stars': stars,
        'comment': comment,
        'tags': tags,
      },
    );
  }

  @override
  Future<RatingStatusModel> getBookingRatingStatus(String bookingId) async {
    final response = await dio.get('/helper/ratings/booking/$bookingId');
    return RatingStatusModel.fromJson(response.data);
  }

  @override
  Future<List<RatingModel>> getReceivedRatings({int page = 1, int pageSize = 20}) async {
    final response = await dio.get(
      '/helper/ratings/received',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    return (response.data as List).map((r) => RatingModel.fromJson(r)).toList();
  }

  @override
  Future<RatingSummaryModel> getRatingsSummary() async {
    final response = await dio.get('/helper/ratings/summary');
    return RatingSummaryModel.fromJson(response.data);
  }
}
