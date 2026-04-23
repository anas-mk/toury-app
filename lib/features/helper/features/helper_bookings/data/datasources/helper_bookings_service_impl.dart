import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../models/helper_booking_model.dart';
import 'helper_bookings_service.dart';

class HelperBookingsServiceImpl implements HelperBookingsService {
  final Dio dio;

  HelperBookingsServiceImpl(this.dio);

  @override
  Future<List<HelperBookingModel>> getRequests() async {
    final response = await dio.get('${ApiConfig.baseUrl}/api/helper/bookings/requests');
    final List data = response.data['data'] ?? [];
    return data.map((e) => HelperBookingModel.fromJson(e)).toList();
  }

  @override
  Future<void> acceptBooking(String bookingId) async {
    await dio.post('${ApiConfig.baseUrl}/api/helper/bookings/$bookingId/accept');
  }

  @override
  Future<List<HelperBookingModel>> getUpcomingBookings() async {
    final response = await dio.get('${ApiConfig.baseUrl}/api/helper/bookings/upcoming');
    final List data = response.data['data'] ?? [];
    return data.map((e) => HelperBookingModel.fromJson(e)).toList();
  }

  @override
  Future<void> startTrip(String bookingId) async {
    await dio.post('${ApiConfig.baseUrl}/api/helper/bookings/$bookingId/start');
  }

  @override
  Future<void> endTrip(String bookingId) async {
    await dio.post('${ApiConfig.baseUrl}/api/helper/bookings/$bookingId/end');
  }

  @override
  Future<HelperBookingModel?> getActiveBooking() async {
    final response = await dio.get('${ApiConfig.baseUrl}/api/helper/bookings/active');
    if (response.data['data'] == null) return null;
    return HelperBookingModel.fromJson(response.data['data']);
  }

  @override
  Future<List<HelperBookingModel>> getHistory() async {
    final response = await dio.get('${ApiConfig.baseUrl}/api/helper/bookings/history');
    final List data = response.data['data'] ?? [];
    return data.map((e) => HelperBookingModel.fromJson(e)).toList();
  }
}
