import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceDetailUseCase implements UseCase<InvoiceEntity, String> {
  final InvoiceRepository repository;

  GetInvoiceDetailUseCase(this.repository);

  @override
  Future<Either<Failure, InvoiceEntity>> call(String invoiceId) async {
    return await repository.getInvoiceDetail(invoiceId);
  }
}
