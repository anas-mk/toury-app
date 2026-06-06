import '../../data/models/language_model.dart';

/// Placeholder languages shown when the API returns an empty list.
class StaticLanguages {
  StaticLanguages._();

  static const List<LanguageModel> samples = [
    LanguageModel(
      code: 'en',
      name: 'English',
      isVerified: true,
      isNative: false,
      isSelected: true,
      verificationStatus: 'Verified',
      canStartInterview: false,
      canRetake: false,
      level: 'B2',
      interviewAttempts: 1,
    ),
    LanguageModel(
      code: 'ar',
      name: 'Arabic',
      isVerified: false,
      isNative: true,
      isSelected: true,
      verificationStatus: 'Ready to verify',
      canStartInterview: true,
      canRetake: false,
      interviewAttempts: 0,
    ),
    LanguageModel(
      code: 'fr',
      name: 'French',
      isVerified: false,
      isNative: false,
      isSelected: true,
      verificationStatus: 'In progress',
      canStartInterview: false,
      canRetake: false,
      activeInterviewId: 'static-interview-1',
      interviewAttempts: 1,
    ),
  ];
}
