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
