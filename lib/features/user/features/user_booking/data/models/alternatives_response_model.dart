import '../../domain/entities/alternatives_response.dart';
import 'helper_search_result_model.dart';
import 'json_helpers.dart';

class AssignmentAttemptModel extends AssignmentAttempt {
  const AssignmentAttemptModel({
    required super.attemptOrder,
    required super.helperName,
    required super.responseStatus,
    super.sentAt,
    super.respondedAt,
  });

  factory AssignmentAttemptModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAttemptModel(
      attemptOrder: parseInt(json['attemptOrder']),
      helperName: json['helperName']?.toString() ?? '',
      responseStatus: json['responseStatus']?.toString() ?? 'Unknown',
      sentAt: tryParseUtc(json['sentAt']),
      respondedAt: tryParseUtc(json['respondedAt']),
    );
  }
}

class AlternativesResponseModel extends AlternativesResponse {
  const AlternativesResponseModel({
    required super.bookingId,
    required super.status,
    required super.message,
    required super.autoRetryActive,
    required super.attemptsMade,
    required super.maxAttempts,
    required super.alternativeHelpers,
    required super.assignmentHistory,
  });

  factory AlternativesResponseModel.fromJson(Map<String, dynamic> json) {
    return AlternativesResponseModel(
      bookingId: json['bookingId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      message: json['message']?.toString() ?? '',
      autoRetryActive: parseBool(json['autoRetryActive']),
      attemptsMade: parseInt(json['attemptsMade']),
      maxAttempts: parseInt(json['maxAttempts']),
      alternativeHelpers: (json['alternativeHelpers'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(HelperSearchResultModel.fromJson)
              .toList() ??
          const [],
      assignmentHistory: (json['assignmentHistory'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AssignmentAttemptModel.fromJson)
              .toList() ??
          const [],
    );
  }
}
