import 'package:equatable/equatable.dart';
import 'question_model.dart';

class InterviewModel extends Equatable {
  final String id;
  final String languageCode;
  final String languageName;
  final String status;
  final int totalQuestions;
  final int answeredCount;
  final String createdAt;
  final String? startedAt;
  final String? submittedAt;
  final String? reviewedAt;
  final String? rejectionReason;
  final List<QuestionModel> questions;

  const InterviewModel({
    required this.id,
    required this.languageCode,
    required this.languageName,
    required this.status,
    required this.totalQuestions,
    required this.answeredCount,
    required this.createdAt,
    this.startedAt,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    required this.questions,
  });

  factory InterviewModel.fromJson(Map<String, dynamic> json) {
    return InterviewModel(
      id: json['id'] ?? '',
      languageCode: json['languageCode'] ?? '',
      languageName: json['languageName'] ?? '',
      status: json['status'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      answeredCount: json['answeredCount'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      startedAt: json['startedAt'],
      submittedAt: json['submittedAt'],
      reviewedAt: json['reviewedAt'],
      rejectionReason: json['rejectionReason'],
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => QuestionModel.fromJson(q))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'languageCode': languageCode,
      'languageName': languageName,
      'status': status,
      'totalQuestions': totalQuestions,
      'answeredCount': answeredCount,
      'createdAt': createdAt,
      'startedAt': startedAt,
      'submittedAt': submittedAt,
      'reviewedAt': reviewedAt,
      'rejectionReason': rejectionReason,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  InterviewModel copyWith({
    String? id,
    String? languageCode,
    String? languageName,
    String? status,
    int? totalQuestions,
    int? answeredCount,
    String? createdAt,
    String? startedAt,
    String? submittedAt,
    String? reviewedAt,
    String? rejectionReason,
    List<QuestionModel>? questions,
  }) {
    return InterviewModel(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      languageName: languageName ?? this.languageName,
      status: status ?? this.status,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      answeredCount: answeredCount ?? this.answeredCount,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      questions: questions ?? this.questions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        languageCode,
        languageName,
        status,
        totalQuestions,
        answeredCount,
        createdAt,
        startedAt,
        submittedAt,
        reviewedAt,
        rejectionReason,
        questions,
      ];
}
