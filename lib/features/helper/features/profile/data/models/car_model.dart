import '../../domain/entities/car_entity.dart';

/// Data model for a helper's car.
/// Extends [CarEntity] to enforce the Data → Domain mapping pattern.
/// The UI and domain layers always work with [CarEntity].
class CarModel extends CarEntity {
  const CarModel({
    super.carId,
    required super.brand,
    required super.model,
    required super.color,
    required super.licensePlate,
    required super.energyType,
    required super.carType,
    super.carLicenseFrontUrl,
    super.carLicenseBackUrl,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      carId: json['carId'] as String?,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String? ?? '',
      licensePlate: json['licensePlate'] as String? ?? '',
      energyType: json['energyType'] as String? ?? '',
      carType: json['carType'] as String? ?? '',
      carLicenseFrontUrl: json['carLicenseFrontUrl'] as String?,
      carLicenseBackUrl: json['carLicenseBackUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carId': carId,
      'brand': brand,
      'model': model,
      'color': color,
      'licensePlate': licensePlate,
      'energyType': energyType,
      'carType': carType,
      'carLicenseFrontUrl': carLicenseFrontUrl,
      'carLicenseBackUrl': carLicenseBackUrl,
    };
  }
}
