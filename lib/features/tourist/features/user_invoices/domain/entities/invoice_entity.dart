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
      ];
}
