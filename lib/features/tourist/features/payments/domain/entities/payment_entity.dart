import 'package:equatable/equatable.dart';

enum PaymentStatus {
  notRequired,
  awaitingPayment,
  paymentPending,
  paid,
  refunded,
  failed,
}

enum PaymentPhase {
  full,
  deposit,
  remaining,
}

class PaymentEntity extends Equatable {
  final String paymentId;
  final String bookingId;
  final double amount;
  final String currency;
  final String method;
  final PaymentStatus status;
  final String? paymentUrl;
  final PaymentPhase? phase;
  final DateTime? initiatedAt;
  final DateTime? completedAt;

  const PaymentEntity({
    required this.paymentId,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    this.paymentUrl,
    this.phase,
    this.initiatedAt,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
        paymentId,
        bookingId,
        amount,
        currency,
        method,
        status,
        paymentUrl,
        phase,
        initiatedAt,
        completedAt,
      ];
}
