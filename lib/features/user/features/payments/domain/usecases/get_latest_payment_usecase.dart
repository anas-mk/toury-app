import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class GetLatestPaymentUseCase implements UseCase<PaymentEntity, String> {
  final PaymentRepository repository;

  GetLatestPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentEntity>> call(String bookingId) async {
    return await repository.getLatestPayment(bookingId);
  }
}
