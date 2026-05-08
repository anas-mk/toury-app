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
    super.basePrice,
    super.tripDistanceKm,
    super.durationInMinutes,
    super.distanceCost,
    super.durationCost,
    super.instantSurchargeAmount,
    super.subtotal,
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
      paymentMethod: json['paymentMethod'] ?? '',
      issuedAt: DateTime.tryParse(json['issuedAt']?.toString() ?? '') ??
          DateTime.now(),
      // Breakdown fields — only present in the detail endpoint
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      tripDistanceKm: (json['tripDistanceKm'] as num?)?.toDouble(),
      durationInMinutes: json['durationInMinutes'] as int?,
      distanceCost: (json['distanceCost'] as num?)?.toDouble(),
      durationCost: (json['durationCost'] as num?)?.toDouble(),
      instantSurchargeAmount:
          (json['instantSurchargeAmount'] as num?)?.toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
    );
  }
}
