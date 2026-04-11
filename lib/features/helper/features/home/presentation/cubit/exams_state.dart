import 'package:equatable/equatable.dart';

import '../../../language_interview/data/models/interview_model.dart';
import '../../../language_interview/data/models/language_model.dart';

enum ExamsStatus {
  initial,
  loading,
  languagesLoaded,
  startInterviewLoading,
  interviewStarted,
  interviewLoaded,
  preInterview,
  recording,
  reviewing,
  answerSubmitting,
  interviewSubmitting,
  success,
  error,
}

class ExamsState extends Equatable {
  final ExamsStatus status;
  final List<LanguageModel> languages;
  final InterviewModel? interview;
  final String? errorMessage;
  final int currentQuestionIndex;
  final int attemptsLeft;
  final bool isRecording;
  final int recordingDuration;
  final String? completedPreInterviewId;
  final bool isNavigating;

  /// Global post-submit lock.
  /// Once true, ALL flows are blocked:
  ///   - navigation to pre-interview / interview
  ///   - CameraService initialization requests from screens
  ///   - auto-resume from activeInterviewId
  /// Reset ONLY when user starts a NEW interview after cooldown.
  final bool isInterviewLocked;

  const ExamsState({
    this.status = ExamsStatus.initial,
    this.languages = const [],
    this.interview,
    this.errorMessage,
    this.currentQuestionIndex = 0,
    this.attemptsLeft = 2,
    this.isRecording = false,
    this.recordingDuration = 0,
    this.completedPreInterviewId,
    this.isNavigating = false,
    this.isInterviewLocked = false,
  });

  ExamsState copyWith({
    ExamsStatus? status,
    List<LanguageModel>? languages,
    InterviewModel? interview,
    String? errorMessage,
    int? currentQuestionIndex,
    int? attemptsLeft,
    bool? isRecording,
    int? recordingDuration,
    String? completedPreInterviewId,
    bool? isNavigating,
    bool? isInterviewLocked,
  }) {
    return ExamsState(
      status: status ?? this.status,
      languages: languages ?? this.languages,
      interview: interview ?? this.interview,
      errorMessage: errorMessage ?? this.errorMessage,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      completedPreInterviewId: completedPreInterviewId ?? this.completedPreInterviewId,
      isNavigating: isNavigating ?? this.isNavigating,
      isInterviewLocked: isInterviewLocked ?? this.isInterviewLocked,
    );
  }

  @override
  List<Object?> get props => [
        status,
        languages,
        interview,
        errorMessage,
        currentQuestionIndex,
        attemptsLeft,
        isRecording,
        recordingDuration,
        completedPreInterviewId,
        isNavigating,
        isInterviewLocked,
      ];
}
