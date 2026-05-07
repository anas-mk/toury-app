import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/payment_model.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentModel> initiatePayment(String bookingId, String method);
  Future<PaymentModel> getPayment(String paymentId);
  Future<PaymentModel> getLatestPayment(String bookingId);
  Future<void> mockPaymentComplete(String paymentId, String action);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final Dio dio;

  PaymentRemoteDataSourceImpl({required this.dio});

  @override
  Future<PaymentModel> initiatePayment(String bookingId, String method) async {
    try {
      final response = await dio.post(
        ApiConfig.initiatePayment(bookingId),
        data: {'method': method},
      );
      return PaymentModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PaymentModel> getPayment(String paymentId) async {
    try {
      final response = await dio.get(ApiConfig.getPayment(paymentId));
      return PaymentModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PaymentModel> getLatestPayment(String bookingId) async {
    try {
      final response = await dio.get(ApiConfig.getLatestPayment(bookingId));
      return PaymentModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> mockPaymentComplete(String paymentId, String action) async {
    try {
      await dio.post(
        ApiConfig.mockPaymentComplete(paymentId),
        data: {'action': action},
      );
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
