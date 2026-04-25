import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/helper_rating_models.dart';

abstract class HelperRatingsRemoteDataSource {
  Future<void> rateUser({
    required String bookingId,
    required double stars,
    required String comment,
    required List<String> tags,
    CancelToken? cancelToken,
  });

  Future<RatingStateModel> getBookingRatingState(String bookingId, {CancelToken? cancelToken});

  Future<List<RatingModel>> getReceivedRatings({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  });

  Future<RatingsSummaryModel> getRatingsSummary({CancelToken? cancelToken});
}

class HelperRatingsRemoteDataSourceImpl implements HelperRatingsRemoteDataSource {
  final Dio dio;
  HelperRatingsRemoteDataSourceImpl(this.dio);

  String _msg(DioException e) {
    if (CancelToken.isCancel(e)) return 'Request cancelled';
    final data = e.response?.data;
    if (data is Map) return (data['message'] ?? data['error'] ?? 'Request failed').toString();
    return e.message ?? 'Connection error. Please try again.';
  }

  void _assertOk(Response response) {
    final s = response.statusCode ?? 0;
    if (s == 400) {
      final d = response.data;
      throw ValidationException(d is Map ? (d['message'] ?? d['error'] ?? 'Validation error').toString() : 'Validation error');
    }
    if (s == 401) throw UnauthorizedException();
    if (s == 403) throw ForbiddenException();
    if (s == 404) throw NotFoundException();
    if (s >= 400) {
      final d = response.data;
      throw ServerException(d is Map ? (d['message'] ?? 'Request failed').toString() : 'Request failed');
    }
  }

  Map<String, dynamic> _data(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['data'] is Map<String, dynamic>) return raw['data'] as Map<String, dynamic>;
      return raw;
    }
    return {};
  }

  @override
  Future<void> rateUser({
    required String bookingId,
    required double stars,
    required String comment,
    required List<String> tags,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.post(
        ApiConfig.helperRateUser(bookingId),
        data: {
          'stars': stars,
          'comment': comment,
          'tags': tags,
        },
        cancelToken: cancelToken,
      );
      _assertOk(res);
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<RatingStateModel> getBookingRatingState(String bookingId, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.get(
        ApiConfig.helperBookingRatingState(bookingId),
        cancelToken: cancelToken,
      );
      _assertOk(res);
      return RatingStateModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<List<RatingModel>> getReceivedRatings({
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get(
        ApiConfig.helperReceivedRatings,
        queryParameters: {'page': page, 'pageSize': pageSize},
        cancelToken: cancelToken,
      );
      _assertOk(res);
      final raw = res.data;
      final list = (raw is Map && raw['data'] is List)
          ? raw['data'] as List
          : (raw is Map && raw['items'] is List)
              ? raw['items'] as List
              : (raw is List ? raw : []);
      return list.map((e) => RatingModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<RatingsSummaryModel> getRatingsSummary({CancelToken? cancelToken}) async {
    try {
      final res = await dio.get(
        ApiConfig.helperRatingsSummary,
        cancelToken: cancelToken,
      );
      _assertOk(res);
      return RatingsSummaryModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }
}
