import 'package:equatable/equatable.dart';

class HelperReportEntity extends Equatable {
  final String reportId;
  final String reason;
  final String details;
  final bool isResolved;
  final String? resolutionNote;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const HelperReportEntity({
    required this.reportId,
    required this.reason,
    required this.details,
    required this.isResolved,
    this.resolutionNote,
    required this.createdAt,
    this.resolvedAt,
  });

  @override
  List<Object?> get props => [
        reportId,
        reason,
        details,
        isResolved,
        resolutionNote,
        createdAt,
        resolvedAt,
      ];
}
