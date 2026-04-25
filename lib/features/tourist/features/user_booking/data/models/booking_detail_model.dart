import '../../domain/entities/booking_detail_entity.dart';
import 'helper_booking_model.dart';

class BookingDetailModel extends BookingDetailEntity {
  const BookingDetailModel({
    required super.id,
    required super.status,
    required super.type,
    required super.requestedDate,
    super.startTime,
    required super.durationInMinutes,
    required super.destinationCity,
    super.pickupLocationName,
    super.pickupLatitude,
    super.pickupLongitude,
    super.destinationLatitude,
    super.destinationLongitude,
    super.helper,
    required super.totalPrice,
    required super.currency,
    super.notes,
    required super.chatEnabled,
    required super.timeline,
    super.paymentStatus,
    super.priceBreakdown,
  });

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailModel(
      id: json['id']?.toString() ?? '',
      status: _parseStatus(json['status']),
      type: _parseType(json['type']),
      requestedDate: DateTime.parse(json['requestedDate']),
      startTime: json['startTime'],
      durationInMinutes: json['durationInMinutes'] ?? 0,
      destinationCity: json['destinationCity'] ?? '',
      pickupLocationName: json['pickupLocationName'],
      pickupLatitude: (json['pickupLatitude'] ?? 0.0).toDouble(),
      pickupLongitude: (json['pickupLongitude'] ?? 0.0).toDouble(),
      destinationLatitude: json['destinationLatitude'] != null ? (json['destinationLatitude'] as num).toDouble() : null,
      destinationLongitude: json['destinationLongitude'] != null ? (json['destinationLongitude'] as num).toDouble() : null,
      helper: json['helper'] != null ? HelperBookingModel.fromJson(json['helper']) : null,
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      notes: json['notes'],
      chatEnabled: json['chatEnabled'] ?? false,
      timeline: (json['timeline'] as List? ?? [])
          .map((e) => BookingTimelineStepModel.fromJson(e))
          .toList(),
      paymentStatus: json['paymentStatus'],
      priceBreakdown: json['priceBreakdown'] != null
          ? PriceBreakdownModel.fromJson(json['priceBreakdown'])
          : null,
    );
  }

  static BookingStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return BookingStatus.pending;
      case 'confirmed': return BookingStatus.confirmed;
      case 'inprogress': return BookingStatus.inProgress;
      case 'completed': return BookingStatus.completed;
      case 'cancelled': return BookingStatus.cancelled;
      case 'expired': return BookingStatus.expired;
      case 'declined': return BookingStatus.declined;
      case 'confirmedawaitingpayment': return BookingStatus.confirmedAwaitingPayment;
      default: return BookingStatus.pending;
    }
  }

  static BookingType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'scheduled': return BookingType.scheduled;
      case 'instant': return BookingType.instant;
      default: return BookingType.scheduled;
    }
  }
}

class BookingTimelineStepModel extends BookingTimelineStep {
  const BookingTimelineStepModel({
    required super.status,
    required super.timestamp,
    super.description,
  });

  factory BookingTimelineStepModel.fromJson(Map<String, dynamic> json) {
    return BookingTimelineStepModel(
      status: BookingDetailModel._parseStatus(json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
    );
  }
}

class PriceBreakdownModel extends PriceBreakdownEntity {
  const PriceBreakdownModel({
    required super.basePrice,
    required super.durationPrice,
    required super.carSurcharge,
    required super.serviceFee,
    required super.total,
  });

  factory PriceBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PriceBreakdownModel(
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      durationPrice: (json['durationPrice'] ?? 0.0).toDouble(),
      carSurcharge: (json['carSurcharge'] ?? 0.0).toDouble(),
      serviceFee: (json['serviceFee'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
    );
  }
}
