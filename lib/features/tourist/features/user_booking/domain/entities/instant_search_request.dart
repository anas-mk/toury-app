import 'package:equatable/equatable.dart';

/// Request body for `POST /user/bookings/instant/search`.
class InstantSearchRequest extends Equatable {
  final String pickupLocationName;
  final String destinationName;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double pickupLatitude;
  final double pickupLongitude;
  final int durationInMinutes;
  final String? requestedLanguage;
  final bool requiresCar;
  final int travelersCount;

  const InstantSearchRequest({
    required this.pickupLocationName,
    required this.destinationName,
    this.destinationLatitude,
    this.destinationLongitude,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.durationInMinutes,
    this.requestedLanguage,
    this.requiresCar = false,
    this.travelersCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'pickupLocationName': pickupLocationName,
        'destinationName': destinationName,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
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
        destinationName,
        destinationLatitude,
        destinationLongitude,
        pickupLatitude,
        pickupLongitude,
        durationInMinutes,
        requestedLanguage,
        requiresCar,
        travelersCount,
      ];
}
