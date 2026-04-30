import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/helper_booking_models.dart';
import '../models/helper_dashboard_model.dart';
import '../models/helper_earnings_models.dart';

abstract class HelperBookingsRemoteDataSource {
  Future<HelperDashboardModel> getDashboard({CancelToken? cancelToken});
  Future<void> updateAvailability(String availabilityState, {CancelToken? cancelToken});
  Future<PaginatedRequestsResponse> getRequests({
    String? type,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  });
  Future<HelperBookingModel> getRequestDetails(String id, {CancelToken? cancelToken});
  Future<HelperBookingModel> acceptRequest(String id, {CancelToken? cancelToken});
  Future<void> declineRequest(String id, {String? reason, CancelToken? cancelToken});
  Future<List<HelperBookingModel>> getUpcomingBookings({CancelToken? cancelToken});
  Future<HelperBookingModel?> getActiveBooking({CancelToken? cancelToken});
  Future<void> startTrip(String id, {CancelToken? cancelToken});
  Future<double> endTrip(String id, {CancelToken? cancelToken});
  Future<List<HelperBookingModel>> getHistory({
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  });
  Future<HelperEarningsModel> getEarnings({CancelToken? cancelToken});
  Future<HelperBookingModel> getBookingDetails(String id, {CancelToken? cancelToken});
}

class HelperBookingsRemoteDataSourceImpl implements HelperBookingsRemoteDataSource {
  final Dio dio;
  HelperBookingsRemoteDataSourceImpl(this.dio);

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
  Future<HelperDashboardModel> getDashboard({CancelToken? cancelToken}) async {
    try {
      final res = await dio.get(ApiConfig.helperDashboard, cancelToken: cancelToken);
      _assertOk(res);
      return HelperDashboardModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<void> updateAvailability(String availabilityState, {CancelToken? cancelToken}) async {
    try {
      debugPrint('🟢 [Availability][API] Sending Payload: {"availabilityState": "$availabilityState"}');
      final res = await dio.post(
        ApiConfig.helperAvailability,
        data: {'availabilityState': availabilityState},
        cancelToken: cancelToken,
      );
      _assertOk(res);
      debugPrint('✅ [Availability][API] Success: $availabilityState');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw ServerException('Invalid state change');
      }
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<PaginatedRequestsResponse> getRequests({
    String? type,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      if (type != null && type.isNotEmpty) {
        params['type'] = type;
      }
      
      final res = await dio.get(
        ApiConfig.helperRequests,
        queryParameters: params,
        cancelToken: cancelToken,
      );
      _assertOk(res);
      
      // Handle both paginated and non-paginated responses
      final raw = res.data;
      if (raw is Map && raw['data'] is Map && raw['data']['items'] is List) {
        // New paginated format
        return PaginatedRequestsResponse.fromJson(raw as Map<String, dynamic>);
      } else if (raw is Map && raw['data'] is List) {
        // Old non-paginated format - wrap in pagination structure
        final list = raw['data'] as List;
        return PaginatedRequestsResponse(
          items: list.map((e) => HelperBookingModel.fromJson(e as Map<String, dynamic>)).toList(),
          page: page,
          pageSize: pageSize,
          totalCount: list.length,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        );
      } else if (raw is List) {
        // Direct list format - wrap in pagination structure
        return PaginatedRequestsResponse(
          items: raw.map((e) => HelperBookingModel.fromJson(e as Map<String, dynamic>)).toList(),
          page: page,
          pageSize: pageSize,
          totalCount: raw.length,
          totalPages: 1,
          hasNextPage: false,
          hasPreviousPage: false,
        );
      }
      
      // Empty response
      return PaginatedRequestsResponse(
        items: const [],
        page: page,
        pageSize: pageSize,
        totalCount: 0,
        totalPages: 0,
        hasNextPage: false,
        hasPreviousPage: false,
      );
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<HelperBookingModel> getRequestDetails(String id, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.get(ApiConfig.helperRequestDetails(id), cancelToken: cancelToken);
      _assertOk(res);
      return HelperBookingModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<HelperBookingModel> acceptRequest(String id, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.post(ApiConfig.helperAcceptRequest(id), cancelToken: cancelToken);
      _assertOk(res);
      return HelperBookingModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<void> declineRequest(String id, {String? reason, CancelToken? cancelToken}) async {
    try {
      final res = await dio.post(ApiConfig.helperDeclineRequest(id),
          data: reason != null ? {'reason': reason} : null, cancelToken: cancelToken);
      _assertOk(res);
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<List<HelperBookingModel>> getUpcomingBookings({CancelToken? cancelToken}) async {
    try {
      final res = await dio.get(ApiConfig.helperUpcoming, cancelToken: cancelToken);
      _assertOk(res);
      final raw = res.data;
      final list = (raw is Map && raw['data'] is List)
          ? raw['data'] as List
          : (raw is List ? raw : []);
      return list.map((e) => HelperBookingModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<HelperBookingModel?> getActiveBooking({CancelToken? cancelToken}) async {
    try {
      final res = await dio.get(ApiConfig.helperActiveBooking, cancelToken: cancelToken);
      _assertOk(res);
      final raw = res.data;
      if (raw == null) return null;
      final d = (raw is Map && raw['data'] != null) ? raw['data'] : raw;
      if (d == null) return null;
      return HelperBookingModel.fromJson(d as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<void> startTrip(String id, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.post(ApiConfig.helperStartTrip(id), cancelToken: cancelToken);
      _assertOk(res);
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<double> endTrip(String id, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.post(ApiConfig.helperEndTrip(id), cancelToken: cancelToken);
      _assertOk(res);
      final raw = res.data;
      final earnings = (raw is Map) ? (raw['data']?['earnings'] ?? raw['earnings'] ?? 0) : 0;
      return (earnings as num).toDouble();
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<List<HelperBookingModel>> getHistory({
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 10,
    CancelToken? cancelToken,
  }) async {
    try {
      final normalizedPageSize = pageSize.clamp(1, 50);
      final params = <String, dynamic>{'page': page, 'pageSize': normalizedPageSize};
      if (status != null && status.trim().isNotEmpty) {
        params['status'] = status.trim();
      }
      if (from != null) params['from'] = from.toIso8601String();
      if (to != null) params['to'] = to.toIso8601String();
      final res = await dio.get(ApiConfig.helperHistory,
          queryParameters: params, cancelToken: cancelToken);
      _assertOk(res);
      final raw = res.data;
      final list = (raw is Map && raw['data'] is Map && raw['data']['items'] is List)
          ? raw['data']['items'] as List
          : (raw is Map && raw['data'] is List)
              ? raw['data'] as List
              : (raw is Map && raw['items'] is List)
                  ? raw['items'] as List
                  : (raw is List ? raw : []);
      return list.map((e) => HelperBookingModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<HelperEarningsModel> getEarnings({CancelToken? cancelToken}) async {
    try {
      final res = await dio.get(ApiConfig.helperEarnings, cancelToken: cancelToken);
      _assertOk(res);
      return HelperEarningsModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }

  @override
  Future<HelperBookingModel> getBookingDetails(String id, {CancelToken? cancelToken}) async {
    try {
      final res = await dio.get(ApiConfig.helperBookingDetails(id), cancelToken: cancelToken);
      _assertOk(res);
      return HelperBookingModel.fromJson(_data(res.data));
    } on DioException catch (e) {
      throw ServerException(_msg(e));
    }
  }
}
