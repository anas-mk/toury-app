import '../../domain/entities/helper_report_entities.dart';

class HelperReportModel extends HelperReportEntity {
  const HelperReportModel({
    required super.reportId,
    required super.reason,
    required super.details,
    required super.isResolved,
    super.resolutionNote,
    required super.createdAt,
    super.resolvedAt,
  });

  factory HelperReportModel.fromJson(Map<String, dynamic> json) {
    return HelperReportModel(
      reportId: json['reportId'] ?? '',
      reason: json['reason'] ?? '',
      details: json['details'] ?? '',
      isResolved: json['isResolved'] ?? false,
      resolutionNote: json['resolutionNote'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'reason': reason,
      'details': details,
      'isResolved': isResolved,
      'resolutionNote': resolutionNote,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}
