import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../repositories/payment_repository.dart';

class MockPaymentCompleteUseCase implements UseCase<void, MockPaymentCompleteParams> {
  final PaymentRepository repository;

  MockPaymentCompleteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MockPaymentCompleteParams params) async {
    return await repository.mockPaymentComplete(params.paymentId, params.action);
  }
}

class MockPaymentCompleteParams {
  final String paymentId;
  final String action;

  MockPaymentCompleteParams({required this.paymentId, required this.action});
}
