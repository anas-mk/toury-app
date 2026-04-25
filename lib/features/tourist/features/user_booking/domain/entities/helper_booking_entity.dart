import 'package:equatable/equatable.dart';

class HelperBookingEntity extends Equatable {
  final String id;
  final String name;
  final String? profileImageUrl;
  final double rating;
  final int tripsCount;
  final String? bio;
  final List<String> languages;
  final List<String>? certificates;
  final CarEntity? car;
  final String responseSpeed;
  final double acceptanceRate;
  final int age;
  final String gender;
  final String experience;
  final List<String> serviceAreas;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;

  const HelperBookingEntity({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.rating,
    required this.tripsCount,
    this.bio,
    required this.languages,
    this.certificates,
    this.car,
    required this.responseSpeed,
    required this.acceptanceRate,
    required this.age,
    required this.gender,
    required this.experience,
    required this.serviceAreas,
    this.latitude,
    this.longitude,
    this.isAvailable = true,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        profileImageUrl,
        rating,
        tripsCount,
        bio,
        languages,
        certificates,
        car,
        responseSpeed,
        acceptanceRate,
        age,
        gender,
        experience,
        serviceAreas,
        latitude,
        longitude,
        isAvailable,
      ];
}

class CarEntity extends Equatable {
  final String model;
  final String color;
  final String plateNumber;
  final int year;

  const CarEntity({
    required this.model,
    required this.color,
    required this.plateNumber,
    required this.year,
  });

  @override
  List<Object?> get props => [model, color, plateNumber, year];
}
