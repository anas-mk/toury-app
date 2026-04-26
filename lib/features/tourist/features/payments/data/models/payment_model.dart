import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.paymentId,
    required super.bookingId,
    required super.amount,
    required super.currency,
    required super.method,
    required super.status,
    super.paymentUrl,
    super.phase,
    super.initiatedAt,
    super.completedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      paymentId: json['paymentId'] ?? '',
      bookingId: json['bookingId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'EGP',
      method: json['method'] ?? 'Unknown',
      status: _parseStatus(json['status']),
      paymentUrl: json['paymentUrl'],
      phase: _parsePhase(json['phase']),
      initiatedAt: json['initiatedAt'] != null ? DateTime.parse(json['initiatedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  static PaymentStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'notrequired':
        return PaymentStatus.notRequired;
      case 'awaitingpayment':
        return PaymentStatus.awaitingPayment;
      case 'paymentpending':
      case 'pending':
        return PaymentStatus.paymentPending;
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.paymentPending;
    }
  }

  static PaymentPhase? _parsePhase(String? value) {
    switch (value?.toLowerCase()) {
      case 'full':
        return PaymentPhase.full;
      case 'deposit':
        return PaymentPhase.deposit;
      case 'remaining':
        return PaymentPhase.remaining;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'bookingId': bookingId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'status': status.name,
      'paymentUrl': paymentUrl,
      'phase': phase?.name,
      'initiatedAt': initiatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
