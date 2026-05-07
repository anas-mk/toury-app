import 'package:equatable/equatable.dart';

class ScheduledSearchParams extends Equatable {
  final String destinationCity;
  final String destinationName;
  final DateTime requestedDate;
  final String startTime;
  final int durationInMinutes;
  final String requestedLanguage;
  final bool requiresCar;
  final int travelersCount;

  // Required by both search and create endpoints.
  final double destinationLatitude;
  final double destinationLongitude;

  // Pickup is required — user must provide before searching (GPS default).
  final String pickupLocationName;
  final double pickupLatitude;
  final double pickupLongitude;

  // Optional filters for Phase 2
  final String? sortBy;
  final String? sortOrder;
  final double? minRating;
  final double? maxPrice;
  final String? helperGender;

  const ScheduledSearchParams({
    required this.destinationCity,
    required this.destinationName,
    required this.requestedDate,
    required this.startTime,
    required this.durationInMinutes,
    required this.requestedLanguage,
    required this.requiresCar,
    required this.travelersCount,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.pickupLocationName,
    required this.pickupLatitude,
    required this.pickupLongitude,
    this.sortBy,
    this.sortOrder,
    this.helperGender,
    this.minRating,
    this.maxPrice,
  });

  @override
  List<Object?> get props => [
        destinationCity,
        destinationName,
        requestedDate,
        startTime,
        durationInMinutes,
        requestedLanguage,
        requiresCar,
        travelersCount,
        destinationLatitude,
        destinationLongitude,
        pickupLocationName,
        pickupLatitude,
        pickupLongitude,
        sortBy,
        sortOrder,
        minRating,
        maxPrice,
        helperGender,
      ];

  Map<String, dynamic> toJson() => {
        'destinationCity': destinationCity,
        'destinationName': destinationName,
        'requestedDate': requestedDate.toIso8601String(),
        'startTime': startTime,
        'durationInMinutes': durationInMinutes,
        'requestedLanguage': requestedLanguage,
        'requiresCar': requiresCar,
        'travelersCount': travelersCount,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
        'pickupLocationName': pickupLocationName,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
        if (minRating != null) 'minRating': minRating,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (helperGender != null) 'helperGender': helperGender,
      };

  ScheduledSearchParams copyWith({
    String? sortBy,
    String? sortOrder,
    double? minRating,
    double? maxPrice,
    String? helperGender,
  }) {
    return ScheduledSearchParams(
      destinationCity: destinationCity,
      destinationName: destinationName,
      requestedDate: requestedDate,
      startTime: startTime,
      durationInMinutes: durationInMinutes,
      requestedLanguage: requestedLanguage,
      requiresCar: requiresCar,
      travelersCount: travelersCount,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
      pickupLocationName: pickupLocationName,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      minRating: minRating ?? this.minRating,
      maxPrice: maxPrice ?? this.maxPrice,
      helperGender: helperGender ?? this.helperGender,
    );
  }
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
