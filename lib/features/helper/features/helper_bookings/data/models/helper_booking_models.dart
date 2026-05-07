import 'package:flutter/cupertino.dart';

import '../../domain/entities/helper_booking_entities.dart';

class HelperBookingModel extends HelperBooking {
  const HelperBookingModel({
    required super.id,
    required super.bookingType,
    super.isUrgent,
    required super.travelerName,
    super.travelerCountry,
    super.travelerImage,
    required super.destinationCity,
    required super.pickupLocation,
    required super.destinationLocation,
    required super.pickupLat,
    required super.pickupLng,
    required super.destinationLat,
    required super.destinationLng,
    required super.startTime,
    super.endTime,
    super.durationInMinutes,
    super.requiresCar,
    super.travelersCount,
    super.meetingPointType,
    required super.payout,
    required super.status,
    super.language,
    super.notes,
    super.attemptOrder,
    super.attemptStatus,
    super.sentAt,
    required super.responseDeadline,
    super.isExpired,
    required super.isInstant,
    required super.createdAt,
    super.canStartTrip = false,
    super.canEndTrip = false,
  });

  factory HelperBookingModel.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 [HelperBookingModel] Parsing JSON keys: ${json.keys.toList()}');
    final bookingId = json['bookingId']?.toString() ?? json['id']?.toString() ?? '';
    final bookingType = json['bookingType']?.toString() ?? (json['isInstant'] == true ? 'Instant' : 'Scheduled');
    final isUrgent = json['isUrgent'] ?? false;
    final travelerName = json['travelerName'] ?? 'Traveler';
    final travelerCountry = json['travelerCountry'];
    final travelerImage = json['travelerProfileImage'] ?? json['travelerImage'];
    final destinationCity = json['destinationCity'] ?? '';
    final pickupLocation = json['pickupLocationName'] ?? json['pickupLocation'] ?? '';
    final destinationLocation = json['destinationName'] ?? json['destinationLocation'] ?? '';
    final pickupLat = (json['pickupLatitude'] ?? json['pickupLat'] as num?)?.toDouble() ?? 0.0;
    final pickupLng = (json['pickupLongitude'] ?? json['pickupLng'] as num?)?.toDouble() ?? 0.0;
    final destinationLat = (json['destinationLatitude'] ?? json['destinationLat'] as num?)?.toDouble() ?? 0.0;
    final destinationLng = (json['destinationLongitude'] ?? json['destinationLng'] as num?)?.toDouble() ?? 0.0;
    
    // Parse dates with fallback
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value == null) return fallback;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return fallback;
      }
    }
    
    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }
    
    final now = DateTime.now();
    final startTime = parseDate(json['requestedDate'] ?? json['startTime'], now);
    final endTime = parseNullableDate(json['endTime']);
    final durationInMinutes = (json['durationInMinutes'] as num?)?.toInt() ?? 0;
    final requiresCar = json['requiresCar'] ?? false;
    final travelersCount = (json['travelersCount'] as num?)?.toInt() ?? 1;
    final meetingPointType = json['meetingPointType'];
    final payout = (json['estimatedPayout'] ?? json['payout'] as num?)?.toDouble() ?? 0.0;
    final status = json['status'] ?? json['attemptStatus'] ?? 'pending';
    final language = json['requestedLanguage'] ?? json['language'];
    final notes = json['notes'];
    final attemptOrder = (json['attemptOrder'] as num?)?.toInt() ?? 0;
    final attemptStatus = json['attemptStatus'];
    final sentAt = parseNullableDate(json['sentAt']);
    final responseDeadline = parseDate(json['responseDeadline'], now.add(const Duration(hours: 1)));
    final isExpired = json['isExpired'] ?? false;
    final isInstant = json['isInstant'] ?? bookingType.toLowerCase() == 'instant';
    final createdAt = parseDate(json['createdAt'], now);
    final canStartTrip = json['canStartTrip'] ?? false;
    final canEndTrip = json['canEndTrip'] ?? false;

    return HelperBookingModel(
      id: bookingId,
      bookingType: bookingType,
      isUrgent: isUrgent,
      travelerName: travelerName,
      travelerCountry: travelerCountry,
      travelerImage: travelerImage,
      destinationCity: destinationCity,
      pickupLocation: pickupLocation,
      destinationLocation: destinationLocation,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      startTime: startTime,
      endTime: endTime,
      durationInMinutes: durationInMinutes,
      requiresCar: requiresCar,
      travelersCount: travelersCount,
      meetingPointType: meetingPointType,
      payout: payout,
      status: status,
      language: language,
      notes: notes,
      attemptOrder: attemptOrder,
      attemptStatus: attemptStatus,
      sentAt: sentAt,
      responseDeadline: responseDeadline,
      isExpired: isExpired,
      isInstant: isInstant,
      createdAt: createdAt,
      canStartTrip: canStartTrip,
      canEndTrip: canEndTrip,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': id,
      'bookingType': bookingType,
      'isUrgent': isUrgent,
      'travelerName': travelerName,
      'travelerCountry': travelerCountry,
      'travelerProfileImage': travelerImage,
      'destinationCity': destinationCity,
      'pickupLocationName': pickupLocation,
      'destinationName': destinationLocation,
      'pickupLatitude': pickupLat,
      'pickupLongitude': pickupLng,
      'destinationLatitude': destinationLat,
      'destinationLongitude': destinationLng,
      'requestedDate': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationInMinutes': durationInMinutes,
      'requiresCar': requiresCar,
      'travelersCount': travelersCount,
      'meetingPointType': meetingPointType,
      'estimatedPayout': payout,
      'status': status,
      'requestedLanguage': language,
      'notes': notes,
      'attemptOrder': attemptOrder,
      'attemptStatus': attemptStatus,
      'sentAt': sentAt?.toIso8601String(),
      'responseDeadline': responseDeadline.toIso8601String(),
      'isExpired': isExpired,
      'isInstant': isInstant,
      'createdAt': createdAt.toIso8601String(),
      'canStartTrip': canStartTrip,
      'canEndTrip': canEndTrip,
    };
  }
}

/// Paginated response wrapper for incoming requests
class PaginatedRequestsResponse {
  final List<HelperBookingModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedRequestsResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedRequestsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final itemsList = data['items'] as List? ?? [];
    
    return PaginatedRequestsResponse(
      items: itemsList
          .map((e) => HelperBookingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (data['page'] as num?)?.toInt() ?? 1,
      pageSize: (data['pageSize'] as num?)?.toInt() ?? 10,
      totalCount: (data['totalCount'] as num?)?.toInt() ?? 0,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
      hasNextPage: data['hasNextPage'] ?? false,
      hasPreviousPage: data['hasPreviousPage'] ?? false,
    );
  }
}

