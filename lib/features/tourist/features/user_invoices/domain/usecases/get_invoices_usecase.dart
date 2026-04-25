import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class GetInvoicesUseCase implements UseCase<List<InvoiceEntity>, GetInvoicesParams> {
  final InvoiceRepository repository;

  GetInvoicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<InvoiceEntity>>> call(GetInvoicesParams params) async {
    return await repository.getInvoices(page: params.page, pageSize: params.pageSize);
  }
}

class GetInvoicesParams {
  final int page;
  final int pageSize;

  GetInvoicesParams({this.page = 1, this.pageSize = 20});
}
