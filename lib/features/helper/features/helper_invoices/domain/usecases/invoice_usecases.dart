import '../entities/invoice_entities.dart';
import '../repositories/helper_invoices_repository.dart';

class GetInvoicesUseCase {
  final HelperInvoicesRepository repository;
  GetInvoicesUseCase(this.repository);
  Future<List<InvoiceEntity>> execute({int page = 1, int pageSize = 20, String? status}) =>
      repository.getInvoices(page: page, pageSize: pageSize, status: status);
}

class GetInvoiceDetailUseCase {
  final HelperInvoicesRepository repository;
  GetInvoiceDetailUseCase(this.repository);
  Future<InvoiceDetailEntity> execute(String invoiceId) => repository.getInvoiceDetail(invoiceId);
}

class GetInvoiceByBookingUseCase {
  final HelperInvoicesRepository repository;
  GetInvoiceByBookingUseCase(this.repository);
  Future<InvoiceDetailEntity> execute(String bookingId) => repository.getInvoiceByBooking(bookingId);
}

class GetInvoiceSummaryUseCase {
  final HelperInvoicesRepository repository;
  GetInvoiceSummaryUseCase(this.repository);
  Future<InvoiceSummaryEntity> execute() => repository.getSummary();
}

class GetInvoiceHtmlUseCase {
  final HelperInvoicesRepository repository;
  GetInvoiceHtmlUseCase(this.repository);
  Future<String> execute(String invoiceId) => repository.getInvoiceHtml(invoiceId);
}
