import 'package:equatable/equatable.dart';

class InvoiceEntity extends Equatable {
  final String invoiceId;
  final String invoiceNumber;
  final String bookingId;
  final String userName;
  final String helperName;
  final String destinationCity;
  final double totalAmount;
  final String currency;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime? issuedAt;

  const InvoiceEntity({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.bookingId,
    required this.userName,
    required this.helperName,
    required this.destinationCity,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.issuedAt,
  });

  @override
  List<Object?> get props => [
        invoiceId, invoiceNumber, bookingId, userName, helperName,
        destinationCity, totalAmount, currency, status, paymentStatus,
        paymentMethod, issuedAt,
      ];
}

class InvoiceDetailEntity extends Equatable {
  final String invoiceId;
  final String invoiceNumber;
  final String bookingId;
  final String userName;
  final String helperName;
  final String destinationCity;
  final DateTime? tripStartTime;
  final DateTime? tripEndTime;
  final int? durationMinutes;
  final double basePrice;
  final double distanceCost;
  final double durationCost;
  final double surchargeAmount;
  final double subtotal;
  final double commissionAmount;
  final double commissionRate;
  final double netAmount;
  final double totalAmount;
  final String currency;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime? issuedAt;
  final DateTime? paidAt;
  final String? notes;

  const InvoiceDetailEntity({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.bookingId,
    required this.userName,
    required this.helperName,
    required this.destinationCity,
    this.tripStartTime,
    this.tripEndTime,
    this.durationMinutes,
    required this.basePrice,
    required this.distanceCost,
    required this.durationCost,
    required this.surchargeAmount,
    required this.subtotal,
    required this.commissionAmount,
    required this.commissionRate,
    required this.netAmount,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.issuedAt,
    this.paidAt,
    this.notes,
  });

  @override
  List<Object?> get props => [invoiceId, invoiceNumber, netAmount, paymentStatus];
}

class InvoiceSummaryEntity extends Equatable {
  final double grossAmount;
  final double commissionAmount;
  final double netAmount;
  final int invoiceCount;
  final String currency;

  const InvoiceSummaryEntity({
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    required this.invoiceCount,
    required this.currency,
  });

  @override
  List<Object?> get props => [grossAmount, commissionAmount, netAmount, invoiceCount, currency];
}
