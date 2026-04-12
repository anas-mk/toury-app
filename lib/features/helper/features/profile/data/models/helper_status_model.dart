import '../../domain/entities/helper_status_entity.dart';

class HelperStatusModel extends HelperStatusEntity {
  const HelperStatusModel({
    required super.onboardingComplete,
    required super.canSubmitForAdminReview,
    required super.isApproved,
    required super.isActive,
    required super.approvalStatus,
  });

  factory HelperStatusModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return HelperStatusModel(
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
      canSubmitForAdminReview: data['canSubmitForAdminReview'] as bool? ?? false,
      isApproved: data['isApproved'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? false,
      approvalStatus: data['approvalStatus'] as String? ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'onboardingComplete': onboardingComplete,
      'canSubmitForAdminReview': canSubmitForAdminReview,
      'isApproved': isApproved,
      'isActive': isActive,
      'approvalStatus': approvalStatus,
    };
  }
}
