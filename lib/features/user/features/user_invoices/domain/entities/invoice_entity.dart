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
  final DateTime issuedAt;

  // Detail-only breakdown fields (null for list-level entities)
  final double? basePrice;
  final double? tripDistanceKm;
  final int? durationInMinutes;
  final double? distanceCost;
  final double? durationCost;
  final double? instantSurchargeAmount;
  final double? subtotal;

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
    required this.issuedAt,
    this.basePrice,
    this.tripDistanceKm,
    this.durationInMinutes,
    this.distanceCost,
    this.durationCost,
    this.instantSurchargeAmount,
    this.subtotal,
  });

  @override
  List<Object?> get props => [
        invoiceId,
        invoiceNumber,
        bookingId,
        userName,
        helperName,
        destinationCity,
        totalAmount,
        currency,
        status,
        paymentStatus,
        paymentMethod,
        issuedAt,
        basePrice,
        tripDistanceKm,
        durationInMinutes,
        distanceCost,
        durationCost,
        instantSurchargeAmount,
        subtotal,
      ];
}
