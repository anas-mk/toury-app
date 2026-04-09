import 'helper_model.dart';

class HelperAuthResponseModel {
  final String message;
  final String action;
  final HelperModel? data;

  HelperAuthResponseModel({
    required this.message,
    required this.action,
    this.data,
  });

  factory HelperAuthResponseModel.fromJson(Map<String, dynamic> json) {
    return HelperAuthResponseModel(
      message: json['message'] ?? '',
      action: json['action'] ?? '',
      data: json['data'] != null ? HelperModel.fromJson(json['data']) : null,
    );
  }
}
