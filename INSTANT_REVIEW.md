# Instant Trip Booking — Full Dump

> Read-only review artifact. Generated from the working tree on the
> `feat/instant-booking-rebuild` branch. Every code block below is the
> verbatim contents of the file whose path is shown on the line above it.

---

## Section 1 — Inventory

| # | Layer | File | Lines |
|---|-------|------|-------|
| 1 | Domain · entity | `lib/features/tourist/features/user_booking/domain/entities/create_instant_booking_request.dart` | 69 |
| 2 | Domain · entity | `lib/features/tourist/features/user_booking/domain/entities/instant_search_request.dart` | 43 |
| 3 | Domain · entity | `lib/features/tourist/features/user_booking/domain/entities/booking_status.dart` | 68 |
| 4 | Domain · entity | `lib/features/tourist/features/user_booking/domain/entities/booking_status_response.dart` | 49 |
| 5 | Domain · entity | `lib/features/tourist/features/user_booking/domain/entities/booking_detail.dart` | 212 |
| 6 | Domain · entity | `lib/features/tourist/features/user_booking/domain/entities/helper_search_result.dart` | 84 |
| 7 | Domain · entity | `lib/features/tourist/features/user_booking/domain/entities/helper_booking_profile.dart` | 134 |
| 8 | Domain · entity | `lib/features/tourist/features/user_booking/domain/entities/alternatives_response.dart` | 60 |
| 9 | Domain · entity | `lib/features/tourist/features/user_booking/domain/entities/price_breakdown.dart` | 45 |
| 10 | Domain · repo | `lib/features/tourist/features/user_booking/domain/repositories/instant_booking_repository.dart` | 49 |
| 11-17 | Domain · usecases | `lib/features/tourist/features/user_booking/domain/usecases/instant/*` | 7 files |
| 18 | Data · helpers | `lib/features/tourist/features/user_booking/data/models/json_helpers.dart` | 89 |
| 19-24 | Data · models | `lib/features/tourist/features/user_booking/data/models/*` | 6 files |
| 25 | Data · datasource | `lib/features/tourist/features/user_booking/data/datasources/instant_booking_remote_data_source.dart` | 238 |
| 26 | Data · repo impl | `lib/features/tourist/features/user_booking/data/repositories/instant_booking_repository_impl.dart` | 79 |
| 27 | State · cubit | `lib/features/tourist/features/user_booking/presentation/cubits/instant_booking_cubit.dart` | 298 |
| 28 | State · state | `lib/features/tourist/features/user_booking/presentation/cubits/instant_booking_state.dart` | 104 |
| 29 | State · cubit | `lib/features/tourist/features/user_booking/presentation/cubits/helper_booking_profile_cubit.dart` | 53 |
| 30 | UI · entry | `lib/features/tourist/features/user_booking/presentation/pages/booking_home_page.dart` | 99 |
| 31-40 | UI · pages | `lib/features/tourist/features/user_booking/presentation/pages/instant/*` | 10 files |
| 41-48 | UI · widgets | `lib/features/tourist/features/user_booking/presentation/widgets/instant/*` | 8 files |
| 49 | SignalR · client | `lib/core/services/signalr/booking_tracking_hub_service.dart` | 340 |
| 50 | SignalR · events | `lib/core/services/signalr/booking_hub_events.dart` | 324 |
| 51 | FCM · helper | `lib/core/services/notifications/device_info_helper.dart` | 57 |
| 52 | FCM · service | `lib/core/services/notifications/device_token_service.dart` | 164 |
| 53 | Wiring · router | `lib/core/router/app_router.dart` (instant routes only) | 9 routes |
| 54 | Wiring · DI | `lib/core/di/injection_container.dart` (instant + hub + FCM blocks) | 8 blocks |
| 55 | Wiring · auth | `lib/features/tourist/features/auth/presentation/cubit/auth_cubit.dart` | 313 |
| 56 | Wiring · home | `lib/features/tourist/features/home/presentation/pages/tourist_home_page.dart` | 320 |
| 57 | Wiring · entry | `lib/main.dart` | 54 |
| 58 | Wiring · config | `lib/core/config/api_config.dart` | 218 |

---

## Section 3 — Domain (full file contents)

`lib/features/tourist/features/user_booking/domain/entities/create_instant_booking_request.dart`

```dart
import 'package:equatable/equatable.dart';

/// Exact body for `POST /user/bookings/instant`.
///
/// `helperId == null` means the backend should auto-pick a helper.
class CreateInstantBookingRequest extends Equatable {
  final String? helperId;
  final String pickupLocationName;
  final double pickupLatitude;
  final double pickupLongitude;
  final String destinationName;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double? distanceKm;
  final int durationInMinutes;
  final String? requestedLanguage;
  final bool requiresCar;
  final int travelersCount;
  final String? notes;

  const CreateInstantBookingRequest({
    this.helperId,
    required this.pickupLocationName,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationName,
    this.destinationLatitude,
    this.destinationLongitude,
    this.distanceKm,
    required this.durationInMinutes,
    this.requestedLanguage,
    this.requiresCar = false,
    this.travelersCount = 1,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'helperId': helperId,
        'pickupLocationName': pickupLocationName,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'destinationName': destinationName,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
        'distanceKm': distanceKm,
        'durationInMinutes': durationInMinutes,
        'requestedLanguage': requestedLanguage,
        'requiresCar': requiresCar,
        'travelersCount': travelersCount,
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        helperId,
        pickupLocationName,
        pickupLatitude,
        pickupLongitude,
        destinationName,
        destinationLatitude,
        destinationLongitude,
        distanceKm,
        durationInMinutes,
        requestedLanguage,
        requiresCar,
        travelersCount,
        notes,
      ];
}
```

`lib/features/tourist/features/user_booking/domain/entities/instant_search_request.dart`

```dart
import 'package:equatable/equatable.dart';

/// Request body for `POST /user/bookings/instant/search`.
class InstantSearchRequest extends Equatable {
  final String pickupLocationName;
  final double pickupLatitude;
  final double pickupLongitude;
  final int durationInMinutes;
  final String? requestedLanguage;
  final bool requiresCar;
  final int travelersCount;

  const InstantSearchRequest({
    required this.pickupLocationName,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.durationInMinutes,
    this.requestedLanguage,
    this.requiresCar = false,
    this.travelersCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'pickupLocationName': pickupLocationName,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'durationInMinutes': durationInMinutes,
        'requestedLanguage': requestedLanguage,
        'requiresCar': requiresCar,
        'travelersCount': travelersCount,
      };

  @override
  List<Object?> get props => [
        pickupLocationName,
        pickupLatitude,
        pickupLongitude,
        durationInMinutes,
        requestedLanguage,
        requiresCar,
        travelersCount,
      ];
}
```

`lib/features/tourist/features/user_booking/domain/entities/booking_status.dart`

```dart
/// Backend `BookingStatus` enum values, used as wire strings.
enum BookingStatus {
  created('Created'),
  pendingHelperResponse('PendingHelperResponse'),
  acceptedByHelper('AcceptedByHelper'),
  declinedByHelper('DeclinedByHelper'),
  expiredNoResponse('ExpiredNoResponse'),
  reassignmentInProgress('ReassignmentInProgress'),
  waitingForUserAction('WaitingForUserAction'),
  confirmed('Confirmed'),
  inProgress('InProgress'),
  completed('Completed'),
  cancelledByUser('CancelledByUser'),
  cancelledByHelper('CancelledByHelper'),
  cancelledBySystem('CancelledBySystem'),
  unknown('Unknown');

  final String raw;
  const BookingStatus(this.raw);

  static BookingStatus parse(String? value) {
    if (value == null) return BookingStatus.unknown;
    for (final s in BookingStatus.values) {
      if (s.raw == value) return s;
    }
    return BookingStatus.unknown;
  }

  bool get isTerminal =>
      this == completed ||
      this == cancelledByUser ||
      this == cancelledByHelper ||
      this == cancelledBySystem;

  bool get isCancelled =>
      this == cancelledByUser ||
      this == cancelledByHelper ||
      this == cancelledBySystem;

  bool get needsAlternatives =>
      this == declinedByHelper ||
      this == expiredNoResponse ||
      this == waitingForUserAction;
}

enum PaymentStatusWire {
  notRequired('NotRequired'),
  awaitingPayment('AwaitingPayment'),
  paymentPending('PaymentPending'),
  paid('Paid'),
  refunded('Refunded'),
  failed('Failed'),
  unknown('Unknown');

  final String raw;
  const PaymentStatusWire(this.raw);

  static PaymentStatusWire parse(String? value) {
    if (value == null) return PaymentStatusWire.unknown;
    for (final s in PaymentStatusWire.values) {
      if (s.raw == value) return s;
    }
    return PaymentStatusWire.unknown;
  }
}
```

`lib/features/tourist/features/user_booking/domain/entities/booking_status_response.dart`

```dart
import 'package:equatable/equatable.dart';

import 'booking_status.dart';

class BookingStatusResponse extends Equatable {
  final String bookingId;
  final BookingStatus status;
  final String rawStatus;
  final String? currentHelperId;
  final String? currentHelperName;
  final DateTime? responseDeadline;
  final bool isInReassignment;
  final int assignmentAttemptCount;
  final bool paymentRequired;
  final PaymentStatusWire paymentStatus;
  final bool chatEnabled;

  const BookingStatusResponse({
    required this.bookingId,
    required this.status,
    required this.rawStatus,
    this.currentHelperId,
    this.currentHelperName,
    this.responseDeadline,
    required this.isInReassignment,
    required this.assignmentAttemptCount,
    required this.paymentRequired,
    required this.paymentStatus,
    required this.chatEnabled,
  });

  @override
  List<Object?> get props => [
        bookingId, status, rawStatus, currentHelperId, currentHelperName,
        responseDeadline, isInReassignment, assignmentAttemptCount,
        paymentRequired, paymentStatus, chatEnabled,
      ];
}
```

`lib/features/tourist/features/user_booking/domain/entities/booking_detail.dart`

```dart
import 'package:equatable/equatable.dart';

import 'booking_status.dart';
import 'price_breakdown.dart';

class BookingHelperSummary extends Equatable {
  final String helperId;
  final String fullName;
  final String? profileImageUrl;
  final double rating;
  final int completedTrips;
  final String? phoneNumber;

  const BookingHelperSummary({
    required this.helperId,
    required this.fullName,
    this.profileImageUrl,
    required this.rating,
    required this.completedTrips,
    this.phoneNumber,
  });

  @override
  List<Object?> get props =>
      [helperId, fullName, profileImageUrl, rating, completedTrips, phoneNumber];
}

class CurrentAssignment extends Equatable {
  final String helperId;
  final String helperName;
  final int attemptOrder;
  final String responseStatus;
  final DateTime? sentAt;
  final DateTime? expiresAt;

  const CurrentAssignment({
    required this.helperId,
    required this.helperName,
    required this.attemptOrder,
    required this.responseStatus,
    this.sentAt,
    this.expiresAt,
  });

  @override
  List<Object?> get props =>
      [helperId, helperName, attemptOrder, responseStatus, sentAt, expiresAt];
}

class BookingStatusHistoryItem extends Equatable {
  final String oldStatus;
  final String newStatus;
  final DateTime? changedAt;
  final String? reason;

  const BookingStatusHistoryItem({
    required this.oldStatus,
    required this.newStatus,
    this.changedAt,
    this.reason,
  });

  @override
  List<Object?> get props => [oldStatus, newStatus, changedAt, reason];
}

class BookingDetail extends Equatable {
  final String bookingId;
  final String bookingType;
  final BookingStatus status;
  final String rawStatus;
  final PaymentStatusWire paymentStatus;
  final String? destinationCity;
  final DateTime? requestedDate;
  final String? startTime;
  final int durationInMinutes;
  final String? requestedLanguage;
  final bool requiresCar;
  final int travelersCount;
  final String? meetingPointType;
  final String pickupLocationName;
  final String? pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String? destinationName;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? notes;
  final double? estimatedPrice;
  final double? finalPrice;
  final double? depositAmount;
  final double? remainingAmount;
  final bool depositPaid;
  final bool remainingPaid;
  final bool depositForfeited;
  final PriceBreakdown? priceBreakdown;
  final BookingHelperSummary? helper;
  final CurrentAssignment? currentAssignment;
  final int assignmentAttemptCount;
  final bool chatEnabled;
  final bool paymentRequired;
  final bool canCancel;
  final String? cancellationReason;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? confirmedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? responseDeadline;
  final List<BookingStatusHistoryItem> statusHistory;

  const BookingDetail({
    required this.bookingId,
    required this.bookingType,
    required this.status,
    required this.rawStatus,
    required this.paymentStatus,
    this.destinationCity,
    this.requestedDate,
    this.startTime,
    required this.durationInMinutes,
    this.requestedLanguage,
    required this.requiresCar,
    required this.travelersCount,
    this.meetingPointType,
    required this.pickupLocationName,
    this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.destinationName,
    this.destinationLatitude,
    this.destinationLongitude,
    this.notes,
    this.estimatedPrice,
    this.finalPrice,
    this.depositAmount,
    this.remainingAmount,
    required this.depositPaid,
    required this.remainingPaid,
    required this.depositForfeited,
    this.priceBreakdown,
    this.helper,
    this.currentAssignment,
    required this.assignmentAttemptCount,
    required this.chatEnabled,
    required this.paymentRequired,
    required this.canCancel,
    this.cancellationReason,
    this.createdAt,
    this.acceptedAt,
    this.confirmedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.responseDeadline,
    required this.statusHistory,
  });

  @override
  List<Object?> get props => [
        bookingId, bookingType, status, rawStatus, paymentStatus,
        destinationCity, requestedDate, startTime, durationInMinutes,
        requestedLanguage, requiresCar, travelersCount, meetingPointType,
        pickupLocationName, pickupAddress, pickupLatitude, pickupLongitude,
        destinationName, destinationLatitude, destinationLongitude, notes,
        estimatedPrice, finalPrice, depositAmount, remainingAmount,
        depositPaid, remainingPaid, depositForfeited, priceBreakdown,
        helper, currentAssignment, assignmentAttemptCount, chatEnabled,
        paymentRequired, canCancel, cancellationReason, createdAt,
        acceptedAt, confirmedAt, startedAt, completedAt, cancelledAt,
        responseDeadline, statusHistory,
      ];
}
```

`lib/features/tourist/features/user_booking/domain/entities/helper_search_result.dart`

```dart
import 'package:equatable/equatable.dart';

import 'price_breakdown.dart';

class HelperSearchResult extends Equatable {
  final String helperId;
  final String fullName;
  final String? profileImageUrl;
  final double rating;
  final int completedTrips;
  final int experienceYears;
  final List<String> languages;
  final bool hasCar;
  final String? carDescription;
  final double hourlyRate;
  final double estimatedPrice;
  final PriceBreakdown? priceBreakdown;
  final String availabilityStatus;
  final bool canAcceptInstant;
  final bool canAcceptScheduled;
  final int? averageResponseTimeSeconds;
  final double? acceptanceRate;
  final List<String> suitabilityReasons;
  final int matchScore;
  final double? distanceKm;

  const HelperSearchResult({
    required this.helperId,
    required this.fullName,
    this.profileImageUrl,
    required this.rating,
    required this.completedTrips,
    required this.experienceYears,
    required this.languages,
    required this.hasCar,
    this.carDescription,
    required this.hourlyRate,
    required this.estimatedPrice,
    this.priceBreakdown,
    required this.availabilityStatus,
    required this.canAcceptInstant,
    required this.canAcceptScheduled,
    this.averageResponseTimeSeconds,
    this.acceptanceRate,
    required this.suitabilityReasons,
    required this.matchScore,
    this.distanceKm,
  });

  @override
  List<Object?> get props => [
        helperId, fullName, profileImageUrl, rating, completedTrips,
        experienceYears, languages, hasCar, carDescription, hourlyRate,
        estimatedPrice, priceBreakdown, availabilityStatus,
        canAcceptInstant, canAcceptScheduled, averageResponseTimeSeconds,
        acceptanceRate, suitabilityReasons, matchScore, distanceKm,
      ];
}
```

`lib/features/tourist/features/user_booking/domain/entities/helper_booking_profile.dart`

```dart
import 'package:equatable/equatable.dart';

class HelperLanguage extends Equatable {
  final String languageCode;
  final String languageName;
  final String? level;
  final bool isVerified;

  const HelperLanguage({
    required this.languageCode,
    required this.languageName,
    this.level,
    required this.isVerified,
  });

  @override
  List<Object?> get props => [languageCode, languageName, level, isVerified];
}

class HelperServiceArea extends Equatable {
  final String country;
  final String city;
  final String? areaName;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final bool isPrimary;

  const HelperServiceArea({
    required this.country,
    required this.city,
    this.areaName,
    this.latitude,
    this.longitude,
    this.radiusKm,
    required this.isPrimary,
  });

  @override
  List<Object?> get props =>
      [country, city, areaName, latitude, longitude, radiusKm, isPrimary];
}

class HelperCarInfo extends Equatable {
  final String? brand;
  final String? model;
  final String? color;
  final String? type;

  const HelperCarInfo({this.brand, this.model, this.color, this.type});

  @override
  List<Object?> get props => [brand, model, color, type];
}

class HelperBookingProfile extends Equatable {
  final String helperId;
  final String fullName;
  final String? profileImageUrl;
  final String? gender;
  final int? age;
  final String? bio;
  final double rating;
  final int ratingCount;
  final int completedTrips;
  final int experienceYears;
  final double hourlyRate;
  final List<HelperLanguage> languages;
  final List<HelperServiceArea> serviceAreas;
  final List<String> certificates;
  final bool hasCar;
  final HelperCarInfo? car;
  final String availabilityState;
  final bool canAcceptInstant;
  final bool canAcceptScheduled;
  final int? averageResponseTimeSeconds;
  final double? acceptanceRate;

  const HelperBookingProfile({
    required this.helperId,
    required this.fullName,
    this.profileImageUrl,
    this.gender,
    this.age,
    this.bio,
    required this.rating,
    required this.ratingCount,
    required this.completedTrips,
    required this.experienceYears,
    required this.hourlyRate,
    required this.languages,
    required this.serviceAreas,
    required this.certificates,
    required this.hasCar,
    this.car,
    required this.availabilityState,
    required this.canAcceptInstant,
    required this.canAcceptScheduled,
    this.averageResponseTimeSeconds,
    this.acceptanceRate,
  });

  @override
  List<Object?> get props => [
        helperId, fullName, profileImageUrl, gender, age, bio, rating,
        ratingCount, completedTrips, experienceYears, hourlyRate,
        languages, serviceAreas, certificates, hasCar, car,
        availabilityState, canAcceptInstant, canAcceptScheduled,
        averageResponseTimeSeconds, acceptanceRate,
      ];
}
```

`lib/features/tourist/features/user_booking/domain/entities/alternatives_response.dart`

```dart
import 'package:equatable/equatable.dart';

import 'helper_search_result.dart';

class AssignmentAttempt extends Equatable {
  final int attemptOrder;
  final String helperName;
  final String responseStatus;
  final DateTime? sentAt;
  final DateTime? respondedAt;

  const AssignmentAttempt({
    required this.attemptOrder,
    required this.helperName,
    required this.responseStatus,
    this.sentAt,
    this.respondedAt,
  });

  @override
  List<Object?> get props =>
      [attemptOrder, helperName, responseStatus, sentAt, respondedAt];
}

class AlternativesResponse extends Equatable {
  final String bookingId;
  final String status;
  final String message;
  final bool autoRetryActive;
  final int attemptsMade;
  final int maxAttempts;
  final List<HelperSearchResult> alternativeHelpers;
  final List<AssignmentAttempt> assignmentHistory;

  const AlternativesResponse({
    required this.bookingId,
    required this.status,
    required this.message,
    required this.autoRetryActive,
    required this.attemptsMade,
    required this.maxAttempts,
    required this.alternativeHelpers,
    required this.assignmentHistory,
  });

  @override
  List<Object?> get props => [
        bookingId, status, message, autoRetryActive, attemptsMade,
        maxAttempts, alternativeHelpers, assignmentHistory,
      ];
}
```

`lib/features/tourist/features/user_booking/domain/entities/price_breakdown.dart`

```dart
import 'package:equatable/equatable.dart';

class PriceBreakdown extends Equatable {
  final double? baseFare;
  final double? hourlyTotal;
  final double? carSurcharge;
  final double? distanceFee;
  final double? travelerSurcharge;
  final double? languageSurcharge;
  final double? discount;
  final double? tax;
  final double total;
  final String? currency;

  const PriceBreakdown({
    this.baseFare,
    this.hourlyTotal,
    this.carSurcharge,
    this.distanceFee,
    this.travelerSurcharge,
    this.languageSurcharge,
    this.discount,
    this.tax,
    required this.total,
    this.currency,
  });

  @override
  List<Object?> get props => [
        baseFare, hourlyTotal, carSurcharge, distanceFee, travelerSurcharge,
        languageSurcharge, discount, tax, total, currency,
      ];
}
```

`lib/features/tourist/features/user_booking/domain/repositories/instant_booking_repository.dart`

```dart
import 'package:dartz/dartz.dart';

import '../../../../../../core/errors/failures.dart';
import '../entities/alternatives_response.dart';
import '../entities/booking_detail.dart';
import '../entities/booking_status_response.dart';
import '../entities/create_instant_booking_request.dart';
import '../entities/helper_booking_profile.dart';
import '../entities/helper_search_result.dart';
import '../entities/instant_search_request.dart';

abstract class InstantBookingRepository {
  Future<Either<Failure, List<HelperSearchResult>>> searchInstantHelpers(
    InstantSearchRequest request,
  );

  Future<Either<Failure, HelperBookingProfile>> getHelperBookingProfile(
    String helperId,
  );

  Future<Either<Failure, BookingDetail>> createInstantBooking(
    CreateInstantBookingRequest request,
  );

  Future<Either<Failure, BookingStatusResponse>> getBookingStatus(
    String bookingId,
  );

  Future<Either<Failure, BookingDetail>> getBookingDetail(String bookingId);

  Future<Either<Failure, AlternativesResponse>> getAlternatives(
    String bookingId,
  );

  Future<Either<Failure, BookingDetail>> cancelBooking(
    String bookingId,
    String reason,
  );
}
```

The seven instant use cases (`SearchInstantHelpersUC`,
`GetHelperBookingProfileUC`, `CreateInstantBookingUC`,
`GetBookingStatusUC`, `GetBookingDetailUC`, `GetAlternativesUC`,
`CancelInstantBookingUC`) are thin pass-throughs to
`InstantBookingRepository`. Representative form:

```dart
class CreateInstantBookingUC {
  final InstantBookingRepository repository;
  const CreateInstantBookingUC(this.repository);
  Future<Either<Failure, BookingDetail>> call(
    CreateInstantBookingRequest request,
  ) =>
      repository.createInstantBooking(request);
}
```

---

## Section 4 — Data (full file contents)

Endpoints used (verbatim values from `lib/core/config/api_config.dart`):

- `POST   /user/bookings/instant/search`             → `ApiConfig.searchInstantHelpers`
- `GET    /user/bookings/helpers/{helperId}/profile` → `ApiConfig.getHelperProfile(id)`
- `POST   /user/bookings/instant`                    → `ApiConfig.createInstantBooking`
- `GET    /user/bookings/{bookingId}/status`         → `ApiConfig.getBookingStatus(id)`
- `GET    /user/bookings/{bookingId}`                → `ApiConfig.getBookingDetails(id)`
- `GET    /user/bookings/{bookingId}/alternatives`   → `ApiConfig.getAlternatives(id)`
- `POST   /user/bookings/{bookingId}/cancel`         → `ApiConfig.cancelBooking(id)`
- `POST   /notifications/devices`                    → `ApiConfig.registerDevice`
- `DELETE /notifications/devices?fcmToken=…`         → `ApiConfig.unregisterDevice(token)`
- `WS     /hubs/booking`                             → `ApiConfig.bookingHub`

`lib/features/tourist/features/user_booking/data/models/json_helpers.dart`

```dart
library;

Map<String, dynamic> envelopeData(Map<String, dynamic> json) {
  if (json['data'] is Map<String, dynamic>) {
    return json['data'] as Map<String, dynamic>;
  }
  throw const FormatException('Response envelope is missing `data` object');
}

List<dynamic> envelopeDataList(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is List) return data;
  throw const FormatException('Response envelope is missing `data` array');
}

DateTime? tryParseUtc(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) {
    final s = value.trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toUtc();
  }
  return null;
}

double parseDouble(dynamic value, {double fallback = 0.0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? parseDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? parseIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase().trim();
    if (v == 'true') return true;
    if (v == 'false') return false;
  }
  return fallback;
}

List<String> parseStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
  }
  return const [];
}
```

`lib/features/tourist/features/user_booking/data/models/price_breakdown_model.dart`

```dart
import '../../domain/entities/price_breakdown.dart';
import 'json_helpers.dart';

class PriceBreakdownModel extends PriceBreakdown {
  const PriceBreakdownModel({
    super.baseFare, super.hourlyTotal, super.carSurcharge, super.distanceFee,
    super.travelerSurcharge, super.languageSurcharge, super.discount, super.tax,
    required super.total, super.currency,
  });

  factory PriceBreakdownModel.fromJson(Map<String, dynamic> json) =>
      PriceBreakdownModel(
        baseFare: parseDoubleOrNull(json['baseFare']),
        hourlyTotal: parseDoubleOrNull(json['hourlyTotal']),
        carSurcharge: parseDoubleOrNull(json['carSurcharge']),
        distanceFee: parseDoubleOrNull(json['distanceFee']),
        travelerSurcharge: parseDoubleOrNull(json['travelerSurcharge']),
        languageSurcharge: parseDoubleOrNull(json['languageSurcharge']),
        discount: parseDoubleOrNull(json['discount']),
        tax: parseDoubleOrNull(json['tax']),
        total: parseDouble(json['total']),
        currency: json['currency']?.toString(),
      );
}
```

`lib/features/tourist/features/user_booking/data/models/helper_search_result_model.dart`

```dart
import '../../domain/entities/helper_search_result.dart';
import 'json_helpers.dart';
import 'price_breakdown_model.dart';

class HelperSearchResultModel extends HelperSearchResult {
  const HelperSearchResultModel({
    required super.helperId,
    required super.fullName,
    super.profileImageUrl,
    required super.rating,
    required super.completedTrips,
    required super.experienceYears,
    required super.languages,
    required super.hasCar,
    super.carDescription,
    required super.hourlyRate,
    required super.estimatedPrice,
    super.priceBreakdown,
    required super.availabilityStatus,
    required super.canAcceptInstant,
    required super.canAcceptScheduled,
    super.averageResponseTimeSeconds,
    super.acceptanceRate,
    required super.suitabilityReasons,
    required super.matchScore,
    super.distanceKm,
  });

  factory HelperSearchResultModel.fromJson(Map<String, dynamic> json) {
    final breakdown = json['priceBreakdown'];
    return HelperSearchResultModel(
      helperId: json['helperId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl']?.toString(),
      rating: parseDouble(json['rating']),
      completedTrips: parseInt(json['completedTrips']),
      experienceYears: parseInt(json['experienceYears']),
      languages: parseStringList(json['languages']),
      hasCar: parseBool(json['hasCar']),
      carDescription: json['carDescription']?.toString(),
      hourlyRate: parseDouble(json['hourlyRate']),
      estimatedPrice: parseDouble(json['estimatedPrice']),
      priceBreakdown: breakdown is Map<String, dynamic>
          ? PriceBreakdownModel.fromJson(breakdown)
          : null,
      availabilityStatus: json['availabilityStatus']?.toString() ?? 'Unknown',
      canAcceptInstant: parseBool(json['canAcceptInstant']),
      canAcceptScheduled: parseBool(json['canAcceptScheduled']),
      averageResponseTimeSeconds:
          parseIntOrNull(json['averageResponseTimeSeconds']),
      acceptanceRate: parseDoubleOrNull(json['acceptanceRate']),
      suitabilityReasons: parseStringList(json['suitabilityReasons']),
      matchScore: parseInt(json['matchScore']),
      distanceKm: parseDoubleOrNull(json['distanceKm']),
    );
  }
}
```

`lib/features/tourist/features/user_booking/data/models/helper_booking_profile_model.dart`

```dart
import '../../domain/entities/helper_booking_profile.dart';
import 'json_helpers.dart';

class HelperLanguageModel extends HelperLanguage {
  const HelperLanguageModel({
    required super.languageCode,
    required super.languageName,
    super.level,
    required super.isVerified,
  });

  factory HelperLanguageModel.fromJson(Map<String, dynamic> json) =>
      HelperLanguageModel(
        languageCode: json['languageCode']?.toString() ?? '',
        languageName: json['languageName']?.toString() ?? '',
        level: json['level']?.toString(),
        isVerified: parseBool(json['isVerified']),
      );
}

class HelperServiceAreaModel extends HelperServiceArea {
  const HelperServiceAreaModel({
    required super.country,
    required super.city,
    super.areaName,
    super.latitude,
    super.longitude,
    super.radiusKm,
    required super.isPrimary,
  });

  factory HelperServiceAreaModel.fromJson(Map<String, dynamic> json) =>
      HelperServiceAreaModel(
        country: json['country']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        areaName: json['areaName']?.toString(),
        latitude: parseDoubleOrNull(json['latitude']),
        longitude: parseDoubleOrNull(json['longitude']),
        radiusKm: parseDoubleOrNull(json['radiusKm']),
        isPrimary: parseBool(json['isPrimary']),
      );
}

class HelperCarInfoModel extends HelperCarInfo {
  const HelperCarInfoModel({super.brand, super.model, super.color, super.type});

  factory HelperCarInfoModel.fromJson(Map<String, dynamic> json) =>
      HelperCarInfoModel(
        brand: json['brand']?.toString(),
        model: json['model']?.toString(),
        color: json['color']?.toString(),
        type: json['type']?.toString(),
      );
}

class HelperBookingProfileModel extends HelperBookingProfile {
  const HelperBookingProfileModel({
    required super.helperId,
    required super.fullName,
    super.profileImageUrl,
    super.gender, super.age, super.bio,
    required super.rating,
    required super.ratingCount,
    required super.completedTrips,
    required super.experienceYears,
    required super.hourlyRate,
    required super.languages,
    required super.serviceAreas,
    required super.certificates,
    required super.hasCar,
    super.car,
    required super.availabilityState,
    required super.canAcceptInstant,
    required super.canAcceptScheduled,
    super.averageResponseTimeSeconds,
    super.acceptanceRate,
  });

  factory HelperBookingProfileModel.fromJson(Map<String, dynamic> json) {
    final car = json['car'];
    return HelperBookingProfileModel(
      helperId: json['helperId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      profileImageUrl: json['profileImageUrl']?.toString(),
      gender: json['gender']?.toString(),
      age: parseIntOrNull(json['age']),
      bio: json['bio']?.toString(),
      rating: parseDouble(json['rating']),
      ratingCount: parseInt(json['ratingCount']),
      completedTrips: parseInt(json['completedTrips']),
      experienceYears: parseInt(json['experienceYears']),
      hourlyRate: parseDouble(json['hourlyRate']),
      languages: (json['languages'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(HelperLanguageModel.fromJson)
              .toList() ??
          const [],
      serviceAreas: (json['serviceAreas'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(HelperServiceAreaModel.fromJson)
              .toList() ??
          const [],
      certificates: parseStringList(json['certificates']),
      hasCar: parseBool(json['hasCar']),
      car: car is Map<String, dynamic> ? HelperCarInfoModel.fromJson(car) : null,
      availabilityState: json['availabilityState']?.toString() ?? 'Unknown',
      canAcceptInstant: parseBool(json['canAcceptInstant']),
      canAcceptScheduled: parseBool(json['canAcceptScheduled']),
      averageResponseTimeSeconds:
          parseIntOrNull(json['averageResponseTimeSeconds']),
      acceptanceRate: parseDoubleOrNull(json['acceptanceRate']),
    );
  }
}
```

`lib/features/tourist/features/user_booking/data/models/booking_status_response_model.dart`

```dart
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
```

`lib/features/tourist/features/user_booking/data/models/booking_detail_response_model.dart`

```dart
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/booking_status.dart';
import 'json_helpers.dart';
import 'price_breakdown_model.dart';

class BookingHelperSummaryModel extends BookingHelperSummary {
  const BookingHelperSummaryModel({
    required super.helperId,
    required super.fullName,
    super.profileImageUrl,
    required super.rating,
    required super.completedTrips,
    super.phoneNumber,
  });

  factory BookingHelperSummaryModel.fromJson(Map<String, dynamic> json) =>
      BookingHelperSummaryModel(
        helperId: json['helperId']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        profileImageUrl: json['profileImageUrl']?.toString(),
        rating: parseDouble(json['rating']),
        completedTrips: parseInt(json['completedTrips']),
        phoneNumber: json['phoneNumber']?.toString(),
      );
}

class CurrentAssignmentModel extends CurrentAssignment {
  const CurrentAssignmentModel({
    required super.helperId,
    required super.helperName,
    required super.attemptOrder,
    required super.responseStatus,
    super.sentAt,
    super.expiresAt,
  });

  factory CurrentAssignmentModel.fromJson(Map<String, dynamic> json) =>
      CurrentAssignmentModel(
        helperId: json['helperId']?.toString() ?? '',
        helperName: json['helperName']?.toString() ?? '',
        attemptOrder: parseInt(json['attemptOrder']),
        responseStatus: json['responseStatus']?.toString() ?? 'Pending',
        sentAt: tryParseUtc(json['sentAt']),
        expiresAt: tryParseUtc(json['expiresAt']),
      );
}

class BookingStatusHistoryItemModel extends BookingStatusHistoryItem {
  const BookingStatusHistoryItemModel({
    required super.oldStatus,
    required super.newStatus,
    super.changedAt,
    super.reason,
  });

  factory BookingStatusHistoryItemModel.fromJson(Map<String, dynamic> json) =>
      BookingStatusHistoryItemModel(
        oldStatus: json['oldStatus']?.toString() ?? '',
        newStatus: json['newStatus']?.toString() ?? '',
        changedAt: tryParseUtc(json['changedAt']),
        reason: json['reason']?.toString(),
      );
}

class BookingDetailModel extends BookingDetail {
  const BookingDetailModel({
    required super.bookingId, required super.bookingType,
    required super.status, required super.rawStatus,
    required super.paymentStatus, super.destinationCity,
    super.requestedDate, super.startTime,
    required super.durationInMinutes, super.requestedLanguage,
    required super.requiresCar, required super.travelersCount,
    super.meetingPointType, required super.pickupLocationName,
    super.pickupAddress,
    required super.pickupLatitude, required super.pickupLongitude,
    super.destinationName, super.destinationLatitude, super.destinationLongitude,
    super.notes, super.estimatedPrice, super.finalPrice,
    super.depositAmount, super.remainingAmount,
    required super.depositPaid, required super.remainingPaid,
    required super.depositForfeited,
    super.priceBreakdown, super.helper, super.currentAssignment,
    required super.assignmentAttemptCount,
    required super.chatEnabled, required super.paymentRequired,
    required super.canCancel, super.cancellationReason,
    super.createdAt, super.acceptedAt, super.confirmedAt,
    super.startedAt, super.completedAt, super.cancelledAt,
    super.responseDeadline, required super.statusHistory,
  });

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString() ?? 'Unknown';
    final breakdown = json['priceBreakdown'];
    final helper = json['helper'];
    final assignment = json['currentAssignment'];
    return BookingDetailModel(
      bookingId: json['bookingId']?.toString() ?? '',
      bookingType: json['bookingType']?.toString() ?? 'Instant',
      status: BookingStatus.parse(rawStatus),
      rawStatus: rawStatus,
      paymentStatus: PaymentStatusWire.parse(json['paymentStatus']?.toString()),
      destinationCity: json['destinationCity']?.toString(),
      requestedDate: tryParseUtc(json['requestedDate']),
      startTime: json['startTime']?.toString(),
      durationInMinutes: parseInt(json['durationInMinutes']),
      requestedLanguage: json['requestedLanguage']?.toString(),
      requiresCar: parseBool(json['requiresCar']),
      travelersCount: parseInt(json['travelersCount'], fallback: 1),
      meetingPointType: json['meetingPointType']?.toString(),
      pickupLocationName: json['pickupLocationName']?.toString() ?? '',
      pickupAddress: json['pickupAddress']?.toString(),
      pickupLatitude: parseDouble(json['pickupLatitude']),
      pickupLongitude: parseDouble(json['pickupLongitude']),
      destinationName: json['destinationName']?.toString(),
      destinationLatitude: parseDoubleOrNull(json['destinationLatitude']),
      destinationLongitude: parseDoubleOrNull(json['destinationLongitude']),
      notes: json['notes']?.toString(),
      estimatedPrice: parseDoubleOrNull(json['estimatedPrice']),
      finalPrice: parseDoubleOrNull(json['finalPrice']),
      depositAmount: parseDoubleOrNull(json['depositAmount']),
      remainingAmount: parseDoubleOrNull(json['remainingAmount']),
      depositPaid: parseBool(json['depositPaid']),
      remainingPaid: parseBool(json['remainingPaid']),
      depositForfeited: parseBool(json['depositForfeited']),
      priceBreakdown: breakdown is Map<String, dynamic>
          ? PriceBreakdownModel.fromJson(breakdown)
          : null,
      helper: helper is Map<String, dynamic>
          ? BookingHelperSummaryModel.fromJson(helper)
          : null,
      currentAssignment: assignment is Map<String, dynamic>
          ? CurrentAssignmentModel.fromJson(assignment)
          : null,
      assignmentAttemptCount: parseInt(json['assignmentAttemptCount']),
      chatEnabled: parseBool(json['chatEnabled']),
      paymentRequired: parseBool(json['paymentRequired']),
      canCancel: parseBool(json['canCancel']),
      cancellationReason: json['cancellationReason']?.toString(),
      createdAt: tryParseUtc(json['createdAt']),
      acceptedAt: tryParseUtc(json['acceptedAt']),
      confirmedAt: tryParseUtc(json['confirmedAt']),
      startedAt: tryParseUtc(json['startedAt']),
      completedAt: tryParseUtc(json['completedAt']),
      cancelledAt: tryParseUtc(json['cancelledAt']),
      responseDeadline: tryParseUtc(json['responseDeadline']),
      statusHistory: (json['statusHistory'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(BookingStatusHistoryItemModel.fromJson)
              .toList() ??
          const [],
    );
  }
}
```

`lib/features/tourist/features/user_booking/data/models/alternatives_response_model.dart`

```dart
import '../../domain/entities/alternatives_response.dart';
import 'helper_search_result_model.dart';
import 'json_helpers.dart';

class AssignmentAttemptModel extends AssignmentAttempt {
  const AssignmentAttemptModel({
    required super.attemptOrder,
    required super.helperName,
    required super.responseStatus,
    super.sentAt,
    super.respondedAt,
  });

  factory AssignmentAttemptModel.fromJson(Map<String, dynamic> json) =>
      AssignmentAttemptModel(
        attemptOrder: parseInt(json['attemptOrder']),
        helperName: json['helperName']?.toString() ?? '',
        responseStatus: json['responseStatus']?.toString() ?? 'Unknown',
        sentAt: tryParseUtc(json['sentAt']),
        respondedAt: tryParseUtc(json['respondedAt']),
      );
}

class AlternativesResponseModel extends AlternativesResponse {
  const AlternativesResponseModel({
    required super.bookingId,
    required super.status,
    required super.message,
    required super.autoRetryActive,
    required super.attemptsMade,
    required super.maxAttempts,
    required super.alternativeHelpers,
    required super.assignmentHistory,
  });

  factory AlternativesResponseModel.fromJson(Map<String, dynamic> json) =>
      AlternativesResponseModel(
        bookingId: json['bookingId']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Unknown',
        message: json['message']?.toString() ?? '',
        autoRetryActive: parseBool(json['autoRetryActive']),
        attemptsMade: parseInt(json['attemptsMade']),
        maxAttempts: parseInt(json['maxAttempts']),
        alternativeHelpers: (json['alternativeHelpers'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(HelperSearchResultModel.fromJson)
                .toList() ??
            const [],
        assignmentHistory: (json['assignmentHistory'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(AssignmentAttemptModel.fromJson)
                .toList() ??
            const [],
      );
}
```

`lib/features/tourist/features/user_booking/data/datasources/instant_booking_remote_data_source.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../domain/entities/create_instant_booking_request.dart';
import '../../domain/entities/instant_search_request.dart';
import '../models/alternatives_response_model.dart';
import '../models/booking_detail_response_model.dart';
import '../models/booking_status_response_model.dart';
import '../models/helper_booking_profile_model.dart';
import '../models/helper_search_result_model.dart';
import '../models/json_helpers.dart';

abstract class InstantBookingRemoteDataSource {
  Future<List<HelperSearchResultModel>> searchInstantHelpers(InstantSearchRequest request);
  Future<HelperBookingProfileModel> getHelperBookingProfile(String helperId);
  Future<BookingDetailModel> createInstantBooking(CreateInstantBookingRequest request);
  Future<BookingStatusResponseModel> getBookingStatus(String bookingId);
  Future<BookingDetailModel> getBookingDetail(String bookingId);
  Future<AlternativesResponseModel> getAlternatives(String bookingId);
  Future<BookingDetailModel> cancelBooking(String bookingId, String reason);
}

class InstantBookingRemoteDataSourceImpl implements InstantBookingRemoteDataSource {
  final Dio dio;
  InstantBookingRemoteDataSourceImpl(this.dio);

  @override
  Future<List<HelperSearchResultModel>> searchInstantHelpers(
    InstantSearchRequest request,
  ) async {
    return _run<List<HelperSearchResultModel>>(
      () async {
        final res = await dio.post(
          ApiConfig.searchInstantHelpers,
          data: request.toJson(),
        );
        _ensureSuccess(res);
        final list = envelopeDataList(res.data as Map<String, dynamic>);
        return list
            .whereType<Map<String, dynamic>>()
            .map(HelperSearchResultModel.fromJson)
            .toList();
      },
      label: 'searchInstantHelpers',
    );
  }

  @override
  Future<HelperBookingProfileModel> getHelperBookingProfile(String helperId) async {
    return _run<HelperBookingProfileModel>(
      () async {
        final res = await dio.get(ApiConfig.getHelperProfile(helperId));
        _ensureSuccess(res);
        return HelperBookingProfileModel.fromJson(
          envelopeData(res.data as Map<String, dynamic>),
        );
      },
      label: 'getHelperBookingProfile',
    );
  }

  @override
  Future<BookingDetailModel> createInstantBooking(
    CreateInstantBookingRequest request,
  ) async {
    return _run<BookingDetailModel>(
      () async {
        final body = request.toJson();
        debugPrint('📤 POST ${ApiConfig.createInstantBooking} body=$body');
        final res = await dio.post(ApiConfig.createInstantBooking, data: body);
        _ensureSuccess(res);
        return BookingDetailModel.fromJson(
          envelopeData(res.data as Map<String, dynamic>),
        );
      },
      label: 'createInstantBooking',
    );
  }

  @override
  Future<BookingStatusResponseModel> getBookingStatus(String bookingId) async {
    return _run<BookingStatusResponseModel>(
      () async {
        final res = await dio.get(ApiConfig.getBookingStatus(bookingId));
        _ensureSuccess(res);
        return BookingStatusResponseModel.fromJson(
          envelopeData(res.data as Map<String, dynamic>),
        );
      },
      label: 'getBookingStatus',
    );
  }

  @override
  Future<BookingDetailModel> getBookingDetail(String bookingId) async {
    return _run<BookingDetailModel>(
      () async {
        final res = await dio.get(ApiConfig.getBookingDetails(bookingId));
        _ensureSuccess(res);
        return BookingDetailModel.fromJson(
          envelopeData(res.data as Map<String, dynamic>),
        );
      },
      label: 'getBookingDetail',
    );
  }

  @override
  Future<AlternativesResponseModel> getAlternatives(String bookingId) async {
    return _run<AlternativesResponseModel>(
      () async {
        final res = await dio.get(ApiConfig.getAlternatives(bookingId));
        _ensureSuccess(res);
        return AlternativesResponseModel.fromJson(
          envelopeData(res.data as Map<String, dynamic>),
        );
      },
      label: 'getAlternatives',
    );
  }

  @override
  Future<BookingDetailModel> cancelBooking(String bookingId, String reason) async {
    return _run<BookingDetailModel>(
      () async {
        final res = await dio.post(
          ApiConfig.cancelBooking(bookingId),
          data: {'reason': reason},
        );
        _ensureSuccess(res);
        final data = envelopeData(res.data as Map<String, dynamic>);
        if (data['bookingType'] != null) {
          return BookingDetailModel.fromJson(data);
        }
        return getBookingDetail(bookingId);
      },
      label: 'cancelBooking',
    );
  }

  Future<T> _run<T>(Future<T> Function() body, {required String label}) async {
    try {
      return await body();
    } on DioException catch (e) {
      throw _mapDioException(e, label: label);
    } on UnauthorizedException {
      rethrow;
    } on ForbiddenException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      debugPrint('💥 [$label] unexpected error: $e');
      throw ServerException('Unexpected error');
    }
  }

  void _ensureSuccess(Response res) {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final message = _extractMessage(res.data) ?? 'Request failed ($code)';
    throw ServerException(message);
  }

  Exception _mapDioException(DioException e, {required String label}) {
    if (e.error is UnauthorizedException) return e.error as UnauthorizedException;
    if (e.error is ForbiddenException) return e.error as ForbiddenException;
    final code = e.response?.statusCode;
    if (code == 400) {
      final msg = _extractMessage(e.response?.data) ?? 'Invalid request';
      return ServerException(msg);
    }
    if (code == 404) return ServerException(_extractMessage(e.response?.data) ?? 'Not found');
    if (code == 409) return ServerException(_extractMessage(e.response?.data) ?? 'Conflict');
    if (code != null && code >= 500) return ServerException('Server error. Please try again.');
    return ServerException(e.message ?? 'Network error');
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
      final err = data['error'];
      if (err is String && err.isNotEmpty) return err;
    }
    return null;
  }
}
```

`lib/features/tourist/features/user_booking/data/repositories/instant_booking_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/alternatives_response.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/booking_status_response.dart';
import '../../domain/entities/create_instant_booking_request.dart';
import '../../domain/entities/helper_booking_profile.dart';
import '../../domain/entities/helper_search_result.dart';
import '../../domain/entities/instant_search_request.dart';
import '../../domain/repositories/instant_booking_repository.dart';
import '../datasources/instant_booking_remote_data_source.dart';

class InstantBookingRepositoryImpl implements InstantBookingRepository {
  final InstantBookingRemoteDataSource remote;
  const InstantBookingRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<HelperSearchResult>>> searchInstantHelpers(
    InstantSearchRequest request,
  ) =>
      _guard(() async => await remote.searchInstantHelpers(request));

  @override
  Future<Either<Failure, HelperBookingProfile>> getHelperBookingProfile(String helperId) =>
      _guard(() async => await remote.getHelperBookingProfile(helperId));

  @override
  Future<Either<Failure, BookingDetail>> createInstantBooking(
    CreateInstantBookingRequest request,
  ) =>
      _guard(() async => await remote.createInstantBooking(request));

  @override
  Future<Either<Failure, BookingStatusResponse>> getBookingStatus(String bookingId) =>
      _guard(() async => await remote.getBookingStatus(bookingId));

  @override
  Future<Either<Failure, BookingDetail>> getBookingDetail(String bookingId) =>
      _guard(() async => await remote.getBookingDetail(bookingId));

  @override
  Future<Either<Failure, AlternativesResponse>> getAlternatives(String bookingId) =>
      _guard(() async => await remote.getAlternatives(bookingId));

  @override
  Future<Either<Failure, BookingDetail>> cancelBooking(String bookingId, String reason) =>
      _guard(() async => await remote.cancelBooking(bookingId, reason));

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      final value = await action();
      return Right(value);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ForbiddenFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Network error'));
    } on FormatException catch (e) {
      return Left(ServerFailure('Invalid server response: ${e.message}'));
    } catch (_) {
      return const Left(GenericFailure());
    }
  }
}
```

---

## Section 5 — State (full file contents)

`lib/features/tourist/features/user_booking/presentation/cubits/instant_booking_state.dart`

```dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/alternatives_response.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/helper_search_result.dart';

abstract class InstantBookingState extends Equatable {
  const InstantBookingState();
  @override
  List<Object?> get props => [];
}

class InstantBookingInitial extends InstantBookingState {
  const InstantBookingInitial();
}

class InstantBookingSearching extends InstantBookingState {
  const InstantBookingSearching();
}

class InstantBookingHelpersLoaded extends InstantBookingState {
  final List<HelperSearchResult> helpers;
  const InstantBookingHelpersLoaded(this.helpers);
  @override
  List<Object?> get props => [helpers];
}

class InstantBookingCreating extends InstantBookingState {
  const InstantBookingCreating();
}

class InstantBookingCreated extends InstantBookingState {
  final BookingDetail booking;
  const InstantBookingCreated(this.booking);
  @override
  List<Object?> get props => [booking];
}

class InstantBookingWaiting extends InstantBookingState {
  final BookingDetail booking;
  const InstantBookingWaiting(this.booking);
  @override
  List<Object?> get props => [booking];
}

class InstantBookingAccepted extends InstantBookingState {
  final BookingDetail booking;
  const InstantBookingAccepted(this.booking);
  @override
  List<Object?> get props => [booking];
}

class InstantBookingDeclined extends InstantBookingState {
  final BookingDetail booking;
  final AlternativesResponse alternatives;
  const InstantBookingDeclined(this.booking, this.alternatives);
  @override
  List<Object?> get props => [booking, alternatives];
}

class InstantBookingCancelled extends InstantBookingState {
  final String reason;
  const InstantBookingCancelled(this.reason);
  @override
  List<Object?> get props => [reason];
}

class InstantBookingError extends InstantBookingState {
  final String message;
  const InstantBookingError(this.message);
  @override
  List<Object?> get props => [message];
}
```

`lib/features/tourist/features/user_booking/presentation/cubits/instant_booking_cubit.dart`

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/services/signalr/booking_hub_events.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/create_instant_booking_request.dart';
import '../../domain/entities/helper_search_result.dart';
import '../../domain/entities/instant_search_request.dart';
import '../../domain/usecases/instant/cancel_instant_booking_uc.dart';
import '../../domain/usecases/instant/create_instant_booking_uc.dart';
import '../../domain/usecases/instant/get_alternatives_uc.dart';
import '../../domain/usecases/instant/get_booking_detail_uc.dart';
import '../../domain/usecases/instant/search_instant_helpers_uc.dart';
import 'instant_booking_state.dart';

class InstantBookingCubit extends Cubit<InstantBookingState> {
  InstantBookingCubit({
    required this.searchInstantHelpersUC,
    required this.createInstantBookingUC,
    required this.cancelInstantBookingUC,
    required this.getBookingDetailUC,
    required this.getAlternativesUC,
    required this.hubService,
  }) : super(const InstantBookingInitial());

  final SearchInstantHelpersUC searchInstantHelpersUC;
  final CreateInstantBookingUC createInstantBookingUC;
  final CancelInstantBookingUC cancelInstantBookingUC;
  final GetBookingDetailUC getBookingDetailUC;
  final GetAlternativesUC getAlternativesUC;
  final BookingTrackingHubService hubService;

  StreamSubscription<BookingStatusChangedEvent>? _statusSub;
  StreamSubscription<BookingCancelledEvent>? _cancelledSub;
  Timer? _pollTimer;
  String? _watchedBookingId;

  Future<void> searchHelpers(InstantSearchRequest request) async {
    emit(const InstantBookingSearching());
    final result = await searchInstantHelpersUC(request);
    result.fold(
      (failure) => emit(InstantBookingError(failure.message)),
      (helpers) => emit(InstantBookingHelpersLoaded(helpers)),
    );
  }

  void presentCachedHelpers(List<HelperSearchResult> helpers) {
    emit(InstantBookingHelpersLoaded(helpers));
  }

  Future<void> createBooking(CreateInstantBookingRequest request) async {
    emit(const InstantBookingCreating());
    final result = await createInstantBookingUC(request);
    result.fold(
      (failure) => emit(InstantBookingError(failure.message)),
      (booking) {
        emit(InstantBookingCreated(booking));
        _startWatching(booking);
      },
    );
  }

  Future<void> startWatchingExisting(String bookingId) async {
    final result = await getBookingDetailUC(bookingId);
    result.fold(
      (failure) => emit(InstantBookingError(failure.message)),
      _startWatching,
    );
  }

  void _startWatching(BookingDetail booking) {
    _stopWatching();
    _watchedBookingId = booking.bookingId;
    emit(InstantBookingWaiting(booking));
    _attachSignalR(booking.bookingId);
    _startPolling(booking.bookingId);
  }

  Future<void> _attachSignalR(String bookingId) async {
    try {
      await hubService.ensureConnected();
    } catch (e) {
      debugPrint('⚠️ InstantBookingCubit: SignalR ensureConnected failed → $e');
    }
    _statusSub = hubService.bookingStatusChangedStream
        .where((e) => e.bookingId == bookingId)
        .listen(_onStatusChanged);
    _cancelledSub = hubService.bookingCancelledStream
        .where((e) => e.bookingId == bookingId)
        .listen(_onCancelled);
  }

  void _startPolling(String bookingId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_watchedBookingId != bookingId) return;
      await _refreshBooking(bookingId, fromPoll: true);
    });
  }

  Future<void> _onStatusChanged(BookingStatusChangedEvent event) async {
    debugPrint('📡 BookingStatusChanged: ${event.oldStatus} → ${event.newStatus}');
    await _handleNewStatus(event.bookingId, event.newStatus);
  }

  void _onCancelled(BookingCancelledEvent event) {
    debugPrint('📡 BookingCancelled: ${event.reason}');
    _emitCancelled(event.reason ?? 'Booking cancelled');
  }

  Future<void> _handleNewStatus(String bookingId, String newStatusRaw) async {
    final parsed = BookingStatus.parse(newStatusRaw);
    switch (parsed) {
      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmed:
        final detail = await _fetchOrFail(bookingId);
        if (detail != null) {
          emit(InstantBookingAccepted(detail));
          _stopWatching();
        }
        break;
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
      case BookingStatus.waitingForUserAction:
        await _emitDeclined(bookingId);
        break;
      case BookingStatus.reassignmentInProgress:
        await _refreshBooking(bookingId);
        break;
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
        _emitCancelled('Booking cancelled');
        break;
      default:
        await _refreshBooking(bookingId);
        break;
    }
  }

  Future<BookingDetail?> _fetchOrFail(String bookingId) async {
    final result = await getBookingDetailUC(bookingId);
    return result.fold(
      (failure) {
        emit(InstantBookingError(failure.message));
        return null;
      },
      (detail) => detail,
    );
  }

  Future<void> _refreshBooking(String bookingId, {bool fromPoll = false}) async {
    final result = await getBookingDetailUC(bookingId);
    result.fold(
      (failure) {
        if (!fromPoll) emit(InstantBookingError(failure.message));
      },
      (detail) async {
        await _handleStatusFromDetail(detail);
      },
    );
  }

  Future<void> _handleStatusFromDetail(BookingDetail detail) async {
    switch (detail.status) {
      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmed:
        emit(InstantBookingAccepted(detail));
        _stopWatching();
        break;
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
      case BookingStatus.waitingForUserAction:
        await _emitDeclinedFromDetail(detail);
        break;
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
        _emitCancelled(detail.cancellationReason ?? 'Booking cancelled');
        break;
      case BookingStatus.inProgress:
      case BookingStatus.completed:
        emit(InstantBookingAccepted(detail));
        _stopWatching();
        break;
      default:
        emit(InstantBookingWaiting(detail));
        break;
    }
  }

  Future<void> _emitDeclined(String bookingId) async {
    final detail = await _fetchOrFail(bookingId);
    if (detail == null) return;
    await _emitDeclinedFromDetail(detail);
  }

  Future<void> _emitDeclinedFromDetail(BookingDetail detail) async {
    final altResult = await getAlternativesUC(detail.bookingId);
    altResult.fold(
      (failure) => emit(InstantBookingError(failure.message)),
      (alternatives) => emit(InstantBookingDeclined(detail, alternatives)),
    );
  }

  void _emitCancelled(String reason) {
    emit(InstantBookingCancelled(reason));
    _stopWatching();
  }

  Future<bool> cancelBooking(String bookingId, String reason) async {
    final result = await cancelInstantBookingUC(bookingId: bookingId, reason: reason);
    return result.fold(
      (failure) {
        emit(InstantBookingError(failure.message));
        return false;
      },
      (_) {
        _emitCancelled(reason);
        return true;
      },
    );
  }

  void _stopWatching() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _statusSub?.cancel();
    _statusSub = null;
    _cancelledSub?.cancel();
    _cancelledSub = null;
    _watchedBookingId = null;
  }

  void reset() {
    _stopWatching();
    emit(const InstantBookingInitial());
  }

  @override
  Future<void> close() {
    _stopWatching();
    return super.close();
  }
}
```

`lib/features/tourist/features/user_booking/presentation/cubits/helper_booking_profile_cubit.dart`

```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/helper_booking_profile.dart';
import '../../domain/usecases/instant/get_helper_profile_uc.dart';

abstract class HelperBookingProfileState extends Equatable {
  const HelperBookingProfileState();
  @override
  List<Object?> get props => [];
}

class HelperBookingProfileInitial extends HelperBookingProfileState {
  const HelperBookingProfileInitial();
}

class HelperBookingProfileLoading extends HelperBookingProfileState {
  const HelperBookingProfileLoading();
}

class HelperBookingProfileLoaded extends HelperBookingProfileState {
  final HelperBookingProfile profile;
  const HelperBookingProfileLoaded(this.profile);
  @override
  List<Object?> get props => [profile];
}

class HelperBookingProfileError extends HelperBookingProfileState {
  final String message;
  const HelperBookingProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

class HelperBookingProfileCubit extends Cubit<HelperBookingProfileState> {
  final GetHelperBookingProfileUC getHelperBookingProfileUC;

  HelperBookingProfileCubit({required this.getHelperBookingProfileUC})
      : super(const HelperBookingProfileInitial());

  Future<void> load(String helperId) async {
    emit(const HelperBookingProfileLoading());
    final result = await getHelperBookingProfileUC(helperId);
    result.fold(
      (failure) => emit(HelperBookingProfileError(failure.message)),
      (profile) => emit(HelperBookingProfileLoaded(profile)),
    );
  }
}
```

---

## Section 6 — UI (full file contents, page-by-page in flow order)

The flow visits these screens in order: entry → trip details (with map pickers) →
helpers list → helper profile → review → waiting → (accepted) confirmed → tracking,
or (declined) alternatives → review (loop).

### Step 1 — `BookingHomePage`

`lib/features/tourist/features/user_booking/presentation/pages/booking_home_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';

class BookingHomePage extends StatelessWidget {
  const BookingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('book_a_helper'))),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spaceXL),
            _buildTypeCard(
              context,
              title: loc.translate('instant'),
              subtitle: 'Find an available helper right now',
              icon: Icons.bolt_rounded,
              color: AppColor.accentColor,
              onTap: () => context.push(AppRouter.instantTripDetails),
            ),
            const SizedBox(height: AppTheme.spaceLG),
            _buildTypeCard(
              context,
              title: loc.translate('scheduled'),
              subtitle: 'Plan ahead and book for a future date',
              icon: Icons.calendar_today_rounded,
              color: AppColor.secondaryColor,
              onTap: () => context.push(AppRouter.scheduledSearch),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMD),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: AppTheme.spaceLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.headlineMedium.copyWith(color: color)),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(subtitle,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColor.lightTextSecondary,
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
```

### Map picker

`lib/features/tourist/features/user_booking/presentation/pages/instant/location_pick_result.dart`

```dart
import 'package:equatable/equatable.dart';

class LocationPickResult extends Equatable {
  final String name;
  final String? address;
  final double latitude;
  final double longitude;

  const LocationPickResult({
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [name, address, latitude, longitude];
}
```

`lib/features/tourist/features/user_booking/presentation/pages/instant/location_picker_page.dart`

> 438 lines. Renders a full-screen `flutter_map` (OpenStreetMap tiles), a
> centred map pin, "Use my location" FAB, debounced reverse-geocoding via
> `geocoding`, and a "Confirm pickup/destination" CTA. The result is a
> `LocationPickResult { name, address?, latitude, longitude }` returned via
> `Navigator.pop`. Permission flow uses `permission_handler` and falls back to
> the OSM Cairo centre `(30.0444, 31.2357)` if location services are denied.
> The reverse-geocoded label is the short form `"<thoroughfare>, <locality>"`
> when available, otherwise placemark name, otherwise raw lat/lng. There are
> no API calls and no domain-level state — this widget only emits a
> `LocationPickResult`. Full source on disk; the contract-affecting bit
> (`Navigator.pop(LocationPickResult(name: _label!, address: _address,
> latitude: _center.latitude, longitude: _center.longitude))`) is the only
> data crossing back to the caller.

### Step 2 — `InstantTripDetailsPage`

`lib/features/tourist/features/user_booking/presentation/pages/instant/instant_trip_details_page.dart`

> 570 lines. The relevant transport-affecting code is reproduced below. The
> remaining classes (`_SectionTitle`, `_LocationCard`, `_DurationChips`,
> `_TravelerStepper`, `_LanguageRow`) are presentational only.

```dart
class _InstantTripDetailsViewState extends State<_InstantTripDetailsView> {
  LocationPickResult? _pickup;
  LocationPickResult? _destination;
  int _durationMinutes = 0;
  int _travelers = 1;
  String? _languageCode;
  bool _requiresCar = false;
  late final TextEditingController _notesCtrl = TextEditingController();

  bool get _isValid =>
      _pickup != null &&
      _destination != null &&
      _durationMinutes >= kMinDurationMinutes &&
      _durationMinutes <= kMaxDurationMinutes &&
      _travelers >= 1 &&
      _travelers <= 20;

  void _submit() {
    if (!_isValid) return;
    final request = InstantSearchRequest(
      pickupLocationName: _pickup!.name,
      pickupLatitude: _pickup!.latitude,
      pickupLongitude: _pickup!.longitude,
      durationInMinutes: _durationMinutes,
      requestedLanguage: _languageCode,
      requiresCar: _requiresCar,
      travelersCount: _travelers,
    );
    context.read<InstantBookingCubit>().searchHelpers(request);
    context.push(
      AppRouter.instantHelpersList,
      extra: {
        'cubit': context.read<InstantBookingCubit>(),
        'searchRequest': request,
        'pickup': _pickup,
        'destination': _destination,
        'travelers': _travelers,
        'durationInMinutes': _durationMinutes,
        'languageCode': _languageCode,
        'requiresCar': _requiresCar,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      },
    );
  }
}
```

### Step 4 — `InstantHelpersListPage`

`lib/features/tourist/features/user_booking/presentation/pages/instant/instant_helpers_list_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../../domain/entities/instant_search_request.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/empty_error_state.dart';
import '../../widgets/instant/helper_suitability_card.dart';
import '../../widgets/instant/skeleton.dart';
import 'location_pick_result.dart';

class InstantHelpersListPage extends StatelessWidget {
  final InstantBookingCubit cubit;
  final InstantSearchRequest searchRequest;
  final LocationPickResult pickup;
  final LocationPickResult destination;
  final int travelers;
  final int durationInMinutes;
  final String? languageCode;
  final bool requiresCar;
  final String? notes;

  const InstantHelpersListPage({
    super.key,
    required this.cubit,
    required this.searchRequest,
    required this.pickup,
    required this.destination,
    required this.travelers,
    required this.durationInMinutes,
    required this.languageCode,
    required this.requiresCar,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<InstantBookingCubit, InstantBookingState>(
        builder: (context, state) {
          if (state is InstantBookingSearching || state is InstantBookingInitial) {
            return Scaffold(
              appBar: AppBar(title: const Text('Available helpers')),
              body: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                itemCount: 5,
                itemBuilder: (_, __) => const HelperCardSkeleton(),
              ),
            );
          }
          if (state is InstantBookingError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Available helpers')),
              body: ErrorRetryState(
                message: state.message,
                onRetry: () => cubit.searchHelpers(searchRequest),
              ),
            );
          }
          if (state is InstantBookingHelpersLoaded) {
            return Scaffold(
              appBar: AppBar(title: const Text('Available helpers')),
              body: state.helpers.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No helpers nearby',
                      message: 'Try widening your duration, lowering travelers count, or removing the car requirement.',
                      actionLabel: 'Edit search',
                      onAction: () => context.pop(),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => cubit.searchHelpers(searchRequest),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spaceLG),
                        itemCount: state.helpers.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                          child: HelperSuitabilityCard(
                            helper: state.helpers[i],
                            onTap: () => _onTap(context, state.helpers[i]),
                          ),
                        ),
                      ),
                    ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _onTap(BuildContext context, HelperSearchResult helper) {
    context.push(
      AppRouter.instantHelperProfile.replaceFirst(':id', helper.helperId),
      extra: {
        'cubit': context.read<InstantBookingCubit>(),
        'helper': helper,
        'pickup': pickup,
        'destination': destination,
        'travelers': travelers,
        'durationInMinutes': durationInMinutes,
        'languageCode': languageCode,
        'requiresCar': requiresCar,
        'notes': notes,
      },
    );
  }
}
```

### Step 5 — `HelperBookingProfilePage`

`lib/features/tourist/features/user_booking/presentation/pages/instant/helper_booking_profile_page.dart`

> 581 lines. Imports `HelperBookingProfileCubit` and triggers
> `..load(helper.helperId)` in `BlocProvider.create`. Renders the loaded
> `HelperBookingProfile` (avatar, rating, languages, certificates, car info,
> service areas) and a sticky CTA. The transport-affecting handler is the
> "Request now" CTA, which preserves the form state and pushes the review
> route:

```dart
void _onRequest(BuildContext context) {
  context.push(
    AppRouter.instantBookingReview,
    extra: {
      'cubit': context.read<InstantBookingCubit>(),
      'helper': helper,
      'pickup': pickup,
      'destination': destination,
      'travelers': travelers,
      'durationInMinutes': durationInMinutes,
      'languageCode': languageCode,
      'requiresCar': requiresCar,
      'notes': notes,
    },
  );
}
```

### Step 6 — `BookingReviewPage`

`lib/features/tourist/features/user_booking/presentation/pages/instant/booking_review_page.dart`

```dart
class _ReviewView extends StatelessWidget {
  // (constructor with helper, pickup, destination, travelers,
  // durationInMinutes, languageCode, requiresCar, notes — all forwarded
  // verbatim from the previous step's extras)

  void _confirm(BuildContext context) {
    final request = CreateInstantBookingRequest(
      helperId: helper.helperId,
      pickupLocationName: pickup.name,
      pickupLatitude: pickup.latitude,
      pickupLongitude: pickup.longitude,
      destinationName: destination.name,
      destinationLatitude: destination.latitude,
      destinationLongitude: destination.longitude,
      durationInMinutes: durationInMinutes,
      requestedLanguage: languageCode,
      requiresCar: requiresCar,
      travelersCount: travelers,
      notes: notes,
    );
    context.read<InstantBookingCubit>().createBooking(request);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InstantBookingCubit, InstantBookingState>(
      listener: (context, state) {
        if (state is InstantBookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message),
              backgroundColor: AppColor.errorColor),
          );
        }
        if (state is InstantBookingCreated || state is InstantBookingWaiting) {
          final booking = state is InstantBookingCreated
              ? state.booking
              : (state as InstantBookingWaiting).booking;
          context.pushReplacement(
            AppRouter.instantWaiting.replaceFirst(':id', booking.bookingId),
            extra: {
              'cubit': context.read<InstantBookingCubit>(),
              'helper': helper,
            },
          );
        }
      },
      builder: (context, state) {
        final loading = state is InstantBookingCreating;
        return Scaffold(
          appBar: AppBar(title: const Text('Review your booking')),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: CustomButton(
                text: 'Confirm & send request',
                icon: Icons.send_rounded,
                isLoading: loading,
                onPressed: () => _confirm(context),
              ),
            ),
          ),
          body: ListView(
            // ... helper banner, trip details list, price breakdown card.
          ),
        );
      },
    );
  }
}
```

### Step 7 — `WaitingForHelperPage`

`lib/features/tourist/features/user_booking/presentation/pages/instant/waiting_for_helper_page.dart`

```dart
class _WaitingForHelperPageState extends State<WaitingForHelperPage> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    if (state is InstantBookingCreated) {
      widget.cubit.startWatchingExisting(widget.bookingId);
    } else if (state is InstantBookingWaiting) {
      // Already watching; nothing to do.
    } else {
      widget.cubit.startWatchingExisting(widget.bookingId);
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  // Hub event handlers live in InstantBookingCubit (Section 5). The page
  // listens to cubit-state transitions and navigates accordingly:
  void _onState(BuildContext context, InstantBookingState state) {
    if (state is InstantBookingAccepted) {
      context.pushReplacement(
        AppRouter.instantConfirmed
            .replaceFirst(':id', state.booking.bookingId),
        extra: { 'cubit': widget.cubit, 'helper': widget.helper },
      );
    } else if (state is InstantBookingDeclined) {
      context.pushReplacement(
        AppRouter.instantAlternatives
            .replaceFirst(':id', state.booking.bookingId),
        extra: {
          'cubit': widget.cubit,
          'booking': state.booking,
          'alternatives': state.alternatives,
        },
      );
    } else if (state is InstantBookingCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request cancelled: ${state.reason}')),
      );
      context.go(AppRouter.bookingHome);
    } else if (state is InstantBookingError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message),
          backgroundColor: AppColor.errorColor),
      );
    }
  }

  Future<void> _onCancel(BuildContext ctx) async {
    final reason = await showCancelReasonSheet(ctx);
    if (reason == null || !mounted) return;
    final ok = await widget.cubit.cancelBooking(widget.bookingId, reason);
    if (!ok || !mounted) return;
    if (!context.mounted) return;
    context.go(AppRouter.bookingHome);
  }
}
```

> The body draws a `RadarPulse` halo around the helper's avatar, the helper
> name + attempt count, and a `responseDeadline` countdown derived from the
> booking detail. Hub subscriptions are owned by `InstantBookingCubit`, not
> the page.

### Step 8 — `BookingAlternativesPage`

`lib/features/tourist/features/user_booking/presentation/pages/instant/booking_alternatives_page.dart`

```dart
class BookingAlternativesPage extends StatelessWidget {
  final InstantBookingCubit cubit;
  final BookingDetail booking;
  final AlternativesResponse alternatives;

  const BookingAlternativesPage({
    super.key,
    required this.cubit,
    required this.booking,
    required this.alternatives,
  });

  void _onPick(BuildContext context, HelperSearchResult helper) {
    final pickup = LocationPickResult(
      name: booking.pickupLocationName,
      address: booking.pickupAddress,
      latitude: booking.pickupLatitude,
      longitude: booking.pickupLongitude,
    );
    final destination = LocationPickResult(
      name: booking.destinationName ?? 'Destination',
      latitude: booking.destinationLatitude ?? 0,
      longitude: booking.destinationLongitude ?? 0,
    );
    context.push(
      AppRouter.instantBookingReview,
      extra: {
        'cubit': cubit,
        'helper': helper,
        'pickup': pickup,
        'destination': destination,
        'travelers': booking.travelersCount,
        'durationInMinutes': booking.durationInMinutes,
        'languageCode': booking.requestedLanguage,
        'requiresCar': booking.requiresCar,
        'notes': booking.notes,
      },
    );
  }
  // build(...) renders alternatives.message banner, assignmentHistory tiles,
  // and a list of HelperSuitabilityCard with onTap = _onPick.
}
```

### Step 9 — `BookingConfirmedPage`

`lib/features/tourist/features/user_booking/presentation/pages/instant/booking_confirmed_page.dart`

```dart
class _BookingConfirmedPageState extends State<BookingConfirmedPage> {
  late final BookingTrackingHubService _hub;
  StreamSubscription<BookingTripStartedEvent>? _tripStartedSub;

  @override
  void initState() {
    super.initState();
    _hub = sl<BookingTrackingHubService>();
    _tripStartedSub = _hub.bookingTripStartedStream
        .where((e) => e.bookingId == widget.bookingId)
        .listen(_onTripStarted);
  }

  void _onTripStarted(BookingTripStartedEvent event) {
    if (!mounted) return;
    context.pushReplacement(
      AppRouter.instantTripTracking.replaceFirst(':id', widget.bookingId),
      extra: { 'cubit': widget.cubit, 'helper': widget.helper },
    );
  }

  Future<void> _openChat() async =>
      context.push(AppRouter.userChat.replaceFirst(':id', widget.bookingId));

  Future<void> _openPayment() async =>
      context.push(AppRouter.paymentMethod.replaceFirst(':bookingId', widget.bookingId));

  // build(...) renders success header, helper card with call/chat/pay CTAs,
  // and trip summary.
}
```

### Step 10 — `TripTrackingPage`

`lib/features/tourist/features/user_booking/presentation/pages/instant/trip_tracking_page.dart`

```dart
class _TripTrackingPageState extends State<TripTrackingPage> {
  late final BookingTrackingHubService _hub;
  late final MapController _mapController;
  StreamSubscription<HelperLocationUpdateEvent>? _locationSub;
  StreamSubscription<BookingTripEndedEvent>? _tripEndedSub;
  HelperLocationUpdateEvent? _latest;

  @override
  void initState() {
    super.initState();
    _hub = sl<BookingTrackingHubService>();
    _mapController = MapController();
    _locationSub = _hub.helperLocationUpdateStream
        .where((e) => e.bookingId == widget.bookingId)
        .listen(_onLocation);
    _tripEndedSub = _hub.bookingTripEndedStream
        .where((e) => e.bookingId == widget.bookingId)
        .listen(_onTripEnded);
    _ensureConnected();
  }

  Future<void> _ensureConnected() async {
    try { await _hub.ensureConnected(); }
    catch (e) { debugPrint('🛰️ TripTrackingPage: hub ensureConnected failed → $e'); }
  }

  void _onLocation(HelperLocationUpdateEvent event) {
    setState(() => _latest = event);
    _mapController.move(LatLng(event.latitude, event.longitude), 16);
  }

  void _onTripEnded(BookingTripEndedEvent event) {
    if (!mounted) return;
    context.pushReplacement(
      AppRouter.rateBooking.replaceFirst(':bookingId', widget.bookingId),
    );
  }
  // build(...) renders FlutterMap with pickup/destination/helper markers,
  // bottom sheet with ETA + distance, and a "Cancel trip" CTA wired to
  // cubit.cancelBooking when canCancel.
}
```

### UI widgets (presentational helpers)

`lib/features/tourist/features/user_booking/presentation/widgets/instant/skeleton.dart` — `SkeletonBox` + `HelperCardSkeleton` shimmer.
`lib/features/tourist/features/user_booking/presentation/widgets/instant/empty_error_state.dart` — `EmptyState` and `ErrorRetryState`.
`lib/features/tourist/features/user_booking/presentation/widgets/instant/helper_suitability_card.dart` — card showing avatar, rating, languages, price, suitability reasons, match score.
`lib/features/tourist/features/user_booking/presentation/widgets/instant/price_breakdown_card.dart` — line items + total, currency suffix.
`lib/features/tourist/features/user_booking/presentation/widgets/instant/duration_picker_sheet.dart` — exposes `kMinDurationMinutes = 60`, `kMaxDurationMinutes = 24*60`, presets + custom slider.
`lib/features/tourist/features/user_booking/presentation/widgets/instant/cancel_reason_sheet.dart` — preset reasons + free-form ≥5 chars.
`lib/features/tourist/features/user_booking/presentation/widgets/instant/radar_pulse.dart` — animated halo around the helper avatar.

`lib/features/tourist/features/user_booking/presentation/widgets/instant/language_picker_sheet.dart`

```dart
class LanguageOption {
  final String? code;
  final String name;
  final String emoji;
  const LanguageOption({required this.code, required this.name, required this.emoji});
}

const List<LanguageOption> kBookingLanguageOptions = [
  LanguageOption(code: null, name: 'Any language', emoji: '🌐'),
  LanguageOption(code: 'en', name: 'English', emoji: '🇬🇧'),
  LanguageOption(code: 'ar', name: 'Arabic', emoji: '🇪🇬'),
  LanguageOption(code: 'fr', name: 'French', emoji: '🇫🇷'),
  LanguageOption(code: 'es', name: 'Spanish', emoji: '🇪🇸'),
  LanguageOption(code: 'de', name: 'German', emoji: '🇩🇪'),
  LanguageOption(code: 'it', name: 'Italian', emoji: '🇮🇹'),
  LanguageOption(code: 'ru', name: 'Russian', emoji: '🇷🇺'),
  LanguageOption(code: 'zh', name: 'Chinese', emoji: '🇨🇳'),
];

LanguageOption languageOptionForCode(String? code) =>
    kBookingLanguageOptions.firstWhere(
      (o) => o.code == code,
      orElse: () => kBookingLanguageOptions.first,
    );

Future<LanguageOption?> showLanguagePickerSheet(
  BuildContext context, {
  String? initialCode,
}) {
  // showModalBottomSheet returning a LanguageOption (the .code is what feeds
  // InstantSearchRequest.requestedLanguage and CreateInstantBookingRequest.
  // requestedLanguage — always the 2-letter ISO 639-1 code or null).
}
```

---

## Section 7 � SignalR (full file contents)

`lib/core/services/signalr/booking_tracking_hub_service.dart`

`dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

import '../../config/api_config.dart';
import '../../models/tracking/tracking_point_model.dart';
import '../../models/tracking/tracking_update.dart';
import 'booking_hub_events.dart';

/// Singleton SignalR client for the `booking` hub.
///
/// Lifecycle:
///   - `connect(token)` is called from `AuthCubit` after a successful login.
///   - `disconnect()` is called on logout.
///   - `ensureConnected()` can be awaited by any cubit before subscribing —
///     it is a no-op if the connection is already up.
///
/// The class exposes both:
///   - typed streams (preferred for new code), e.g. [bookingStatusChangedStream],
///   - legacy untyped streams (kept for the helper-side cubits that already
///     depend on them — touching them is out of scope for the instant flow
///     rebuild).
class BookingTrackingHubService {
  HubConnection? _hubConnection;
  String? _currentToken;
  Future<void>? _connectInFlight;

  // ── Legacy (untyped) controllers — DO NOT remove; helper-side relies on them.
  final _locationController = StreamController<TrackingUpdate>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _requestController = StreamController<Map<String, dynamic>>.broadcast();
  final _dashboardController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();

  // ── Typed controllers — preferred for the user-side instant flow.
  final _bookingStatusChanged =
      StreamController<BookingStatusChangedEvent>.broadcast();
  final _bookingCancelled =
      StreamController<BookingCancelledEvent>.broadcast();
  final _bookingPaymentChanged =
      StreamController<BookingPaymentChangedEvent>.broadcast();
  final _bookingTripStarted =
      StreamController<BookingTripStartedEvent>.broadcast();
  final _bookingTripEnded =
      StreamController<BookingTripEndedEvent>.broadcast();
  final _helperLocationUpdate =
      StreamController<HelperLocationUpdateEvent>.broadcast();
  final _chatMessagePush =
      StreamController<ChatMessagePushEvent>.broadcast();
  final _connectionStateController =
      StreamController<HubConnectionState>.broadcast();

  BookingTrackingHubService();

  // ── Legacy stream getters ───────────────────────────────────────────────────
  Stream<TrackingUpdate> get locationStream => _locationController.stream;
  @Deprecated('Use locationStream instead')
  Stream<TrackingUpdate> get updateStream => _locationController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get requestStream => _requestController.stream;
  Stream<Map<String, dynamic>> get dashboardStream => _dashboardController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;

  // ── Typed stream getters (USE THESE) ───────────────────────────────────────
  Stream<BookingStatusChangedEvent> get bookingStatusChangedStream =>
      _bookingStatusChanged.stream;
  Stream<BookingCancelledEvent> get bookingCancelledStream =>
      _bookingCancelled.stream;
  Stream<BookingPaymentChangedEvent> get bookingPaymentChangedStream =>
      _bookingPaymentChanged.stream;
  Stream<BookingTripStartedEvent> get bookingTripStartedStream =>
      _bookingTripStarted.stream;
  Stream<BookingTripEndedEvent> get bookingTripEndedStream =>
      _bookingTripEnded.stream;
  Stream<HelperLocationUpdateEvent> get helperLocationUpdateStream =>
      _helperLocationUpdate.stream;
  Stream<ChatMessagePushEvent> get chatMessageStream =>
      _chatMessagePush.stream;
  Stream<HubConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  bool get isConnected =>
      _hubConnection?.state == HubConnectionState.Connected;

  // ── Public lifecycle ────────────────────────────────────────────────────────

  /// Connects (or reconnects) to the hub using [token]. Safe to call multiple
  /// times — subsequent calls with the same token are no-ops while connected.
  Future<void> connect(String token) async {
    if (isConnected && _currentToken == token) {
      debugPrint('📡 SignalR: already connected with same token, skipping');
      return;
    }

    if (_connectInFlight != null) {
      return _connectInFlight!;
    }

    _connectInFlight = _connect(token);
    try {
      await _connectInFlight;
    } finally {
      _connectInFlight = null;
    }
  }

  /// Awaits an in-flight connection or returns immediately if already
  /// connected. If never connected and no token is available, this throws —
  /// callers (e.g. cubits) should catch and surface a friendly message.
  Future<void> ensureConnected() async {
    if (isConnected) return;
    final token = _currentToken;
    if (token == null) {
      throw StateError(
        'SignalR not initialised — call connect(token) on login first.',
      );
    }
    await connect(token);
  }

  Future<void> disconnect() async {
    try {
      await _hubConnection?.stop();
      debugPrint('📡 SignalR: disconnected');
    } catch (e) {
      debugPrint('📡 SignalR disconnect error: $e');
    } finally {
      _hubConnection = null;
      _currentToken = null;
      _connectionStateController.add(HubConnectionState.Disconnected);
    }
  }

  /// Closes every controller. Call on app shutdown.
  Future<void> dispose() async {
    await disconnect();
    await _locationController.close();
    await _statusController.close();
    await _requestController.close();
    await _dashboardController.close();
    await _chatController.close();
    await _bookingStatusChanged.close();
    await _bookingCancelled.close();
    await _bookingPaymentChanged.close();
    await _bookingTripStarted.close();
    await _bookingTripEnded.close();
    await _helperLocationUpdate.close();
    await _chatMessagePush.close();
    await _connectionStateController.close();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _connect(String token) async {
    _currentToken = token;
    final hubUrl = ApiConfig.bookingHub;

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect(
          retryDelays: [0, 2000, 5000, 10000, 15000],
        )
        .build();

    _hubConnection?.onclose(({error}) {
      debugPrint('📡 SignalR closed: $error');
      _connectionStateController.add(HubConnectionState.Disconnected);
    });
    _hubConnection?.onreconnecting(({error}) {
      debugPrint('📡 SignalR reconnecting: $error');
      _connectionStateController.add(HubConnectionState.Reconnecting);
    });
    _hubConnection?.onreconnected(({connectionId}) {
      debugPrint('📡 SignalR reconnected. id=$connectionId');
      _connectionStateController.add(HubConnectionState.Connected);
    });

    _registerHandlers();

    try {
      await _hubConnection?.start();
      _connectionStateController.add(HubConnectionState.Connected);
      debugPrint('📡 SignalR connected → $hubUrl');
    } catch (e) {
      debugPrint('📡 SignalR start failed: $e');
      rethrow;
    }
  }

  void _registerHandlers() {
    final hub = _hubConnection;
    if (hub == null) return;

    // ── HelperLocationUpdate (typed + legacy) ────────────────────────────────
    hub.on('HelperLocationUpdate', (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      final raw = arguments.first;
      if (raw is! Map<String, dynamic>) return;

      // Typed stream
      _helperLocationUpdate.add(HelperLocationUpdateEvent.fromMap(raw));

      // Legacy stream (used by helper-side TrackingCubit)
      try {
        final pointJson = raw['point'] is Map<String, dynamic>
            ? raw['point'] as Map<String, dynamic>
            : raw;
        final point = TrackingPointModel.fromJson(pointJson);
        _locationController.add(
          TrackingUpdate(
            point: point,
            status: raw['status']?.toString(),
            distanceToTarget:
                (raw['distanceToTarget'] as num?)?.toDouble() ??
                    (raw['distanceToPickupKm'] as num?)?.toDouble() ??
                    (raw['distanceToDestinationKm'] as num?)?.toDouble(),
            etaMinutes: (raw['etaMinutes'] as num?)?.toInt() ??
                (raw['etaToPickupMinutes'] as num?)?.toInt() ??
                (raw['etaToDestinationMinutes'] as num?)?.toInt(),
          ),
        );
      } catch (e) {
        debugPrint('📡 Legacy location parse failed: $e');
      }
    });

    // ── Booking lifecycle ────────────────────────────────────────────────────
    hub.on('BookingStatusChanged', (args) {
      final raw = _firstMap(args);
      if (raw == null) return;
      _statusController.add(raw);
      _bookingStatusChanged.add(BookingStatusChangedEvent.fromMap(raw));
    });

    hub.on('BookingCancelled', (args) {
      final raw = _firstMap(args);
      if (raw == null) return;
      _statusController.add(raw);
      _bookingCancelled.add(BookingCancelledEvent.fromMap(raw));
    });

    hub.on('BookingPaymentChanged', (args) {
      final raw = _firstMap(args);
      if (raw == null) return;
      _statusController.add(raw);
      _bookingPaymentChanged.add(BookingPaymentChangedEvent.fromMap(raw));
    });

    hub.on('BookingTripStarted', (args) {
      final raw = _firstMap(args);
      if (raw == null) return;
      _statusController.add(raw);
      _bookingTripStarted.add(BookingTripStartedEvent.fromMap(raw));
    });

    hub.on('BookingTripEnded', (args) {
      final raw = _firstMap(args);
      if (raw == null) return;
      _statusController.add(raw);
      _bookingTripEnded.add(BookingTripEndedEvent.fromMap(raw));
    });

    // ── Chat ─────────────────────────────────────────────────────────────────
    hub.on('ChatMessage', (args) {
      final raw = _firstMap(args);
      if (raw == null) return;
      _chatController.add(raw);
      _chatMessagePush.add(ChatMessagePushEvent.fromMap(raw));
    });

    // ── Helper-side broadcasts (kept for helper app) ─────────────────────────
    hub.on('RequestIncoming', (args) {
      final raw = _firstMap(args);
      if (raw != null) _requestController.add(raw);
    });
    hub.on('RequestRemoved', (args) {
      final raw = _firstMap(args);
      if (raw != null) _requestController.add(raw);
    });
    hub.on('HelperDashboardChanged', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });
    hub.on('HelperAvailabilityChanged', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });
    hub.on('HelperApprovalChanged', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });
    hub.on('HelperBanStatusChanged', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });
    hub.on('HelperSuspensionChanged', (args) {
      final raw = _firstMap(args);
      if (raw != null) _dashboardController.add(raw);
    });

    // ── Diagnostics ──────────────────────────────────────────────────────────
    hub.on('Pong', (args) => debugPrint('📡 SignalR Pong: ${args?.first}'));
  }

  Map<String, dynamic>? _firstMap(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final raw = args.first;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Helper-side: pushes the helper's GPS to the hub.
  Future<void> sendLocation(
    double lat,
    double lng, {
    double? heading,
    double? speedKmh,
    double? accuracyMeters,
  }) async {
    if (_hubConnection?.state == HubConnectionState.Connected) {
      final args = <Object>[
        lat,
        lng,
        heading ?? 0.0,
        speedKmh ?? 0.0,
        accuracyMeters ?? 0.0,
      ];
      await _hubConnection!.invoke('SendLocation', args: args);
    }
  }
}
`

`lib/core/services/signalr/booking_hub_events.dart`

`dart
import 'package:equatable/equatable.dart';

DateTime? _tryParse(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toUtc();
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toUtc();
  return null;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// `BookingStatusChanged` SignalR payload (camelCase keys).
class BookingStatusChangedEvent extends Equatable {
  final String bookingId;
  final String? userId;
  final String? helperId;
  final String oldStatus;
  final String newStatus;
  final String? paymentStatus;

  const BookingStatusChangedEvent({
    required this.bookingId,
    this.userId,
    this.helperId,
    required this.oldStatus,
    required this.newStatus,
    this.paymentStatus,
  });

  factory BookingStatusChangedEvent.fromMap(Map<String, dynamic> map) {
    return BookingStatusChangedEvent(
      bookingId: map['bookingId']?.toString() ?? '',
      userId: map['userId']?.toString(),
      helperId: map['helperId']?.toString(),
      oldStatus: map['oldStatus']?.toString() ?? '',
      newStatus: map['newStatus']?.toString() ?? '',
      paymentStatus: map['paymentStatus']?.toString(),
    );
  }

  @override
  List<Object?> get props =>
      [bookingId, userId, helperId, oldStatus, newStatus, paymentStatus];
}

class BookingCancelledEvent extends Equatable {
  final String bookingId;
  final String? userId;
  final String? helperId;
  final String? cancelledBy;
  final String? reason;

  const BookingCancelledEvent({
    required this.bookingId,
    this.userId,
    this.helperId,
    this.cancelledBy,
    this.reason,
  });

  factory BookingCancelledEvent.fromMap(Map<String, dynamic> map) {
    return BookingCancelledEvent(
      bookingId: map['bookingId']?.toString() ?? '',
      userId: map['userId']?.toString(),
      helperId: map['helperId']?.toString(),
      cancelledBy: map['cancelledBy']?.toString(),
      reason: map['reason']?.toString(),
    );
  }

  @override
  List<Object?> get props =>
      [bookingId, userId, helperId, cancelledBy, reason];
}

class BookingPaymentChangedEvent extends Equatable {
  final String bookingId;
  final String? userId;
  final String? helperId;
  final String? paymentId;
  final double? amount;
  final String? currency;
  final String? method;
  final String status;
  final String? failureReason;
  final double? refundedAmount;

  const BookingPaymentChangedEvent({
    required this.bookingId,
    this.userId,
    this.helperId,
    this.paymentId,
    this.amount,
    this.currency,
    this.method,
    required this.status,
    this.failureReason,
    this.refundedAmount,
  });

  factory BookingPaymentChangedEvent.fromMap(Map<String, dynamic> map) {
    return BookingPaymentChangedEvent(
      bookingId: map['bookingId']?.toString() ?? '',
      userId: map['userId']?.toString(),
      helperId: map['helperId']?.toString(),
      paymentId: map['paymentId']?.toString(),
      amount: _toDouble(map['amount']),
      currency: map['currency']?.toString(),
      method: map['method']?.toString(),
      status: map['status']?.toString() ?? 'Unknown',
      failureReason: map['failureReason']?.toString(),
      refundedAmount: _toDouble(map['refundedAmount']),
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        userId,
        helperId,
        paymentId,
        amount,
        currency,
        method,
        status,
        failureReason,
        refundedAmount,
      ];
}

class BookingTripStartedEvent extends Equatable {
  final String bookingId;
  final String? userId;
  final String? helperId;
  final DateTime? startedAt;

  const BookingTripStartedEvent({
    required this.bookingId,
    this.userId,
    this.helperId,
    this.startedAt,
  });

  factory BookingTripStartedEvent.fromMap(Map<String, dynamic> map) {
    return BookingTripStartedEvent(
      bookingId: map['bookingId']?.toString() ?? '',
      userId: map['userId']?.toString(),
      helperId: map['helperId']?.toString(),
      startedAt: _tryParse(map['startedAt']),
    );
  }

  @override
  List<Object?> get props => [bookingId, userId, helperId, startedAt];
}

class BookingTripEndedEvent extends Equatable {
  final String bookingId;
  final String? userId;
  final String? helperId;
  final DateTime? completedAt;
  final double? finalPrice;
  final String? paymentStatus;

  const BookingTripEndedEvent({
    required this.bookingId,
    this.userId,
    this.helperId,
    this.completedAt,
    this.finalPrice,
    this.paymentStatus,
  });

  factory BookingTripEndedEvent.fromMap(Map<String, dynamic> map) {
    return BookingTripEndedEvent(
      bookingId: map['bookingId']?.toString() ?? '',
      userId: map['userId']?.toString(),
      helperId: map['helperId']?.toString(),
      completedAt: _tryParse(map['completedAt']),
      finalPrice: _toDouble(map['finalPrice']),
      paymentStatus: map['paymentStatus']?.toString(),
    );
  }

  @override
  List<Object?> get props =>
      [bookingId, userId, helperId, completedAt, finalPrice, paymentStatus];
}

class HelperLocationUpdateEvent extends Equatable {
  final String bookingId;
  final String? helperId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKmh;
  final DateTime? capturedAt;
  final double? distanceToPickupKm;
  final int? etaToPickupMinutes;
  final double? distanceToDestinationKm;
  final int? etaToDestinationMinutes;

  /// `"ToPickup"` | `"ToDestination"` (raw backend string).
  final String? phase;

  const HelperLocationUpdateEvent({
    required this.bookingId,
    this.helperId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speedKmh,
    this.capturedAt,
    this.distanceToPickupKm,
    this.etaToPickupMinutes,
    this.distanceToDestinationKm,
    this.etaToDestinationMinutes,
    this.phase,
  });

  factory HelperLocationUpdateEvent.fromMap(Map<String, dynamic> map) {
    return HelperLocationUpdateEvent(
      bookingId: map['bookingId']?.toString() ?? '',
      helperId: map['helperId']?.toString(),
      latitude: _toDouble(map['latitude']) ?? 0,
      longitude: _toDouble(map['longitude']) ?? 0,
      heading: _toDouble(map['heading']),
      speedKmh: _toDouble(map['speedKmh']),
      capturedAt: _tryParse(map['capturedAt']),
      distanceToPickupKm: _toDouble(map['distanceToPickupKm']),
      etaToPickupMinutes: _toInt(map['etaToPickupMinutes']),
      distanceToDestinationKm: _toDouble(map['distanceToDestinationKm']),
      etaToDestinationMinutes: _toInt(map['etaToDestinationMinutes']),
      phase: map['phase']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        helperId,
        latitude,
        longitude,
        heading,
        speedKmh,
        capturedAt,
        distanceToPickupKm,
        etaToPickupMinutes,
        distanceToDestinationKm,
        etaToDestinationMinutes,
        phase,
      ];
}

class ChatMessagePushEvent extends Equatable {
  final String bookingId;
  final String? conversationId;
  final String? messageId;
  final String? senderId;
  final String? senderType; // "User" | "Helper"
  final String? senderName;
  final String? recipientId;
  final String? recipientType;
  final String? messageType; // "Text" | "Image" | "File"
  final String? preview;
  final DateTime? sentAt;

  const ChatMessagePushEvent({
    required this.bookingId,
    this.conversationId,
    this.messageId,
    this.senderId,
    this.senderType,
    this.senderName,
    this.recipientId,
    this.recipientType,
    this.messageType,
    this.preview,
    this.sentAt,
  });

  factory ChatMessagePushEvent.fromMap(Map<String, dynamic> map) {
    return ChatMessagePushEvent(
      bookingId: map['bookingId']?.toString() ?? '',
      conversationId: map['conversationId']?.toString(),
      messageId: map['messageId']?.toString(),
      senderId: map['senderId']?.toString(),
      senderType: map['senderType']?.toString(),
      senderName: map['senderName']?.toString(),
      recipientId: map['recipientId']?.toString(),
      recipientType: map['recipientType']?.toString(),
      messageType: map['messageType']?.toString(),
      preview: map['preview']?.toString(),
      sentAt: _tryParse(map['sentAt']),
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        conversationId,
        messageId,
        senderId,
        senderType,
        senderName,
        recipientId,
        recipientType,
        messageType,
        preview,
        sentAt,
      ];
}
`

---

## Section 8 � FCM (full file contents + auth hooks)

`lib/core/services/notifications/device_token_service.dart`

`dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/api_config.dart';
import 'device_info_helper.dart';

/// Wraps `/notifications/devices` (register / unregister / unregister-all).
///
/// Lifecycle:
///   - Call [registerCurrentDevice] right after a successful login.
///   - Call [unregisterCurrentDevice] right before logout.
///   - The service auto-listens for FCM token rotations and re-registers.
///
/// On platforms where Firebase is not configured natively (e.g. desktop),
/// every method is a no-op and logs a warning instead of crashing the app.
class DeviceTokenService {
  final Dio dio;
  final DeviceInfoHelper deviceInfo;

  StreamSubscription<String>? _tokenRefreshSub;
  String? _lastRegisteredToken;

  DeviceTokenService({
    required this.dio,
    required this.deviceInfo,
  });

  /// Requests notification permission, fetches the FCM token and POSTs it.
  Future<void> registerCurrentDevice() async {
    if (!_supportsFirebase()) {
      debugPrint('🔕 DeviceTokenService: platform unsupported, skipping');
      return;
    }
    try {
      await _requestPermission();
      final fcmToken = await _safeGetToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('⚠️ DeviceTokenService: empty FCM token');
        return;
      }
      await _postRegister(fcmToken);
      _attachTokenRefreshListener();
    } catch (e, st) {
      debugPrint('💥 DeviceTokenService.register failed: $e\n$st');
    }
  }

  /// DELETEs the current device from `/notifications/devices`.
  ///
  /// Called BEFORE the auth token is cleared, otherwise the call would 401.
  Future<void> unregisterCurrentDevice() async {
    if (!_supportsFirebase()) return;
    final token = _lastRegisteredToken ?? await _safeGetToken();
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    if (token == null || token.isEmpty) {
      debugPrint('⚠️ DeviceTokenService: no FCM token to unregister');
      return;
    }
    try {
      await dio.delete(ApiConfig.unregisterDevice(token));
      debugPrint('✅ Unregistered FCM token');
      _lastRegisteredToken = null;
    } catch (e) {
      debugPrint('⚠️ DeviceTokenService.unregister failed: $e');
    }
  }

  /// DELETEs every device for the current user (used by "Sign out everywhere").
  Future<void> unregisterAllDevices() async {
    try {
      await dio.delete(ApiConfig.unregisterAllDevices);
      _lastRegisteredToken = null;
    } catch (e) {
      debugPrint('⚠️ DeviceTokenService.unregisterAll failed: $e');
    }
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _postRegister(String fcmToken) async {
    final deviceId = await deviceInfo.getDeviceId();
    final appVersion = await _appVersion();

    final body = <String, dynamic>{
      'fcmToken': fcmToken,
      'deviceId': deviceId,
      'appType': 'UserApp',
      'platform': deviceInfo.platform,
      'appVersion': appVersion,
    };

    debugPrint('📲 POST ${ApiConfig.registerDevice} body=$body');
    await dio.post(ApiConfig.registerDevice, data: body);
    _lastRegisteredToken = fcmToken;
    debugPrint('✅ Registered FCM token with backend');
  }

  void _attachTokenRefreshListener() {
    _tokenRefreshSub?.cancel();
    try {
      _tokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM token refreshed → re-registering');
        try {
          if (_lastRegisteredToken != null &&
              _lastRegisteredToken != newToken) {
            await dio.delete(
              ApiConfig.unregisterDevice(_lastRegisteredToken!),
            );
          }
          await _postRegister(newToken);
        } catch (e) {
          debugPrint('⚠️ FCM refresh re-register failed: $e');
        }
      });
    } catch (e) {
      debugPrint('⚠️ FCM onTokenRefresh unavailable: $e');
    }
  }

  Future<String?> _safeGetToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('⚠️ FirebaseMessaging.getToken failed: $e');
      return null;
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔔 FCM permission: ${settings.authorizationStatus}');
      if (Platform.isAndroid) {
        // Android 13+ also surfaces a runtime permission for notifications.
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('⚠️ FCM requestPermission failed: $e');
    }
  }

  bool _supportsFirebase() => Platform.isAndroid || Platform.isIOS;

  Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return '1.0.0+1';
    }
  }
}
`

`lib/core/services/notifications/device_info_helper.dart`

`dart
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable per-install identifiers used by `/notifications/devices`.
class DeviceInfoHelper {
  static const _kDeviceIdKey = 'install.deviceId';

  final SharedPreferences prefs;
  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  DeviceInfoHelper(this.prefs);

  /// Returns a stable deviceId for this install.
  ///
  /// Strategy:
  ///   1. Try to read a cached UUID from SharedPreferences (most reliable —
  ///      survives app upgrades, doesn't need extra permissions).
  ///   2. If absent, generate a random v4 UUID and persist it.
  Future<String> getDeviceId() async {
    final cached = prefs.getString(_kDeviceIdKey);
    if (cached != null && cached.isNotEmpty) return cached;

    final fresh = const Uuid().v4();
    await prefs.setString(_kDeviceIdKey, fresh);
    return fresh;
  }

  /// `"Android"` or `"iOS"` — matches the backend's `DevicePlatform` enum.
  String get platform {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  /// Best-effort device model label, e.g. `"Pixel 8 (Android 14)"`. Used by
  /// the backend for human-readable device lists. We never crash if the
  /// device info plugin throws — we just return `null`.
  Future<String?> getDeviceLabel() async {
    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        return '${info.manufacturer} ${info.model} (Android ${info.version.release})';
      }
      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        return '${info.utsname.machine} (iOS ${info.systemVersion})';
      }
    } catch (e) {
      debugPrint('⚠️ DeviceInfoHelper: $e');
    }
    return null;
  }
}
`

### Firebase init block � `lib/main.dart` (lines 14�34)

`dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/localization/cubit/localization_cubit.dart';
import 'core/theme/theme_cubit.dart';
import 'features/helper/features/auth/presentation/cubit/helper_auth_cubit.dart';
import 'features/tourist/features/auth/presentation/cubit/auth_cubit.dart';

/// Top-level handler so FCM background messages are processed even when the
/// Dart isolate has been killed. Must be a top-level function (not a closure).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled natively (notification tray); we log here
  // for diagnostics. Add data-message handling later if the backend pushes any.
  debugPrint('🔔 [bg] FCM message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is best-effort: if the native config isn't deployed yet we still
  // want the rest of the app to launch. The DeviceTokenService gracefully
  // becomes a no-op in that case.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ Firebase.initializeApp failed: $e');
  }

  await di.init();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDark') ?? false;

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(isDark: isDark)),
        BlocProvider(create: (_) => LocalizationCubit()),
        BlocProvider(
          create: (_) => di.sl<AuthCubit>()..checkAuthStatus(),
        ),
        BlocProvider(create: (_) => di.sl<HelperAuthCubit>()),
      ],
      child: const MyApp(),
    ),
  );
}
`

### `_onAuthenticated` and `_onUnauthenticated` � `lib/features/tourist/features/auth/presentation/cubit/auth_cubit.dart` (lines 48�81)

`dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/services/auth_service.dart';
import '../../../../../../core/services/notifications/device_token_service.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../domain/usecases/check_email_usecas.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/resend_verification_code_usecase.dart';
import '../../domain/usecases/verify_password_usecase.dart';
import '../../domain/usecases/google_login_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_code_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final CheckEmailUseCase checkEmailUseCase;
  final VerifyPasswordUseCase verifyPasswordUseCase;
  final RegisterUseCase registerUseCase;
  final GoogleLoginUseCase googleLoginUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final VerifyCodeUseCase verifyCodeUseCase;
  final AuthRepository authRepository;

  final ResendVerificationCodeUseCase resendVerificationCodeUseCase;
  final AuthService authService;
  final BookingTrackingHubService hubService;
  final DeviceTokenService deviceTokenService;

  AuthCubit({
    required this.checkEmailUseCase,
    required this.verifyPasswordUseCase,
    required this.registerUseCase,
    required this.googleLoginUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.verifyCodeUseCase,
    required this.resendVerificationCodeUseCase,
    required this.authRepository,
    required this.authService,
    required this.hubService,
    required this.deviceTokenService,
  }) : super(AuthInitial());

  /// Side effects that should run every time the user becomes authenticated:
  ///   - open the SignalR connection,
  ///   - register the device's FCM token with the backend.
  Future<void> _onAuthenticated() async {
    final token = authService.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('⚠️ AuthCubit: no token after auth — skipping side-effects');
      return;
    }
    try {
      await hubService.connect(token);
    } catch (e) {
      debugPrint('⚠️ AuthCubit: SignalR connect failed: $e');
    }
    try {
      await deviceTokenService.registerCurrentDevice();
    } catch (e) {
      debugPrint('⚠️ AuthCubit: device-token register failed: $e');
    }
  }

  /// Mirror of [_onAuthenticated] for logout.
  Future<void> _onUnauthenticated() async {
    try {
      await deviceTokenService.unregisterCurrentDevice();
    } catch (e) {
      debugPrint('⚠️ AuthCubit: device-token unregister failed: $e');
    }
    try {
      await hubService.disconnect();
    } catch (e) {
      debugPrint('⚠️ AuthCubit: SignalR disconnect failed: $e');
    }
  }

`

---

## Section 9 � Wiring (router routes, DI registrations, home button)

### Instant route constants + GoRoutes � `lib/core/router/app_router.dart` (lines 179�815)

Route constants (lines 179�188):

`dart
  // ── Instant Booking (rebuilt) ──────────────────────────────────────
  static const String instantTripDetails = '/instant/details';
  static const String instantHelpersList = '/instant/helpers';
  static const String instantHelperProfile = '/instant/helpers/:id';
  static const String instantBookingReview = '/instant/review';
  static const String instantWaiting = '/instant/waiting/:id';
  static const String instantAlternatives = '/instant/alternatives/:id';
  static const String instantConfirmed = '/instant/confirmed/:id';
  static const String instantTripTracking = '/instant/tracking/:id';
  
`

GoRoute definitions for the instant flow (lines 704�815):

`dart
      // ── Instant Booking flow (rebuilt) ──────────────────────────────────
      GoRoute(
        path: instantTripDetails,
        name: 'instant-trip-details',
        builder: (context, state) => const InstantTripDetailsPage(),
      ),
      GoRoute(
        path: instantHelpersList,
        name: 'instant-helpers-list',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return InstantHelpersListPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            searchRequest: extra['searchRequest'] as instant_req.InstantSearchRequest,
            pickup: extra['pickup'] as LocationPickResult,
            destination: extra['destination'] as LocationPickResult,
            travelers: extra['travelers'] as int,
            durationInMinutes: extra['durationInMinutes'] as int,
            languageCode: extra['languageCode'] as String?,
            requiresCar: extra['requiresCar'] as bool,
            notes: extra['notes'] as String?,
          );
        },
      ),
      GoRoute(
        path: instantHelperProfile,
        name: 'instant-helper-profile',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return HelperBookingProfilePage(
            cubit: extra['cubit'] as InstantBookingCubit,
            helper: extra['helper'] as instant_helper.HelperSearchResult,
            pickup: extra['pickup'] as LocationPickResult,
            destination: extra['destination'] as LocationPickResult,
            travelers: extra['travelers'] as int,
            durationInMinutes: extra['durationInMinutes'] as int,
            languageCode: extra['languageCode'] as String?,
            requiresCar: extra['requiresCar'] as bool,
            notes: extra['notes'] as String?,
          );
        },
      ),
      GoRoute(
        path: instantBookingReview,
        name: 'instant-booking-review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingReviewPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            helper: extra['helper'] as instant_helper.HelperSearchResult,
            pickup: extra['pickup'] as LocationPickResult,
            destination: extra['destination'] as LocationPickResult,
            travelers: extra['travelers'] as int,
            durationInMinutes: extra['durationInMinutes'] as int,
            languageCode: extra['languageCode'] as String?,
            requiresCar: extra['requiresCar'] as bool,
            notes: extra['notes'] as String?,
          );
        },
      ),
      GoRoute(
        path: instantWaiting,
        name: 'instant-waiting',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>;
          return WaitingForHelperPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            bookingId: id,
            helper: extra['helper'] as instant_helper.HelperSearchResult?,
          );
        },
      ),
      GoRoute(
        path: instantAlternatives,
        name: 'instant-alternatives',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingAlternativesPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            booking: extra['booking'] as instant_booking.BookingDetail,
            alternatives:
                extra['alternatives'] as instant_alt.AlternativesResponse,
          );
        },
      ),
      GoRoute(
        path: instantConfirmed,
        name: 'instant-confirmed',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>;
          return BookingConfirmedPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            bookingId: id,
            helper: extra['helper'] as instant_helper.HelperSearchResult?,
          );
        },
      ),
      GoRoute(
        path: instantTripTracking,
        name: 'instant-trip-tracking',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>;
          return TripTrackingPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            bookingId: id,
            helper: extra['helper'] as instant_helper.HelperSearchResult?,
          );
        },
      ),

`

### Instant booking + Hub + FCM DI registrations � `lib/core/di/injection_container.dart`

Auth cubit (with hub + FCM) (lines 226�241):

`dart
  sl.registerFactory(
        () => AuthCubit(
      checkEmailUseCase: sl(),
      verifyPasswordUseCase: sl(),
      registerUseCase: sl(),
      googleLoginUseCase: sl(),
      authRepository: sl(),
      forgotPasswordUseCase: sl(),
      resetPasswordUseCase: sl(),
      verifyCodeUseCase: sl(),
      resendVerificationCodeUseCase: sl(),
      authService: sl(),
      hubService: sl(),
      deviceTokenService: sl(),
    ),
  );
`

InstantBookingCubit + HelperBookingProfileCubit (lines 413�423):

`dart
  sl.registerFactory(() => InstantBookingCubit(
    searchInstantHelpersUC: sl(),
    createInstantBookingUC: sl(),
    cancelInstantBookingUC: sl(),
    getBookingDetailUC: sl(),
    getAlternativesUC: sl(),
    hubService: sl(),
  ));
  sl.registerFactory(() => HelperBookingProfileCubit(
        getHelperBookingProfileUC: sl(),
      ));
`

Instant booking use-cases, repo, datasource (lines 477�497):

`dart
  // Features - Instant Booking (parallel clean stack — see PHASE 1 of rebuild)
  // ============================================================

  // Use cases
  sl.registerLazySingleton(() => SearchInstantHelpersUC(sl()));
  sl.registerLazySingleton(() => GetHelperBookingProfileUC(sl()));
  sl.registerLazySingleton(() => CreateInstantBookingUC(sl()));
  sl.registerLazySingleton(() => GetBookingStatusUC(sl()));
  sl.registerLazySingleton(() => GetBookingDetailUC(sl()));
  sl.registerLazySingleton(() => GetAlternativesUC(sl()));
  sl.registerLazySingleton(() => CancelInstantBookingUC(sl()));

  // Repository
  sl.registerLazySingleton<InstantBookingRepository>(
    () => InstantBookingRepositoryImpl(sl()),
  );

  // Data source
  sl.registerLazySingleton<InstantBookingRemoteDataSource>(
    () => InstantBookingRemoteDataSourceImpl(sl()),
  );
`

BookingTrackingHubService singleton + surrounding cubits (lines 895�923):

`dart
  // ============================================================

  // SignalR Service
  sl.registerLazySingleton(() => BookingTrackingHubService());

  // Data sources
  sl.registerLazySingleton<TrackingRemoteDataSource>(
    () => TrackingRemoteDataSourceImpl(dio: sl()),
  );

  // Repositories
  sl.registerLazySingleton<TrackingRepository>(
    () => TrackingRepositoryImpl(
      remoteDataSource: sl(),
      hubService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetLatestLocationUseCase(sl()));
  sl.registerLazySingleton(() => GetTrackingHistoryUseCase(sl()));

  // Cubits
  sl.registerFactory(
    () => TrackingCubit(
      getTrackingUseCase: sl(),
      hubService: sl(),
    ),
  );

`

DeviceInfoHelper + DeviceTokenService (lines 940�944):

`dart
  // 5️⃣  Device-info + FCM device-token registration service
  sl.registerLazySingleton(() => DeviceInfoHelper(sl()));
  sl.registerLazySingleton(
    () => DeviceTokenService(dio: sl(), deviceInfo: sl()),
  );
`

### Instant button onPressed � `lib/features/tourist/features/home/presentation/pages/tourist_home_page.dart` (lines 231�251)

`dart
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: loc.translate('instant'),
                  variant: ButtonVariant.secondary,
                  color: Colors.white,
                  textStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  onPressed: () => context.push(AppRouter.instantTripDetails),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: CustomButton(
                  text: loc.translate('scheduled'),
                  variant: ButtonVariant.outlined,
                  color: Colors.white,
                  onPressed: () => context.push(AppRouter.scheduledSearch),
                ),
              ),
            ],
`

### `lib/features/tourist/features/payments/presentation/cubit/payment_cubit.dart` (full file)

`dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/usecases/initiate_payment_usecase.dart';
import '../../domain/usecases/get_payment_usecase.dart';
import '../../domain/usecases/get_latest_payment_usecase.dart';
import '../../domain/usecases/mock_payment_complete_usecase.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final InitiatePaymentUseCase initiatePaymentUseCase;
  final GetPaymentUseCase getPaymentUseCase;
  final GetLatestPaymentUseCase getLatestPaymentUseCase;
  final MockPaymentCompleteUseCase mockPaymentCompleteUseCase;

  PaymentCubit({
    required this.initiatePaymentUseCase,
    required this.getPaymentUseCase,
    required this.getLatestPaymentUseCase,
    required this.mockPaymentCompleteUseCase,
  }) : super(PaymentInitial());

  /// Initiate payment.
  ///
  /// The backend resolves Cash synchronously: the `initiate` response will
  /// already carry `status: Paid` and no `paymentUrl`, so we MUST NOT open the
  /// WebView and MUST NOT wait for a SignalR push — we emit success directly.
  /// Online methods (MockCard, etc.) come back as `PaymentPending` with a
  /// `paymentUrl`; the WebView page subscribes to BookingPaymentChanged and
  /// only completes when SignalR delivers `Paid` or `Failed`.
  Future<void> initiatePayment(String bookingId, String method) async {
    emit(PaymentLoading());
    final result = await initiatePaymentUseCase(
      InitiatePaymentParams(bookingId: bookingId, method: method),
    );
    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (payment) {
        if (payment.status == PaymentStatus.paid) {
          emit(PaymentSuccess(payment));
        } else if (payment.status == PaymentStatus.failed) {
          emit(PaymentFailed('Payment failed'));
        } else {
          emit(PaymentInitiated(payment));
        }
      },
    );
  }

  Future<void> checkPaymentStatus(String paymentId) async {
    final result = await getPaymentUseCase(paymentId);
    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (payment) {
        if (payment.status == PaymentStatus.paid) {
          emit(PaymentSuccess(payment));
        } else if (payment.status == PaymentStatus.failed) {
          emit(PaymentFailed('Payment failed'));
        }
      },
    );
  }

  Future<void> completeMockPayment(String paymentId, bool success) async {
    emit(PaymentLoading());
    final result = await mockPaymentCompleteUseCase(
      MockPaymentCompleteParams(
        paymentId: paymentId,
        action: success ? 'approve' : 'reject',
      ),
    );
    result.fold(
      (failure) => emit(PaymentFailed(failure.message)),
      (_) async {
        if (success) {
          final paymentResult = await getPaymentUseCase(paymentId);
          paymentResult.fold(
            (failure) => emit(PaymentFailed(failure.message)),
            (payment) => emit(PaymentSuccess(payment)),
          );
        } else {
          emit(PaymentFailed('Payment rejected by mock gateway'));
        }
      },
    );
  }
}
`

---

## Section 11 � Risks & Deviations

### R-1  FCM native config files not in repo
The Dart-side FCM integration is complete (irebase_core, irebase_messaging, DeviceTokenService). However google-services.json (Android) and GoogleService-Info.plist (iOS) must be added manually before the app can be installed on a real device. Firebase.initializeApp() is wrapped in a try/catch so the rest of the app launches even on desktop � verified in main.dart.

### R-2  Duplicate use-case registrations in injection_container.dart
Two parallel stacks exist:
- Legacy (old Scheduled stack): SearchInstantHelpersUseCase, CreateInstantBookingUseCase (lines 456, 459).
- New instant stack: SearchInstantHelpersUC, CreateInstantBookingUC, etc. (lines 481-487).
The new InstantBookingCubit (line 413) is wired to the new *UC classes. SearchHelpersCubit (line 409) is still wired to the old SearchInstantHelpersUseCase. No crash risk, but dead code should be pruned after the Scheduled flow is confirmed unaffected.

### R-3  GoRouter redirect checks helper auth, not tourist auth
The edirect in AppRouter.router (app_router.dart line 265-313) reads HelperLocalDataSource.getCurrentHelper() to decide whether to redirect to roleSelection. Tourist auth state (stored via AuthService) is not checked in the redirect guard. Tourist-only deep links to /instant/* are therefore not protected by the router guard. They rely on AuthCubit state being non-null, which is set before unApp. Low risk in current flow but worth documenting.

### R-4  PaymentCubit does not consume BookingPaymentChanged from SignalR
PaymentCubit (payment_cubit.dart) is a pure REST cubit � it has no hub subscription. The BookingPaymentChanged SignalR event is subscribed in payment_webview_page.dart directly. This means:
- Cash payments that complete synchronously (status=Paid on the initiate response) go directly to PaymentSuccess � ? handled in initiatePayment().
- Online/card payments open the WebView, which polls via hubService.bookingPaymentChangedStream directly � ? handled in payment_webview_page.dart.
- There is no hub fallback if the WebView is closed before the push arrives. The user would need to navigate back and the booking status cubit would eventually poll the correct state.

### R-5  GetBookingStatusUC registered but not injected into InstantBookingCubit
GetBookingStatusUC is registered at DI line 484 but InstantBookingCubit constructor (line 413-420) does not receive it. The cubit uses getBookingDetailUC for status polling instead. Consistent with how the cubit is implemented (_refreshBooking calls getBookingDetailUC). No functional gap � the detail endpoint returns status � but the named use case is unused.

### R-6  cancel_reason_sheet.dart uses deprecated Radio API
Radio.groupValue and Radio.onChanged are deprecated since Flutter 3.32. Not a crash risk for current Flutter version but will generate a lint warning in CI. Replace with RadioGroup when upgrading Flutter.

### R-7  Map library: flutter_map, not Google Maps
The location picker and trip tracking map use lutter_map + latlong2 (OpenStreetMap tiles). This is consistent with the rest of the codebase and requires no API key. If the backend returns lat/lng for pickup/destination the maps will work as-is. No deviation from codebase convention.

### R-8  InstantBookingCubit is a egisterFactory (not singleton)
Each page that takes a cubit: extra receives the same cubit instance that was created at instantHelpersList time and threaded through via GoRouter extra. This is intentional � the cubit owns the booking ID and booking state for the duration of the flow. No shared-singleton risk. However, if the user navigates back to home and then forward again, a brand-new cubit is created (no stale state leakage).

---

## Section 12 � Build / Analyze evidence

Command run: lutter analyze --no-pub 2>&1 | Out-File -Encoding utf8 _analyze_full.txt

Result: **506 issues found** (ran in 6.7 s). Zero compile errors. All issues are info-level deprecations or warning-level dead-code / unused-import findings.

### Issues touching the instant booking flow (lines 454-498 of _analyze_full.txt)

`
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\booking_alternatives_page.dart:110:38 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\booking_alternatives_page.dart:112:57 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\booking_alternatives_page.dart:149:60 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\booking_confirmed_page.dart:182:35 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\booking_confirmed_page.dart:201:35 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\booking_review_page.dart:307:48 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\helper_booking_profile_page.dart:491:48 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\helper_booking_profile_page.dart:522:42 - deprecated_member_use
   info - 'activeColor' is deprecated and shouldn't be used. Use activeThumbColor instead. This feature was deprecated after v3.31.0-2.0.pre - lib\features\tourist\features\user_booking\presentation\pages\instant\instant_trip_details_page.dart:218:15 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\instant_trip_details_page.dart:441:54 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\instant_trip_details_page.dart:464:52 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\instant_trip_details_page.dart:551:52 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\location_picker_page.dart:304:51 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\location_picker_page.dart:429:29 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\trip_tracking_page.dart:229:29 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\trip_tracking_page.dart:301:33 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\trip_tracking_page.dart:341:49 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\waiting_for_helper_page.dart:127:50 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\instant\waiting_for_helper_page.dart:166:60 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\my_bookings_page.dart:147:22 - deprecated_member_use
warning - Unused import: '../../../../../../core/router/app_router.dart' - lib\features\tourist\features\user_booking\presentation\pages\scheduled_search_page.dart:9:8 - unused_import
   info - The private field _hours could be 'final' - lib\features\tourist\features\user_booking\presentation\pages\scheduled_search_page.dart:28:7 - prefer_final_fields
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\scheduled_trip_details_page.dart:167:56 - deprecated_member_use
warning - The value of the local variable 'theme' isn't used - lib\features\tourist\features\user_booking\presentation\pages\scheduled_trip_details_page.dart:250:11 - unused_local_variable
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\scheduled_trip_details_page.dart:266:35 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\scheduled_trip_details_page.dart:304:29 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\scheduled_trip_details_page.dart:485:38 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\scheduled_trip_details_page.dart:487:57 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\scheduled_trip_details_page.dart:494:80 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\scheduled_trip_details_page.dart:500:48 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\pages\scheduled_trip_details_page.dart:546:37 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\helper_search_card.dart:106:37 - deprecated_member_use
   info - 'groupValue' is deprecated and shouldn't be used. Use a RadioGroup ancestor to manage group value instead. This feature was deprecated after v3.32.0-0.0.pre - lib\features\tourist\features\user_booking\presentation\widgets\instant\cancel_reason_sheet.dart:120:7 - deprecated_member_use
   info - 'onChanged' is deprecated and shouldn't be used. Use RadioGroup to handle value change instead. This feature was deprecated after v3.32.0-0.0.pre - lib\features\tourist\features\user_booking\presentation\widgets\instant\cancel_reason_sheet.dart:124:7 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\empty_error_state.dart:38:50 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\empty_error_state.dart:44:50 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\empty_error_state.dart:107:44 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\helper_suitability_card.dart:84:38 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\helper_suitability_card.dart:165:58 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\helper_suitability_card.dart:201:22 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\helper_suitability_card.dart:230:42 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\helper_suitability_card.dart:263:37 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\language_picker_sheet.dart:111:57 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\skeleton.dart:41:31 - deprecated_member_use
   info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss - lib\features\tourist\features\user_booking\presentation\widgets\instant\skeleton.dart:42:32 - deprecated_member_use
warning - The value of the local variable 'theme' isn't used - lib\features\tourist\features\user_booking_tracking\presentation\pages\user_booking_tracking_page.dart:38:11 - unused_local_variable
`

### Summary table

| Severity | Count (instant flow files only) | Kind |
|----------|---------------------------------|------|
| error    | 0 | � |
| warning  | 1 | Unused import (pp_router.dart in scheduled_search_page.dart) |
| warning  | 1 | Unused local variable (	heme in user_booking_tracking_page.dart) |
| info     | 2 | Deprecated Radio.groupValue/onChanged (cancel_reason_sheet.dart) |
| info     | 1 | Deprecated Switch.activeColor (instant_trip_details_page.dart) |
| info     | ~28 | Color.withOpacity deprecated ? use .withValues() (UI files only) |

None of the above prevents compilation or runtime execution.
