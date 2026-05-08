import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../../../../core/services/camera_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_camera_preview.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../cubit/exams_cubit.dart';
import '../cubit/exams_state.dart';
import 'interview_under_review_page.dart';

class InterviewScreen extends StatefulWidget {
  final String interviewId;

  const InterviewScreen({super.key, required this.interviewId});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  // ── CameraService is the sole hardware authority ──
  final _camera = CameraService.instance;

  // ── Cubit cached here — NEVER call context.read() inside dispose() ──
  late ExamsCubit _cubit;

  // ── Only local video-player for review phase ──
  VideoPlayerController? _videoPlayerController;
  Timer? _timer;
  File? _recordedFile;
  bool _localCameraReady = false;

  @override
  void initState() {
    super.initState();
    // Cache cubit reference while widget is alive and context is valid
    _cubit = context.read<ExamsCubit>();

    // POST-SUBMIT LOCK: Eject immediately — never allow camera init on a locked session
    if (_cubit.state.isInterviewLocked) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await _camera.initialize();
      if (mounted) setState(() => _localCameraReady = true);
    } catch (e) {
      debugPrint('InterviewScreen: Camera init via CameraService failed: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoPlayerController?.dispose();
    // Safe: using cached reference — never access context in dispose()
    _cubit.cancelPendingRequests();
    super.dispose();
  }

  // ─── Recording Control ────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    // Secondary defense: block camera engagement if session is locked
    if (_cubit.state.isInterviewLocked) return;
    if (!_camera.isInitialized || _camera.isRecording) return;

    try {
      await _camera.startRecording();
      if (!mounted) return;
      context.read<ExamsCubit>().startRecording();
      _startTimer();
    } catch (e) {
      debugPrint('InterviewScreen: Start recording error: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = context.read<ExamsCubit>().state.recordingDuration;
      if (remaining <= 1) {
        _stopRecording();
      } else {
        context.read<ExamsCubit>().updateTimer(remaining - 1);
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    if (!_camera.isRecording) return;

    try {
      final xFile = await _camera.stopRecording();
      if (!mounted || xFile == null) return;
      _recordedFile = File(xFile.path);
      context.read<ExamsCubit>().stopRecording();
      await _initializeVideoPlayer(_recordedFile!);
    } catch (e) {
      debugPrint('InterviewScreen: Stop recording error: $e');
    }
  }

  Future<void> _initializeVideoPlayer(File file) async {
    await _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(file);
    await _videoPlayerController!.initialize();
    await _videoPlayerController!.setLooping(true);
    await _videoPlayerController!.play();
    if (mounted) setState(() {});
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────

  void _onRetake() {
    setState(() {
      _recordedFile = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
    });
    context.read<ExamsCubit>().retakeRecording();
  }

  void _onConfirm() {
    if (_recordedFile == null) return;
    final file = _recordedFile!;
    setState(() {
      _recordedFile = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
    });
    context.read<ExamsCubit>().submitAnswer(file);
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<ExamsCubit, ExamsState>(
      listenWhen: (prev, cur) => prev.status != cur.status,
      listener: (context, state) {
        if (!mounted) return;
        if (state.isNavigating) return;

        if (state.status == ExamsStatus.interviewUnderReview) {
          context.read<ExamsCubit>().setNavigating(true);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const InterviewUnderReviewPage()),
          );
        } else if (state.status == ExamsStatus.interviewError &&
            state.errorMessage != null) {
          AppSnackbar.error(context, state.errorMessage!);
        }
      },
      child: BlocBuilder<ExamsCubit, ExamsState>(
        // ── Only rebuild when statuses or question data change, not on every timer tick ──
        buildWhen: (prev, cur) =>
            prev.status != cur.status ||
            prev.currentQuestionIndex != cur.currentQuestionIndex ||
            prev.attemptsLeft != cur.attemptsLeft ||
            prev.isNavigating != cur.isNavigating ||
            prev.interview?.answeredCount != cur.interview?.answeredCount,
        builder: (context, state) {
          final interview = state.interview;
          if (interview == null) {
            return AppScaffold(
              body: const AppLoading(message: 'Loading interview…'),
            );
          }

          final currentQuestion =
              interview.questions[state.currentQuestionIndex];
          final totalQuestions = interview.totalQuestions;
          final progress = (state.currentQuestionIndex + 1) / totalQuestions;

          final palette = AppColors.of(context);
          final cs = theme.colorScheme;

          return AppScaffold(
            appBar: AppBar(
              title: Text(
                '${interview.languageName} interview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: state.isNavigating
                    ? null
                    : () => Navigator.pop(context),
              ),
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              foregroundColor: palette.textPrimary,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: palette.primarySoft,
                  valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
                  minHeight: 4,
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageGutter,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${currentQuestion.index + 1} of $totalQuestions',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildAttemptsBadge(context, state.attemptsLeft),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    currentQuestion.questionText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Experience Area ──
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildMainContent(state),
                            if (state.isRecording)
                              _buildRecordingOverlay(context, state),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                  _buildActionArea(context, state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Sub-Widgets ──────────────────────────────────────────────────────────────

  Widget _buildAttemptsBadge(BuildContext context, int attemptsLeft) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final hasAttempts = attemptsLeft > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: hasAttempts ? palette.successSoft : palette.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '$attemptsLeft attempts left',
        style: theme.textTheme.labelSmall?.copyWith(
          color: hasAttempts ? palette.success : palette.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMainContent(ExamsState state) {
    if (state.status == ExamsStatus.reviewing &&
        _videoPlayerController != null) {
      return VideoPlayer(_videoPlayerController!);
    }

    // ── Use CameraService.instance.controller for preview ──
    final controller = _camera.controller;
    if (_localCameraReady &&
        controller != null &&
        controller.value.isInitialized) {
      return AppCameraPreview(controller: controller);
    }

    return Center(child: AppSpinner.large());
  }

  Widget _buildRecordingOverlay(BuildContext context, ExamsState state) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Positioned(
      top: AppSpacing.lg,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _RecordingDot(),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'REC',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: palette.onPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.scrim,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                '${state.recordingDuration}s',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, ExamsState state) {
    final palette = AppColors.of(context);
    final cs = Theme.of(context).colorScheme;

    final btnShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    // ── Block all interactions during navigation ──
    if (state.isNavigating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSpinner.large(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please wait…',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
        ],
      );
    }

    if (state.status == ExamsStatus.interviewInProgress ||
        state.status == ExamsStatus.interviewSubmitting ||
        state.status == ExamsStatus.interviewUnderReview) {
      final msg = state.status == ExamsStatus.interviewSubmitting
          ? 'Finalizing interview…'
          : 'Saving your answer…';
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSpinner.large(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            msg,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
        ],
      );
    }

    // The "Complete Interview" button has been removed as per strict
    // constraints: automation triggers `finalizeInterview()` automatically.

    if (state.status == ExamsStatus.reviewing) {
      return Row(
        children: [
          if (state.attemptsLeft > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _onRetake,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retake'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSize.buttonLg),
                  shape: btnShape,
                ),
              ),
            ),
          if (state.attemptsLeft > 0) const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: FilledButton.icon(
              onPressed: _onConfirm,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Confirm'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSize.buttonLg),
                backgroundColor: palette.success,
                foregroundColor: palette.onPrimary,
                shape: btnShape,
              ),
            ),
          ),
        ],
      );
    }

    // Default: ready to record
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: state.isRecording ? _stopRecording : _startRecording,
        icon: Icon(
          state.isRecording ? Icons.stop_rounded : Icons.fiber_manual_record,
        ),
        label: Text(state.isRecording ? 'Stop recording' : 'Start recording'),
        style: FilledButton.styleFrom(
          backgroundColor: state.isRecording ? cs.error : palette.primary,
          foregroundColor: state.isRecording ? cs.onError : palette.onPrimary,
          minimumSize: const Size(double.infinity, AppSize.buttonLg),
          shape: btnShape,
        ),
      ),
    );
  }
}

// ─── Recording Dot Animation (unchanged) ─────────────────────────────────────

class _RecordingDot extends StatefulWidget {
  @override
  _RecordingDotState createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: palette.danger,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
