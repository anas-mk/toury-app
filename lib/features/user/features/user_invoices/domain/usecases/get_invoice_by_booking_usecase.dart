import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceByBookingUseCase implements UseCase<InvoiceEntity, String> {
  final InvoiceRepository repository;

  GetInvoiceByBookingUseCase(this.repository);

  @override
  Future<Either<Failure, InvoiceEntity>> call(String bookingId) async {
    return await repository.getInvoiceByBooking(bookingId);
  }
}
