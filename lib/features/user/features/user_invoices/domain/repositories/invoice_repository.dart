import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/invoice_entity.dart';

abstract class InvoiceRepository {
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices({int page = 1, int pageSize = 20});
  Future<Either<Failure, InvoiceEntity>> getInvoiceDetail(String invoiceId);
  Future<Either<Failure, InvoiceEntity>> getInvoiceByBooking(String bookingId);
  Future<Either<Failure, String>> getInvoiceHtml(String invoiceId);
}
