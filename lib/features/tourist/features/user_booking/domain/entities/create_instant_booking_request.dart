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
