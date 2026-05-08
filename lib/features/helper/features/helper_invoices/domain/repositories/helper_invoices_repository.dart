import '../../domain/entities/invoice_entities.dart';

abstract class HelperInvoicesRepository {
  Future<List<InvoiceEntity>> getInvoices({int page = 1, int pageSize = 20, String? status});
  Future<InvoiceDetailEntity> getInvoiceDetail(String invoiceId);
  Future<InvoiceSummaryEntity> getSummary();
  Future<String> getInvoiceHtml(String invoiceId);
}
