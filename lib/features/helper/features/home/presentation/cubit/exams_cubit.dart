import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../../../language_interview/domain/repositories/interview_repository.dart';
import '../../../language_interview/domain/usecases/get_interview_usecase.dart';
import '../../../language_interview/domain/usecases/get_languages_usecase.dart';
import '../../../language_interview/domain/usecases/start_interview_usecase.dart';
import '../../../language_interview/domain/usecases/submit_answer_usecase.dart';
import '../../../language_interview/domain/usecases/submit_interview_usecase.dart';
import 'exams_state.dart';

/// Blocked statuses — backend is source of truth.
const _blockedStatuses = ['ManualReviewRequired', 'Completed', 'Closed'];

class ExamsCubit extends Cubit<ExamsState> {
  final GetLanguagesUseCase getLanguagesUseCase;
  final StartInterviewUseCase startInterviewUseCase;
  final GetInterviewUseCase getInterviewUseCase;
  final SubmitAnswerUseCase submitAnswerUseCase;
  final SubmitInterviewUseCase submitInterviewUseCase;
  final InterviewRepository repository;
  final SharedPreferences sharedPreferences;

  static const String _activeInterviewKey = 'active_interview_id';

  /// Central token — cancelled on dispose or screen exit.
  CancelToken _cancelToken = CancelToken();

  /// Local navigation lock — prevents duplicate pushes inside async gaps.
  bool _isNavigating = false;

  /// Submission lock — prevents duplicate API calls during active upload.
  bool _isSubmitting = false;

  ExamsCubit({
    required this.getLanguagesUseCase,
    required this.startInterviewUseCase,
    required this.getInterviewUseCase,
    required this.submitAnswerUseCase,
    required this.submitInterviewUseCase,
    required this.repository,
    required this.sharedPreferences,
  }) : super(const ExamsState());

  @override
  Future<void> close() {
    _cancelToken.cancel('ExamsCubit closed');
    _isNavigating = false;
    _isSubmitting = false;
    return super.close();
  }

  /// Call before navigating away (e.g. back button, screen dispose).
  void cancelPendingRequests() {
    _cancelToken.cancel('Screen disposed');
    _cancelToken = CancelToken();
  }

  void _refreshToken() {
    if (_cancelToken.isCancelled) {
      _cancelToken = CancelToken();
    }
  }

  // ─── Initialization ──────────────────────────────────────────────────────────

  Future<void> getLanguages() async {
    _refreshToken();
    emit(state.copyWith(status: ExamsStatus.loading));
    final result = await getLanguagesUseCase(NoParams(), cancelToken: _cancelToken);
    result.fold(
      (failure) => emit(state.copyWith(status: ExamsStatus.error, errorMessage: failure.message)),
      (languages) {
        emit(state.copyWith(status: ExamsStatus.languagesLoaded, languages: languages));

        // │ POST-SUBMIT LOCK: If the interview is locked, treat backend state as
        // │ READ-ONLY. Never auto-resume from activeInterviewId after submission.
        if (state.isInterviewLocked) {
          return;
        }

        final cachedId = sharedPreferences.getString(_activeInterviewKey);
        if (cachedId != null) {
          loadInterview(cachedId);
        }
      },
    );
  }

  // ─── Interview Flow ───────────────────────────────────────────────────────────

  Future<void> startInterview(String code) async {
    // POST-SUBMIT LOCK: Block all new interview flows after submission
    if (state.isInterviewLocked) return;

    _refreshToken();
    emit(state.copyWith(status: ExamsStatus.startInterviewLoading));
    final result = await startInterviewUseCase(code, cancelToken: _cancelToken);

    result.fold(
      (failure) async {
        final lang = state.languages.firstWhere((l) => l.code == code);
        if (lang.activeInterviewId != null) {
          await loadInterview(lang.activeInterviewId!);
        } else {
          emit(state.copyWith(status: ExamsStatus.error, errorMessage: failure.message));
        }
      },
      (interview) async {
        await _cacheInterviewId(interview.id);
        emit(state.copyWith(
          status: ExamsStatus.interviewStarted,
          interview: interview,
          currentQuestionIndex: 0,
        ));
      },
    );
  }

  Future<void> loadInterview(String id) async {
    // POST-SUBMIT LOCK: Ignore activeInterviewId-based resume after submission
    if (state.isInterviewLocked) return;

    _refreshToken();
    emit(state.copyWith(status: ExamsStatus.loading));
    final result = await getInterviewUseCase(id, cancelToken: _cancelToken);
    result.fold(
      (failure) => emit(state.copyWith(status: ExamsStatus.error, errorMessage: failure.message)),
      (interview) {
        emit(state.copyWith(
          status: ExamsStatus.interviewLoaded,
          interview: interview,
          currentQuestionIndex: _findFirstUnanswered(interview),
        ));
      },
    );
  }

  int _findFirstUnanswered(dynamic interview) {
    for (var q in interview.questions) {
      if (!q.isAnswered) return q.index;
    }
    return 0;
  }

  // ─── Question Navigation ──────────────────────────────────────────────────────

  void setQuestionIndex(int index) {
    if (index >= 0 && index < (state.interview?.totalQuestions ?? 0)) {
      emit(state.copyWith(
        currentQuestionIndex: index,
        attemptsLeft: 2,
        status: ExamsStatus.interviewLoaded,
      ));
    }
  }

  void nextQuestion() => setQuestionIndex(state.currentQuestionIndex + 1);
  void previousQuestion() => setQuestionIndex(state.currentQuestionIndex - 1);

  // ─── Recording State (UI signals only — hardware managed by CameraService) ───

  void startRecording() {
    // POST-SUBMIT LOCK: Block hardware engagement after submission
    if (state.isInterviewLocked || state.attemptsLeft <= 0) return;
    final currentQuestion = state.interview!.questions[state.currentQuestionIndex];
    emit(state.copyWith(
      status: ExamsStatus.recording,
      isRecording: true,
      attemptsLeft: state.attemptsLeft - 1,
      recordingDuration: currentQuestion.timeLimitSeconds,
    ));
  }

  void updateTimer(int remainingSeconds) {
    emit(state.copyWith(recordingDuration: remainingSeconds));
  }

  void stopRecording() {
    emit(state.copyWith(status: ExamsStatus.reviewing, isRecording: false));
  }

  void retakeRecording() {
    if (state.attemptsLeft > 0) {
      emit(state.copyWith(status: ExamsStatus.interviewLoaded));
    }
  }

  // ─── Answer Submission ────────────────────────────────────────────────────────

  Future<void> submitAnswer(File videoFile) async {
    // Double-submit guard — atomic boolean prevents concurrent calls
    if (state.interview == null || _isNavigating || _isSubmitting) return;
    _isSubmitting = true;

    final fileSizeInBytes = await videoFile.length();
    if (fileSizeInBytes > 50 * 1024 * 1024) {
      emit(state.copyWith(status: ExamsStatus.error, errorMessage: 'File size exceeds 50MB limit'));
      return;
    }

    // ── Backend Guard: Validate fresh status before submission ──
    final canSubmit = await _canSubmitAnswer(state.interview!.id);
    if (!canSubmit) {
      emit(state.copyWith(
        status: ExamsStatus.error,
        errorMessage: 'Submission blocked: This interview has already been reviewed or closed by admin.',
      ));
      return;
    }

    _refreshToken();
    emit(state.copyWith(status: ExamsStatus.answerSubmitting));

    final result = await submitAnswerUseCase(
      SubmitAnswerParams(
        interviewId: state.interview!.id,
        questionIndex: state.currentQuestionIndex,
        videoFile: videoFile,
      ),
      cancelToken: _cancelToken,
    );

    result.fold(
      (failure) {
        _isSubmitting = false;
        emit(state.copyWith(status: ExamsStatus.error, errorMessage: failure.message));
      },
      (_) async {
        _isSubmitting = false;
        if (await videoFile.exists()) await videoFile.delete();

        final updatedQuestions = List.of(state.interview!.questions);
        final qIndex = state.currentQuestionIndex;
        updatedQuestions[qIndex] = updatedQuestions[qIndex].copyWith(isAnswered: true);

        final updatedInterview = state.interview!.copyWith(
          questions: updatedQuestions,
          answeredCount: updatedQuestions.where((q) => q.isAnswered).length,
        );

        final isLastQuestion = qIndex == state.interview!.totalQuestions - 1;

        if (isLastQuestion) {
          emit(state.copyWith(status: ExamsStatus.success, interview: updatedInterview));
        } else {
          emit(state.copyWith(status: ExamsStatus.success, interview: updatedInterview));
          nextQuestion();
        }
      },
    );
  }

  /// Fetches fresh interview status from backend.
  /// Returns false if submission must be blocked.
  Future<bool> _canSubmitAnswer(String interviewId) async {
    _refreshToken();
    final result = await repository.getInterviewStatus(interviewId, cancelToken: _cancelToken);
    return result.fold(
      (_) => false, // Fail-safe: block on error
      (status) => !_blockedStatuses.contains(status),
    );
  }

  // ─── Final Submission ─────────────────────────────────────────────────────────

  Future<void> finalizeInterview() async {
    if (state.interview == null || _isNavigating || _isSubmitting) return;
    _isSubmitting = true;

    _refreshToken();
    emit(state.copyWith(status: ExamsStatus.interviewSubmitting));

    final result = await submitInterviewUseCase(state.interview!.id, cancelToken: _cancelToken);

    result.fold(
      (failure) {
        _isSubmitting = false;
        emit(state.copyWith(status: ExamsStatus.error, errorMessage: failure.message));
      },
      (_) async {
        _isSubmitting = false;
        await _clearCachedInterviewId();

        // │ LOCK FIRST — before any other state change
        // │ This prevents any navigation or camera re-init during the success
        // │ window between this emit and the UI's reaction.
        emit(state.copyWith(
          status: ExamsStatus.success,
          interview: null,
          isInterviewLocked: true,  // ← GLOBAL POST-SUBMIT LOCK
        ));

        await getLanguages();
      },
    );
  }

  // ─── Navigation Stabilization Helpers ────────────────────────────────────────

  void setNavigating(bool val) {
    _isNavigating = val;
    emit(state.copyWith(isNavigating: val));

    // Auto-release after 3 seconds as a failsafe to prevent permanent lock
    if (val) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_isNavigating && !isClosed) {
          _isNavigating = false;
          emit(state.copyWith(isNavigating: false));
        }
      });
    }
  }

  void completePreInterview(String interviewId) {
    emit(state.copyWith(completedPreInterviewId: interviewId));
  }

  // ─── Cache Helpers ────────────────────────────────────────────────────────────

  Future<void> _cacheInterviewId(String id) async {
    await sharedPreferences.setString(_activeInterviewKey, id);
  }

  Future<void> _clearCachedInterviewId() async {
    await sharedPreferences.remove(_activeInterviewKey);
  }
}
