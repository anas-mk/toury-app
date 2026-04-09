class HelperLoginResponseModel {
  final String message;
  final bool requiresOtp;
  final String action;

  HelperLoginResponseModel({
    required this.message,
    required this.requiresOtp,
    required this.action,
  });

  factory HelperLoginResponseModel.fromJson(Map<String, dynamic> json) {
    return HelperLoginResponseModel(
      message: json['message'] ?? '',
      requiresOtp: json['requiresOtp'] as bool? ?? false,
      action: json['action'] ?? '',
    );
  }
}
