class HelperAuthResponse {
  final String message;
  final String action;
  final String? token;
  final String? helperId;
  final String? email;
  final String? fullName;
  final String? onboardingStatus;
  final bool? isApproved;
  final bool? isActive;

  HelperAuthResponse({
    required this.message,
    required this.action,
    this.token,
    this.helperId,
    this.email,
    this.fullName,
    this.onboardingStatus,
    this.isApproved,
    this.isActive,
  });

  factory HelperAuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return HelperAuthResponse(
      message: json['message'] ?? '',
      action: json['action'] ?? '',
      token: data['token'] as String?,
      helperId: data['helperId'] as String?,
      email: data['email'] as String?,
      fullName: data['fullName'] as String?,
      onboardingStatus: data['onboardingStatus'] as String?,
      isApproved: data['isApproved'] as bool?,
      isActive: data['isActive'] as bool?,
    );
  }
}
