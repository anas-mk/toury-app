import '../../domain/entities/helper_profile_entity.dart';
import 'car_model.dart';
import 'certificate_model.dart';

/// Data model for the full Helper profile.
/// Extends [HelperProfileEntity] — the UI and domain layers only ever see
/// the [HelperProfileEntity] type. This model owns JSON serialisation.
class HelperProfileModel extends HelperProfileEntity {
  const HelperProfileModel({
    required super.helperId,
    required super.fullName,
    required super.email,
    required super.phoneNumber,
    required super.gender,
    super.birthDate,
    super.profileImageUrl,
    super.selfieImageUrl,
    required super.onboardingStatus,
    required super.isApproved,
    required super.isActive,
    super.car,
    required super.certificates,
  });

  factory HelperProfileModel.fromJson(Map<String, dynamic> json) {
    // Support both flat responses and {data: {...}} wrapped responses.
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final carJson = data['car'] as Map<String, dynamic>?;
    final certificatesJson =
        (data['certificates'] as List<dynamic>?) ?? <dynamic>[];

    return HelperProfileModel(
      helperId: data['helperId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      birthDate: data['birthDate'] != null
          ? DateTime.tryParse(data['birthDate'] as String)
          : null,
      profileImageUrl: data['profileImageUrl'] as String?,
      selfieImageUrl: data['selfieImageUrl'] as String?,
      onboardingStatus: data['onboardingStatus'] as String? ?? '',
      isApproved: data['isApproved'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? false,
      car: carJson != null ? CarModel.fromJson(carJson) : null,
      certificates: certificatesJson
          .map((c) => CertificateModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'helperId': helperId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
      'selfieImageUrl': selfieImageUrl,
      'onboardingStatus': onboardingStatus,
      'isApproved': isApproved,
      'isActive': isActive,
      'car': car != null ? (car as CarModel).toJson() : null,
      'certificates': certificates
          .map((c) => (c as CertificateModel).toJson())
          .toList(),
    };
  }
}
