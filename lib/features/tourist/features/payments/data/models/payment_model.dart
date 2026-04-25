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
      status: json['status'] ?? 'Pending',
      paymentUrl: json['paymentUrl'],
      initiatedAt: json['initiatedAt'] != null ? DateTime.parse(json['initiatedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'bookingId': bookingId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'status': status,
      'paymentUrl': paymentUrl,
      'initiatedAt': initiatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
