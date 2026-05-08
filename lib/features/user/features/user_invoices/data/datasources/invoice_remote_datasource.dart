import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../models/invoice_model.dart';

abstract class InvoiceRemoteDataSource {
  Future<List<InvoiceModel>> getInvoices({int page = 1, int pageSize = 20});
  Future<InvoiceModel> getInvoiceDetail(String invoiceId);
  Future<InvoiceModel> getInvoiceByBooking(String bookingId);
  Future<String> getInvoiceHtml(String invoiceId);
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final Dio dio;

  InvoiceRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<InvoiceModel>> getInvoices({int page = 1, int pageSize = 20}) async {
    try {
      final response = await dio.get(ApiConfig.getInvoices(page: page, pageSize: pageSize));
      // API wraps the paginated result under response → data → items
      final List<dynamic> data =
          (response.data['data'] as Map<String, dynamic>?)?['items'] ?? [];
      return data.map((json) => InvoiceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<InvoiceModel> getInvoiceDetail(String invoiceId) async {
    try {
      final response = await dio.get(ApiConfig.getInvoiceDetail(invoiceId));
      // API wraps result under response → data
      final data = response.data['data'] as Map<String, dynamic>;
      return InvoiceModel.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<InvoiceModel> getInvoiceByBooking(String bookingId) async {
    try {
      final response = await dio.get(ApiConfig.getInvoiceByBooking(bookingId));
      return InvoiceModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> getInvoiceHtml(String invoiceId) async {
    try {
      final response = await dio.get(
        ApiConfig.getInvoiceHtml(invoiceId),
        options: Options(responseType: ResponseType.plain),
      );
      return response.data.toString();
    } on DioException catch (e) {
      throw ServerException(e.response?.data?['message'] ?? e.message ?? 'Server error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
