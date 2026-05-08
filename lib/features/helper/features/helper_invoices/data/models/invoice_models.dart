import '../../domain/entities/invoice_entities.dart';

// ──────────────────────────────────────────────────────────────────────────────
// InvoiceModel
// ──────────────────────────────────────────────────────────────────────────────
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
    super.issuedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> j) => InvoiceModel(
        invoiceId: j['invoiceId']?.toString() ?? '',
        invoiceNumber: j['invoiceNumber']?.toString() ?? '',
        bookingId: j['bookingId']?.toString() ?? '',
        userName: j['userName'] ?? '',
        helperName: j['helperName'] ?? '',
        destinationCity: j['destinationCity'] ?? '',
        totalAmount: _parseDouble(j['totalAmount']),
        currency: j['currency'] ?? 'EGP',
        status: j['status'] ?? 'unknown',
        paymentStatus: j['paymentStatus'] ?? 'unknown',
        paymentMethod: j['paymentMethod'] ?? '',
        issuedAt: _parseDate(j['issuedAt']),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// InvoiceDetailModel
// ──────────────────────────────────────────────────────────────────────────────
class InvoiceDetailModel extends InvoiceDetailEntity {
  const InvoiceDetailModel({
    required super.invoiceId,
    required super.invoiceNumber,
    required super.bookingId,
    required super.userName,
    required super.helperName,
    required super.destinationCity,
    super.tripStartTime,
    super.tripEndTime,
    super.durationMinutes,
    required super.basePrice,
    required super.distanceCost,
    required super.durationCost,
    required super.surchargeAmount,
    required super.subtotal,
    required super.commissionAmount,
    required super.commissionRate,
    required super.netAmount,
    required super.totalAmount,
    required super.currency,
    required super.status,
    required super.paymentStatus,
    required super.paymentMethod,
    super.issuedAt,
    super.paidAt,
    super.notes,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> j) => InvoiceDetailModel(
        invoiceId: j['invoiceId']?.toString() ?? '',
        invoiceNumber: j['invoiceNumber']?.toString() ?? '',
        bookingId: j['bookingId']?.toString() ?? '',
        userName: j['userName'] ?? '',
        helperName: j['helperName'] ?? '',
        destinationCity: j['destinationCity'] ?? '',
        tripStartTime: _parseDate(j['tripStartTime']),
        tripEndTime: _parseDate(j['tripEndTime']),
        durationMinutes: j['durationMinutes'] as int?,
        basePrice: _parseDouble(j['basePrice']),
        distanceCost: _parseDouble(j['distanceCost']),
        durationCost: _parseDouble(j['durationCost']),
        surchargeAmount: _parseDouble(j['surchargeAmount']),
        subtotal: _parseDouble(j['subtotal']),
        commissionAmount: _parseDouble(j['commissionAmount']),
        commissionRate: _parseDouble(j['commissionRate']),
        netAmount: _parseDouble(j['netAmount']),
        totalAmount: _parseDouble(j['totalAmount']),
        currency: j['currency'] ?? 'EGP',
        status: j['status'] ?? 'unknown',
        paymentStatus: j['paymentStatus'] ?? 'unknown',
        paymentMethod: j['paymentMethod'] ?? '',
        issuedAt: _parseDate(j['issuedAt']),
        paidAt: _parseDate(j['paidAt']),
        notes: j['notes'] as String?,
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// InvoiceSummaryModel
// ──────────────────────────────────────────────────────────────────────────────
class InvoiceSummaryModel extends InvoiceSummaryEntity {
  const InvoiceSummaryModel({
    required super.grossAmount,
    required super.commissionAmount,
    required super.netAmount,
    required super.invoiceCount,
    required super.currency,
  });

  factory InvoiceSummaryModel.fromJson(Map<String, dynamic> j) => InvoiceSummaryModel(
        grossAmount: _parseDouble(j['grossAmount']),
        commissionAmount: _parseDouble(j['commissionAmount']),
        netAmount: _parseDouble(j['netAmount']),
        invoiceCount: (j['invoiceCount'] as num?)?.toInt() ?? 0,
        currency: j['currency'] ?? 'EGP',
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────
double _parseDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
