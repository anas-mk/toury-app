import 'package:equatable/equatable.dart';

class HelperStatusEntity extends Equatable {
  final bool onboardingComplete;
  final bool canSubmitForAdminReview;
  final bool isApproved;
  final bool isActive;
  final String approvalStatus;

  const HelperStatusEntity({
    required this.onboardingComplete,
    required this.canSubmitForAdminReview,
    required this.isApproved,
    required this.isActive,
    required this.approvalStatus,
  });

  @override
  List<Object?> get props => [
        onboardingComplete,
        canSubmitForAdminReview,
        isApproved,
        isActive,
        approvalStatus,
      ];
}
