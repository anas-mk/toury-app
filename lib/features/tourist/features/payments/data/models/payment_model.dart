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
    Map<String, dynamic> m = json;
    final inner = m['data'];
    if (inner is Map<String, dynamic>) m = inner;

    dynamic p(String camel, String pascal) => m[camel] ?? m[pascal];

    String ps(String camel, String pascal) =>
        p(camel, pascal)?.toString() ?? '';

    double amount(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    DateTime? ts(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return PaymentModel(
      paymentId: ps('paymentId', 'PaymentId'),
      bookingId: ps('bookingId', 'BookingId'),
      amount: amount(p('amount', 'Amount')),
      currency: ps('currency', 'Currency').isEmpty ? 'EGP' : ps('currency', 'Currency'),
      method: ps('method', 'Method').isEmpty ? 'Unknown' : ps('method', 'Method'),
      status: _parseStatus(p('status', 'Status')?.toString()),
      paymentUrl: p('paymentUrl', 'PaymentUrl')?.toString(),
      phase: _parsePhase(p('phase', 'Phase')?.toString()),
      initiatedAt: ts(p('initiatedAt', 'InitiatedAt')),
      completedAt: ts(p('completedAt', 'CompletedAt')),
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
      case 'cancelled':
      case 'canceled':
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
