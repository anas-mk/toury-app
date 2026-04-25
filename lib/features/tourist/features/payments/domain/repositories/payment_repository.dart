import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<Either<Failure, PaymentEntity>> initiatePayment(String bookingId, String method);
  Future<Either<Failure, PaymentEntity>> getPayment(String paymentId);
  Future<Either<Failure, PaymentEntity>> getLatestPayment(String bookingId);
  Future<Either<Failure, void>> mockPaymentComplete(String paymentId, String action);
}
