import '../../domain/entities/invoice_entity.dart';

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.invoiceId,
    required super.invoiceNumber,
    required super.bookingId,
    required super.userName,
    required super.helperName,
    required super.destinationCity,
    required super.totalAmount,
    required super.currency,
    required super.status,
    required super.paymentStatus,
    required super.paymentMethod,
    required super.issuedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId: json['invoiceId']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      bookingId: json['bookingId']?.toString() ?? '',
      userName: json['userName'] ?? '',
      helperName: json['helperName'] ?? '',
      destinationCity: json['destinationCity'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'EGP',
      status: json['status'] ?? 'Issued',
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      paymentMethod: json['paymentMethod'] ?? 'Unknown',
      issuedAt: DateTime.parse(json['issuedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'bookingId': bookingId,
      'userName': userName,
      'helperName': helperName,
      'destinationCity': destinationCity,
      'totalAmount': totalAmount,
      'currency': currency,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'issuedAt': issuedAt.toIso8601String(),
    };
  }
}
