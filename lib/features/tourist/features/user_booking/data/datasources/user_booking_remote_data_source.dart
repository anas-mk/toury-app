import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/booking_detail_model.dart';
import '../models/helper_booking_model.dart';
import '../models/paged_response_model.dart';
import '../../domain/entities/search_params.dart';

abstract class UserBookingRemoteDataSource {
  Future<List<HelperBookingModel>> searchScheduledHelpers(ScheduledSearchParams params);
  Future<List<HelperBookingModel>> searchInstantHelpers(InstantSearchParams params);
  Future<HelperBookingModel> getHelperProfile(String helperId);
  Future<BookingDetailModel> createScheduledBooking(Map<String, dynamic> bookingData);
  Future<BookingDetailModel> createInstantBooking(Map<String, dynamic> bookingData);
  Future<BookingDetailModel> getBookingDetails(String bookingId);
  Future<PagedResponse<BookingDetailModel>> getMyBookings({int page = 1, int pageSize = 10, String? status});
  Future<void> cancelBooking(String bookingId, String reason);
  Future<List<HelperBookingModel>> getAlternatives(String bookingId);
  Future<String> getBookingStatus(String bookingId);
}

class UserBookingRemoteDataSourceImpl implements UserBookingRemoteDataSource {
  final Dio dio;

  UserBookingRemoteDataSourceImpl(this.dio);

  @override
  Future<List<HelperBookingModel>> searchScheduledHelpers(ScheduledSearchParams params) async {
    try {
      final response = await dio.post(ApiConfig.searchScheduledHelpers, data: params.toJson());
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => HelperBookingModel.fromJson(e)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Search failed');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HelperBookingModel>> searchInstantHelpers(InstantSearchParams params) async {
    try {
      final response = await dio.post(ApiConfig.searchInstantHelpers, data: params.toJson());
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => HelperBookingModel.fromJson(e)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Search failed');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<HelperBookingModel> getHelperProfile(String helperId) async {
    try {
      final response = await dio.get(ApiConfig.getHelperProfile(helperId));
      if (response.statusCode == 200) {
        return HelperBookingModel.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<BookingDetailModel> createScheduledBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await dio.post(ApiConfig.createScheduledBooking, data: bookingData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return BookingDetailModel.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message'] ?? 'Booking failed');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<BookingDetailModel> createInstantBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await dio.post(ApiConfig.createInstantBooking, data: bookingData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return BookingDetailModel.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message'] ?? 'Booking failed');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<BookingDetailModel> getBookingDetails(String bookingId) async {
    try {
      final response = await dio.get(ApiConfig.getBookingDetails(bookingId));
      if (response.statusCode == 200) {
        return BookingDetailModel.fromJson(response.data['data']);
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load booking');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PagedResponse<BookingDetailModel>> getMyBookings({int page = 1, int pageSize = 10, String? status}) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'pageSize': pageSize,
      };
      if (status != null && status != 'All') {
        queryParams['status'] = status;
      }
      final response = await dio.get(ApiConfig.getMyBookings, queryParameters: queryParams);
      if (response.statusCode == 200) {
        return PagedResponse<BookingDetailModel>.fromJson(
          response.data['data'],
          (json) => BookingDetailModel.fromJson(json),
        );
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load bookings');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      final response = await dio.post(ApiConfig.cancelBooking(bookingId), data: {'reason': reason});
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(response.data['message'] ?? 'Cancellation failed');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HelperBookingModel>> getAlternatives(String bookingId) async {
    try {
      final response = await dio.get(ApiConfig.getAlternatives(bookingId));
      if (response.statusCode == 200) {
        final data = response.data['data']['alternativeHelpers'] as List;
        return data.map((e) => HelperBookingModel.fromJson(e)).toList();
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to load alternatives');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> getBookingStatus(String bookingId) async {
    try {
      final response = await dio.get(ApiConfig.getBookingStatus(bookingId));
      if (response.statusCode == 200) {
        return response.data['data']['status'] ?? 'Unknown';
      } else {
        throw ServerException(response.data['message'] ?? 'Failed to get status');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
