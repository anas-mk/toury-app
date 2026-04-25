import 'package:equatable/equatable.dart';
import 'helper_booking_entity.dart';

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  expired,
  declined,
}

enum BookingType {
  scheduled,
  instant,
}

class BookingDetailEntity extends Equatable {
  final String id;
  final BookingStatus status;
  final BookingType type;
  final DateTime requestedDate;
  final String? startTime;
  final int durationInMinutes;
  final String destinationCity;
  final String? pickupLocationName;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final HelperBookingEntity? helper;
  final double totalPrice;
  final String currency;
  final String? notes;
  final bool chatEnabled;
  final List<BookingTimelineStep> timeline;
  final PriceBreakdownEntity? priceBreakdown;

  const BookingDetailEntity({
    required this.id,
    required this.status,
    required this.type,
    required this.requestedDate,
    this.startTime,
    required this.durationInMinutes,
    required this.destinationCity,
    this.pickupLocationName,
    this.pickupLatitude,
    this.pickupLongitude,
    this.helper,
    required this.totalPrice,
    required this.currency,
    this.notes,
    required this.chatEnabled,
    required this.timeline,
    this.priceBreakdown,
  });

  @override
  List<Object?> get props => [
        id,
        status,
        type,
        requestedDate,
        startTime,
        durationInMinutes,
        destinationCity,
        pickupLocationName,
        pickupLatitude,
        pickupLongitude,
        helper,
        totalPrice,
        currency,
        notes,
        chatEnabled,
        timeline,
        priceBreakdown,
      ];
}

class BookingTimelineStep extends Equatable {
  final BookingStatus status;
  final DateTime timestamp;
  final String? description;

  const BookingTimelineStep({
    required this.status,
    required this.timestamp,
    this.description,
  });

  @override
  List<Object?> get props => [status, timestamp, description];
}

class PriceBreakdownEntity extends Equatable {
  final double basePrice;
  final double durationPrice;
  final double carSurcharge;
  final double serviceFee;
  final double total;

  const PriceBreakdownEntity({
    required this.basePrice,
    required this.durationPrice,
    required this.carSurcharge,
    required this.serviceFee,
    required this.total,
  });

  @override
  List<Object?> get props => [basePrice, durationPrice, carSurcharge, serviceFee, total];
}
