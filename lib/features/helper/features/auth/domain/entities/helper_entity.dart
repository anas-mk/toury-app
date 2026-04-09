import 'package:equatable/equatable.dart';

class HelperEntity extends Equatable {
  final String helperId;
  final String email;
  final String fullName;
  final String onboardingStatus;
  final bool isApproved;
  final bool isActive;
  final String? token;

  const HelperEntity({
    required this.helperId,
    required this.email,
    required this.fullName,
    required this.onboardingStatus,
    required this.isApproved,
    required this.isActive,
    this.token,
  });

  @override
  List<Object?> get props => [
        helperId,
        email,
        fullName,
        onboardingStatus,
        isApproved,
        isActive,
        token,
      ];
}
