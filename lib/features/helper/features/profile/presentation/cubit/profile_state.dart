import 'package:equatable/equatable.dart';
import '../../domain/entities/car_entity.dart';
import '../../domain/entities/certificate_entity.dart';
import '../../domain/entities/helper_profile_entity.dart';
import '../../domain/entities/helper_status_entity.dart';
import '../../domain/entities/helper_eligibility_entity.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  uploadingImage,
  uploadingSelfie,
  uploadingDocuments,
  managingCar,
  managingCertificate,
  success,
  error,
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final HelperProfileEntity? profile;
  final HelperStatusEntity? statusRecord;
  final HelperEligibilityEntity? eligibilityRecord;
  final String? errorMessage;

  /// Granular success feedback so the UI knows which action just completed.
  final String? successMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.statusRecord,
    this.eligibilityRecord,
    this.errorMessage,
    this.successMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    HelperProfileEntity? profile,
    HelperStatusEntity? statusRecord,
    HelperEligibilityEntity? eligibilityRecord,
    String? errorMessage,
    String? successMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      statusRecord: statusRecord ?? this.statusRecord,
      eligibilityRecord: eligibilityRecord ?? this.eligibilityRecord,
      // Explicitly null-able — pass null to clear messages.
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  // ── Convenience getters ────────────────────────────────────────────────────

  bool get isLoading =>
      status == ProfileStatus.loading ||
      status == ProfileStatus.updating ||
      status == ProfileStatus.uploadingImage ||
      status == ProfileStatus.uploadingSelfie ||
      status == ProfileStatus.uploadingDocuments ||
      status == ProfileStatus.managingCar ||
      status == ProfileStatus.managingCertificate;

  CarEntity? get car => profile?.car;
  List<CertificateEntity> get certificates => profile?.certificates ?? [];

  @override
  List<Object?> get props => [
        status,
        profile,
        statusRecord,
        eligibilityRecord,
        errorMessage,
        successMessage,
      ];
}
