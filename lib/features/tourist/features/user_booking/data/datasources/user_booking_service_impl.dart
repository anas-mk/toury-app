import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/network/api_response.dart';
import '../../../../../../core/utils/logger.dart';
import '../models/alternative_helper_model.dart';
import '../models/booking_model.dart';
import '../models/booking_status_model.dart';
import '../models/helper_model.dart';
import 'user_booking_service.dart';

class UserBookingServiceImpl implements UserBookingService {
  final Dio dio;
  static const String _logName = 'UserBookingService';

  UserBookingServiceImpl({required this.dio});

  void _handleDioError(String endpoint, DioException e) {
    Logger.logError(_logName, endpoint, e.message, e.stackTrace);
    
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw TimeoutException();
    } else if (e.response?.statusCode == 401) {
      throw UnauthorizedException();
    } else if (e.response?.statusCode == 403) {
      throw ForbiddenException();
    }
    
    throw ServerException(e.message ?? 'Server Error');
  }

  @override
  Future<List<HelperModel>> searchScheduledHelpers({
    required String destination,
    required DateTime date,
    required String language,
    required bool needArabic,
    required int durationInMinutes,
  }) async {
    const endpoint = ApiConfig.searchScheduledHelpers;
    final data = {
      "DestinationCity": destination,
      "Date": date.toUtc().toIso8601String(),
      "Language": language,
      "DurationInMinutes": durationInMinutes,
      "NeedArabic": needArabic,
    };
    Logger.logRequest(_logName, 'POST', endpoint, data);

    try {
      final response = await dio.post(
        '${ApiConfig.baseUrl}$endpoint',
        data: data,
      );
      Logger.logResponse(_logName, endpoint, response.data);
      
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data,
        (json) => json as List<dynamic>,
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.map((e) => HelperModel.fromJson(e)).toList();
      } else {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      _handleDioError(endpoint, e);
      rethrow;
    }
  }

  @override
  Future<List<HelperModel>> searchInstantHelpers({
    required String pickupLocation,
    required double lat,
    required double lng,
  }) async {
    const endpoint = ApiConfig.searchInstantHelpers;
    final data = {
      "pickupLocation": pickupLocation,
      "lat": lat,
      "lng": lng,
    };
    Logger.logRequest(_logName, 'POST', endpoint, data);

    try {
      final response = await dio.post(
        '${ApiConfig.baseUrl}$endpoint',
        data: data,
      );
      Logger.logResponse(_logName, endpoint, response.data);
      
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data,
        (json) => json as List<dynamic>,
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!.map((e) => HelperModel.fromJson(e)).toList();
      } else {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      _handleDioError(endpoint, e);
      rethrow;
    }
  }

  @override
  Future<HelperModel> getHelperProfile(String helperId) async {
    final endpoint = ApiConfig.getHelperProfile(helperId);
    Logger.logRequest(_logName, 'GET', endpoint);

    try {
      final response = await dio.get('${ApiConfig.baseUrl}$endpoint');
      Logger.logResponse(_logName, endpoint, response.data);
      
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return HelperModel.fromJson(apiResponse.data!);
      } else {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      _handleDioError(endpoint, e);
      rethrow;
    }
  }

  @override
  Future<BookingModel> createScheduledBooking() async {
    const endpoint = ApiConfig.createScheduledBooking;
    Logger.logRequest(_logName, 'POST', endpoint);

    try {
      final response = await dio.post('${ApiConfig.baseUrl}$endpoint');
      Logger.logResponse(_logName, endpoint, response.data);
      
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return BookingModel.fromJson(apiResponse.data!);
      } else {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      _handleDioError(endpoint, e);
      rethrow;
    }
  }

  @override
  Future<BookingModel> createInstantBooking() async {
    const endpoint = ApiConfig.createInstantBooking;
    Logger.logRequest(_logName, 'POST', endpoint);

    try {
      final response = await dio.post('${ApiConfig.baseUrl}$endpoint');
      Logger.logResponse(_logName, endpoint, response.data);
      
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return BookingModel.fromJson(apiResponse.data!);
      } else {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      _handleDioError(endpoint, e);
      rethrow;
    }
  }

  @override
  Future<BookingModel> getBookingDetails(String bookingId) async {
    final endpoint = ApiConfig.getBookingDetails(bookingId);
    Logger.logRequest(_logName, 'GET', endpoint);

    try {
      final response = await dio.get('${ApiConfig.baseUrl}$endpoint');
      Logger.logResponse(_logName, endpoint, response.data);
      
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return BookingModel.fromJson(apiResponse.data!);
      } else {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      _handleDioError(endpoint, e);
      rethrow;
    }
  }

  @override
  Future<PaginatedResponse<BookingModel>> getMyBookings({
    String? status,
    String? type,
    int page = 1,
    int pageSize = 10,
  }) async {
    const endpoint = ApiConfig.getMyBookings;
    
    // Ensure null values are removed from query params
    final Map<String, dynamic> queryParams = {
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    
    Logger.logRequest(_logName, 'GET', endpoint, queryParams);

    try {
      final response = await dio.get(
        '${ApiConfig.baseUrl}$endpoint',
        queryParameters: queryParams,
      );
      Logger.logResponse(_logName, endpoint, response.data);
      
      return PaginatedResponse<BookingModel>.fromJson(
        response.data,
        (json) => BookingModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      _handleDioError(endpoint, e);
      rethrow;
    }
  }

  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    final endpoint = ApiConfig.cancelBooking(bookingId);
    final data = {"reason": reason};
    Logger.logRequest(_logName, 'POST', endpoint, data);

    try {
      final response = await dio.post(
        '${ApiConfig.baseUrl}$endpoint',
        data: data,
      );
      Logger.logResponse(_logName, endpoint, response.data);
      
      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.data,
        (json) => json,
      );
      
      if (!apiResponse.success) {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      _handleDioError(endpoint, e);
      rethrow;
    }
  }

  @override
  Future<List<AlternativeHelperModel>> getAlternatives(String bookingId) async {
    final endpoint = ApiConfig.getAlternatives(bookingId);
    Logger.logRequest(_logName, 'GET', endpoint);

    try {
      final response = await dio.get('${ApiConfig.baseUrl}$endpoint');
      Logger.logResponse(_logName, endpoint, response.data);
      
      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        response.data,
        (json) => json as List<dynamic>,
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!
            .map((e) => AlternativeHelperModel.fromJson(e))
            .toList();
      } else {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      _handleDioError(endpoint, e);
      rethrow;
    }
  }

  @override
  Future<BookingStatusModel> getBookingStatus(String bookingId) async {
    final endpoint = ApiConfig.getBookingStatus(bookingId);
    Logger.logRequest(_logName, 'GET', endpoint);

    try {
      final response = await dio.get('${ApiConfig.baseUrl}$endpoint');
      Logger.logResponse(_logName, endpoint, response.data);
      
      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
      
      if (apiResponse.success && apiResponse.data != null) {
        return BookingStatusModel.fromJson(apiResponse.data!);
      } else {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      _handleDioError(endpoint, e);
      rethrow;
    }
  }
}
