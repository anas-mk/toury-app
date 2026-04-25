import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceHtmlUseCase implements UseCase<String, String> {
  final InvoiceRepository repository;

  GetInvoiceHtmlUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(String invoiceId) async {
    return await repository.getInvoiceHtml(invoiceId);
  }
}
