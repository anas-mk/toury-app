import '../../domain/entities/invoice_entities.dart';
import '../../domain/repositories/helper_invoices_repository.dart';
import '../datasources/helper_invoices_remote_data_source.dart';

class HelperInvoicesRepositoryImpl implements HelperInvoicesRepository {
  final HelperInvoicesRemoteDataSource remoteDataSource;
  HelperInvoicesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<InvoiceEntity>> getInvoices({int page = 1, int pageSize = 20, String? status}) async {
    final models = await remoteDataSource.getInvoices(page: page, pageSize: pageSize, status: status);
    return models
        .map<InvoiceEntity>((m) => InvoiceEntity(
              invoiceId: m.invoiceId,
              invoiceNumber: m.invoiceNumber,
              bookingId: m.bookingId,
              userName: m.userName,
              helperName: m.helperName,
              destinationCity: m.destinationCity,
              totalAmount: m.totalAmount,
              currency: m.currency,
              status: m.status,
              paymentStatus: m.paymentStatus,
              paymentMethod: m.paymentMethod,
              issuedAt: m.issuedAt,
            ))
        .toList();
  }

  @override
  Future<InvoiceDetailEntity> getInvoiceDetail(String invoiceId) async {
    final m = await remoteDataSource.getInvoiceDetail(invoiceId);
    return _mapDetail(m);
  }

  @override
  Future<InvoiceDetailEntity> getInvoiceByBooking(String bookingId) async {
    final m = await remoteDataSource.getInvoiceByBooking(bookingId);
    return _mapDetail(m);
  }

  @override
  Future<InvoiceSummaryEntity> getSummary() async {
    final m = await remoteDataSource.getSummary();
    return InvoiceSummaryEntity(
      grossAmount: m.grossAmount,
      commissionAmount: m.commissionAmount,
      netAmount: m.netAmount,
      invoiceCount: m.invoiceCount,
      currency: m.currency,
    );
  }

  @override
  Future<String> getInvoiceHtml(String invoiceId) =>
      remoteDataSource.getInvoiceHtml(invoiceId);

  InvoiceDetailEntity _mapDetail(m) => InvoiceDetailEntity(
        invoiceId: m.invoiceId,
        invoiceNumber: m.invoiceNumber,
        bookingId: m.bookingId,
        userName: m.userName,
        helperName: m.helperName,
        destinationCity: m.destinationCity,
        tripStartTime: m.tripStartTime,
        tripEndTime: m.tripEndTime,
        durationMinutes: m.durationMinutes,
        basePrice: m.basePrice,
        distanceCost: m.distanceCost,
        durationCost: m.durationCost,
        surchargeAmount: m.surchargeAmount,
        subtotal: m.subtotal,
        commissionAmount: m.commissionAmount,
        commissionRate: m.commissionRate,
        netAmount: m.netAmount,
        totalAmount: m.totalAmount,
        currency: m.currency,
        status: m.status,
        paymentStatus: m.paymentStatus,
        paymentMethod: m.paymentMethod,
        issuedAt: m.issuedAt,
        paidAt: m.paidAt,
        notes: m.notes,
      );
}
