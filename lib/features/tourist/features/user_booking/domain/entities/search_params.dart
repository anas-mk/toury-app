import 'package:equatable/equatable.dart';

class ScheduledSearchParams extends Equatable {
  final String destinationCity;
  final DateTime requestedDate;
  final String startTime;
  final int durationInMinutes;
  final String requestedLanguage;
  final bool requiresCar;
  final int travelersCount;

  const ScheduledSearchParams({
    required this.destinationCity,
    required this.requestedDate,
    required this.startTime,
    required this.durationInMinutes,
    required this.requestedLanguage,
    required this.requiresCar,
    required this.travelersCount,
  });

  @override
  List<Object?> get props => [
        destinationCity,
        requestedDate,
        startTime,
        durationInMinutes,
        requestedLanguage,
        requiresCar,
        travelersCount,
      ];

  Map<String, dynamic> toJson() => {
        'destinationCity': destinationCity,
        'requestedDate': requestedDate.toIso8601String(),
        'startTime': startTime,
        'durationInMinutes': durationInMinutes,
        'requestedLanguage': requestedLanguage,
        'requiresCar': requiresCar,
        'travelersCount': travelersCount,
      };
}

class InstantSearchParams extends Equatable {
  final String pickupLocationName;
  final double pickupLatitude;
  final double pickupLongitude;
  final int durationInMinutes;
  final String requestedLanguage;
  final bool requiresCar;
  final int travelersCount;

  const InstantSearchParams({
    required this.pickupLocationName,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.durationInMinutes,
    required this.requestedLanguage,
    required this.requiresCar,
    required this.travelersCount,
  });

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

  Map<String, dynamic> toJson() => {
        'pickupLocationName': pickupLocationName,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'durationInMinutes': durationInMinutes,
        'requestedLanguage': requestedLanguage,
        'requiresCar': requiresCar,
        'travelersCount': travelersCount,
      };
}
