import 'package:dio/dio.dart';
import '../../../../../../core/config/api_config.dart';
import '../models/invoice_models.dart';

abstract class HelperInvoicesRemoteDataSource {
  Future<List<InvoiceModel>> getInvoices({int page = 1, int pageSize = 20, String? status});
  Future<InvoiceDetailModel> getInvoiceDetail(String invoiceId);
  Future<InvoiceSummaryModel> getSummary();
  Future<String> getInvoiceHtml(String invoiceId);
}

class HelperInvoicesRemoteDataSourceImpl implements HelperInvoicesRemoteDataSource {
  final Dio dio;
  HelperInvoicesRemoteDataSourceImpl(this.dio);

  @override
  Future<List<InvoiceModel>> getInvoices({int page = 1, int pageSize = 20, String? status}) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (status != null) params['status'] = status;

    final response = await dio.get(ApiConfig.helperInvoices, queryParameters: params);
    final raw = response.data;

    // Support both { data: [...] } and direct array response shapes
    final List list = (raw is Map && raw['data'] is List)
        ? raw['data'] as List
        : (raw is List ? raw : []);

    return list.map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<InvoiceDetailModel> getInvoiceDetail(String invoiceId) async {
    final response = await dio.get(ApiConfig.helperInvoiceById(invoiceId));
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return InvoiceDetailModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<InvoiceSummaryModel> getSummary() async {
    final response = await dio.get(ApiConfig.helperInvoiceSummary);
    final data = response.data is Map && response.data['data'] != null
        ? response.data['data']
        : response.data;
    return InvoiceSummaryModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<String> getInvoiceHtml(String invoiceId) async {
    final response = await dio.get(
      ApiConfig.helperInvoiceView(invoiceId),
      options: Options(responseType: ResponseType.plain),
    );
    return response.data.toString();
  }
}
