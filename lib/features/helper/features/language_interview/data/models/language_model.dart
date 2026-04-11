import 'package:equatable/equatable.dart';

class LanguageModel extends Equatable {
  final String code;
  final String name;
  final bool isVerified;
  final bool isNative;
  final bool isSelected;
  final String? verificationStatus;
  final bool canStartInterview;
  final bool canRetake;
  final String? nextEligibleTestAt;
  final String? activeInterviewId;
  final String? level;
  final int interviewAttempts;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.isVerified,
    required this.isNative,
    required this.isSelected,
    this.verificationStatus,
    required this.canStartInterview,
    required this.canRetake,
    this.nextEligibleTestAt,
    this.activeInterviewId,
    this.level,
    required this.interviewAttempts,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      isVerified: json['isVerified'] ?? false,
      isNative: json['isNative'] ?? false,
      isSelected: json['isSelected'] ?? false,
      verificationStatus: json['verificationStatus'],
      canStartInterview: json['canStartInterview'] ?? false,
      canRetake: json['canRetake'] ?? false,
      nextEligibleTestAt: json['nextEligibleTestAt'],
      activeInterviewId: json['activeInterviewId'],
      level: json['level'],
      interviewAttempts: json['interviewAttempts'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'isVerified': isVerified,
      'isNative': isNative,
      'isSelected': isSelected,
      'verificationStatus': verificationStatus,
      'canStartInterview': canStartInterview,
      'canRetake': canRetake,
      'nextEligibleTestAt': nextEligibleTestAt,
      'activeInterviewId': activeInterviewId,
      'level': level,
      'interviewAttempts': interviewAttempts,
    };
  }

  @override
  List<Object?> get props => [
        code,
        name,
        isVerified,
        isNative,
        isSelected,
        verificationStatus,
        canStartInterview,
        canRetake,
        nextEligibleTestAt,
        activeInterviewId,
        level,
        interviewAttempts,
      ];
}
