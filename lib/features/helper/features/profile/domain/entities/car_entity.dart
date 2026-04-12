import 'package:equatable/equatable.dart';

/// Domain entity representing the helper's vehicle.
class CarEntity extends Equatable {
  final String? carId;
  final String brand;
  final String model;
  final String color;
  final String licensePlate;
  final String energyType;
  final String carType;
  final String? carLicenseFrontUrl;
  final String? carLicenseBackUrl;

  const CarEntity({
    this.carId,
    required this.brand,
    required this.model,
    required this.color,
    required this.licensePlate,
    required this.energyType,
    required this.carType,
    this.carLicenseFrontUrl,
    this.carLicenseBackUrl,
  });

  @override
  List<Object?> get props => [
        carId,
        brand,
        model,
        color,
        licensePlate,
        energyType,
        carType,
        carLicenseFrontUrl,
        carLicenseBackUrl,
      ];
}
