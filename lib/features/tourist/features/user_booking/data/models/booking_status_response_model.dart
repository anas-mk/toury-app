import '../../domain/entities/booking_status.dart';
import '../../domain/entities/booking_status_response.dart';
import 'json_helpers.dart';

class BookingStatusResponseModel extends BookingStatusResponse {
  const BookingStatusResponseModel({
    required super.bookingId,
    required super.status,
    required super.rawStatus,
    super.currentHelperId,
    super.currentHelperName,
    super.responseDeadline,
    required super.isInReassignment,
    required super.assignmentAttemptCount,
    required super.paymentRequired,
    required super.paymentStatus,
    required super.chatEnabled,
  });

  factory BookingStatusResponseModel.fromJson(Map<String, dynamic> json) {
    final raw = json['status']?.toString() ?? 'Unknown';
    return BookingStatusResponseModel(
      bookingId: json['bookingId']?.toString() ?? '',
      status: BookingStatus.parse(raw),
      rawStatus: raw,
      currentHelperId: json['currentHelperId']?.toString(),
      currentHelperName: json['currentHelperName']?.toString(),
      responseDeadline: tryParseUtc(json['responseDeadline']),
      isInReassignment: parseBool(json['isInReassignment']),
      assignmentAttemptCount: parseInt(json['assignmentAttemptCount']),
      paymentRequired: parseBool(json['paymentRequired']),
      paymentStatus: PaymentStatusWire.parse(json['paymentStatus']?.toString()),
      chatEnabled: parseBool(json['chatEnabled']),
    );
  }
}
