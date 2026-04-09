import '../../domain/entities/helper_entity.dart';

class HelperModel extends HelperEntity {
  const HelperModel({
    required super.helperId,
    required super.email,
    required super.fullName,
    required super.onboardingStatus,
    required super.isApproved,
    required super.isActive,
    super.token,
  });

  factory HelperModel.fromJson(Map<String, dynamic> json) {
    // Handling potential nested data structure if needed, or flat if that's the API contract
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return HelperModel(
      token: json['token'] as String? ?? data['token'] as String?,
      helperId: data['helperId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      onboardingStatus: data['onboardingStatus'] as String? ?? '',
      isApproved: data['isApproved'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'helperId': helperId,
      'email': email,
      'fullName': fullName,
      'onboardingStatus': onboardingStatus,
      'isApproved': isApproved,
      'isActive': isActive,
    };
  }
}
