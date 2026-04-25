import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class InitiatePaymentUseCase implements UseCase<PaymentEntity, InitiatePaymentParams> {
  final PaymentRepository repository;

  InitiatePaymentUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentEntity>> call(InitiatePaymentParams params) async {
    return await repository.initiatePayment(params.bookingId, params.method);
  }
}

class InitiatePaymentParams {
  final String bookingId;
  final String method;

  InitiatePaymentParams({required this.bookingId, required this.method});
}
