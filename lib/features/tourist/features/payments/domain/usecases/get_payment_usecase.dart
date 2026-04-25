import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class GetPaymentUseCase implements UseCase<PaymentEntity, String> {
  final PaymentRepository repository;

  GetPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentEntity>> call(String paymentId) async {
    return await repository.getPayment(paymentId);
  }
}
