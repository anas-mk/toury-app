import 'package:equatable/equatable.dart';
import 'car_entity.dart';
import 'certificate_entity.dart';

/// Domain entity representing the Helper's full profile.
/// Free of any data-layer (JSON) concerns.
class HelperProfileEntity extends Equatable {
  final String helperId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String gender;
  final DateTime? birthDate;
  final String? profileImageUrl;
  final String? selfieImageUrl;
  final String onboardingStatus;
  final bool isApproved;
  final bool isActive;
  final CarEntity? car;
  final List<CertificateEntity> certificates;

  const HelperProfileEntity({
    required this.helperId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    this.birthDate,
    this.profileImageUrl,
    this.selfieImageUrl,
    required this.onboardingStatus,
    required this.isApproved,
    required this.isActive,
    this.car,
    required this.certificates,
  });

  @override
  List<Object?> get props => [
        helperId,
        fullName,
        email,
        phoneNumber,
        gender,
        birthDate,
        profileImageUrl,
        selfieImageUrl,
        onboardingStatus,
        isApproved,
        isActive,
        car,
        certificates,
      ];
}
