import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../../../../core/services/camera_service.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/app_camera_preview.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../cubit/exams_cubit.dart';
import '../cubit/exams_state.dart';
import 'interview_under_review_page.dart';

/// Active interview screen — records & submits each answer.
///
/// Hardware is owned by [CameraService]. Submission flow + question state is
/// driven by [ExamsCubit].
class InterviewScreen extends StatefulWidget {
  final String interviewId;

  const InterviewScreen({super.key, required this.interviewId});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final _camera = CameraService.instance;
  late ExamsCubit _cubit;

  VideoPlayerController? _videoPlayerController;
  Timer? _timer;
  File? _recordedFile;
  bool _localCameraReady = false;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ExamsCubit>();

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
      debugPrint('InterviewScreen: Camera init failed: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoPlayerController?.dispose();
    _cubit.cancelPendingRequests();
    super.dispose();
  }

  // ─── Recording ─────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (_cubit.state.isInterviewLocked) return;
    if (!_camera.isInitialized || _camera.isRecording) return;

    try {
      await _camera.startRecording();
      if (!mounted) return;
      HapticService.medium();
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

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _onRetake() {
    HapticService.light();
    setState(() {
      _recordedFile = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
    });
    context.read<ExamsCubit>().retakeRecording();
  }

  void _onConfirm() {
    if (_recordedFile == null) return;
    HapticService.medium();
    final file = _recordedFile!;
    setState(() {
      _recordedFile = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
    });
    context.read<ExamsCubit>().submitAnswer(file);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

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
        buildWhen: (prev, cur) =>
            prev.status != cur.status ||
            prev.currentQuestionIndex != cur.currentQuestionIndex ||
            prev.attemptsLeft != cur.attemptsLeft ||
            prev.isNavigating != cur.isNavigating ||
            prev.interview?.answeredCount != cur.interview?.answeredCount,
        builder: (context, state) {
          final interview = state.interview;
          if (interview == null) {
            return Scaffold(
              backgroundColor: palette.scaffold,
              body: const AppLoading(message: 'Loading interview…'),
            );
          }

          final currentQuestion =
              interview.questions[state.currentQuestionIndex];
          final totalQuestions = interview.totalQuestions;

          return Scaffold(
            backgroundColor: palette.scaffold,
            body: SafeArea(
              child: Column(
                children: [
                  _Header(
                    languageName: interview.languageName,
                    currentIndex: state.currentQuestionIndex + 1,
                    totalQuestions: totalQuestions,
                    canPop: !state.isNavigating,
                  ),
                  _ProgressBar(
                    current: state.currentQuestionIndex + 1,
                    total: totalQuestions,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _QuestionCard(
                            questionNumber: currentQuestion.index + 1,
                            totalQuestions: totalQuestions,
                            questionText: currentQuestion.questionText,
                            attemptsLeft: state.attemptsLeft,
                          ),
                          const SizedBox(height: 14),
                          _RecordingFrame(
                            state: state,
                            videoPlayerController: _videoPlayerController,
                            cameraController: _camera.controller,
                            localCameraReady: _localCameraReady,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: _ActionArea(
                      state: state,
                      onStart: _startRecording,
                      onStop: _stopRecording,
                      onRetake: _onRetake,
                      onConfirm: _onConfirm,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String languageName;
  final int currentIndex;
  final int totalQuestions;
  final bool canPop;

  const _Header({
    required this.languageName,
    required this.currentIndex,
    required this.totalQuestions,
    required this.canPop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: canPop ? () => Navigator.of(context).maybePop() : null,
            icon: Icon(Icons.close_rounded, color: palette.textPrimary),
            style: IconButton.styleFrom(
              backgroundColor: palette.surface,
              shape: const CircleBorder(),
              side: BorderSide(color: palette.border, width: 0.5),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$languageName interview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Question $currentIndex of $totalQuestions',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Bar ────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final progress = total == 0 ? 0.0 : current / total;

    return Semantics(
      value: '${(progress * 100).toInt()}%',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Row(
          children: List.generate(total, (i) {
            final filled = i < current;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                height: 4,
                decoration: BoxDecoration(
                  gradient: filled
                      ? LinearGradient(
                          colors: [
                            palette.primary,
                            const Color(0xFF7B61FF),
                          ],
                        )
                      : null,
                  color: filled ? null : palette.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Question Card ───────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final int questionNumber;
  final int totalQuestions;
  final String questionText;
  final int attemptsLeft;

  const _QuestionCard({
    required this.questionNumber,
    required this.totalQuestions,
    required this.questionText,
    required this.attemptsLeft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.isDark
              ? [
                  palette.primary.withValues(alpha: 0.18),
                  const Color(0xFF7B61FF).withValues(alpha: 0.10),
                ]
              : [
                  palette.primary.withValues(alpha: 0.10),
                  const Color(0xFF7B61FF).withValues(alpha: 0.06),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.25),
          width: 0.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Q$questionNumber/$totalQuestions',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              _AttemptsBadge(attemptsLeft: attemptsLeft),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            questionText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptsBadge extends StatelessWidget {
  final int attemptsLeft;

  const _AttemptsBadge({required this.attemptsLeft});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final has = attemptsLeft > 0;
    final color = has ? const Color(0xFF22C55E) : palette.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.replay_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$attemptsLeft attempts left',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recording Frame ─────────────────────────────────────────────────────────

class _RecordingFrame extends StatelessWidget {
  final ExamsState state;
  final VideoPlayerController? videoPlayerController;
  final dynamic cameraController;
  final bool localCameraReady;

  const _RecordingFrame({
    required this.state,
    required this.videoPlayerController,
    required this.cameraController,
    required this.localCameraReady,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isRecording = state.isRecording;
    final color = isRecording ? palette.danger : palette.primary;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withValues(alpha: 0.55),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.20),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildContent(context),
              if (isRecording)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _RecBadge(),
                ),
              if (isRecording)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _CountdownPill(seconds: state.recordingDuration),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final palette = AppColors.of(context);

    if (state.status == ExamsStatus.reviewing &&
        videoPlayerController != null) {
      return VideoPlayer(videoPlayerController!);
    }

    final controller = cameraController;
    if (localCameraReady &&
        controller != null &&
        controller.value.isInitialized) {
      return AppCameraPreview(controller: controller);
    }

    return Center(child: AppSpinner.large(color: palette.primary));
  }
}

class _RecBadge extends StatefulWidget {
  @override
  State<_RecBadge> createState() => _RecBadgeState();
}

class _RecBadgeState extends State<_RecBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
            SizedBox(width: 4),
            Text(
              'REC',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  final int seconds;
  const _CountdownPill({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            '${seconds}s',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Area ─────────────────────────────────────────────────────────────

class _ActionArea extends StatelessWidget {
  final ExamsState state;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  const _ActionArea({
    required this.state,
    required this.onStart,
    required this.onStop,
    required this.onRetake,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isNavigating) {
      return _StatusFooter(label: 'Please wait…');
    }

    if (state.status == ExamsStatus.interviewInProgress ||
        state.status == ExamsStatus.interviewSubmitting ||
        state.status == ExamsStatus.interviewUnderReview) {
      final msg = state.status == ExamsStatus.interviewSubmitting
          ? 'Finalizing interview…'
          : 'Saving your answer…';
      return _StatusFooter(label: msg);
    }

    if (state.status == ExamsStatus.reviewing) {
      return Row(
        children: [
          if (state.attemptsLeft > 0)
            Expanded(
              child: _OutlineButton(
                label: 'Retake',
                icon: Icons.refresh_rounded,
                onTap: onRetake,
              ),
            ),
          if (state.attemptsLeft > 0) const SizedBox(width: 12),
          Expanded(
            child: _GradientButton(
              label: 'Confirm',
              icon: Icons.check_rounded,
              colors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
              onTap: onConfirm,
            ),
          ),
        ],
      );
    }

    if (state.isRecording) {
      return _GradientButton(
        label: 'Stop recording',
        icon: Icons.stop_rounded,
        colors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
        onTap: onStop,
      );
    }

    return _GradientButton(
      label: 'Start recording',
      icon: Icons.fiber_manual_record,
      onTap: onStart,
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final List<Color>? colors;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final disabled = onTap == null;

    final gradColors = disabled
        ? [palette.border, palette.border]
        : (colors ?? [palette.primary, const Color(0xFF7B61FF)]);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: gradColors),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: gradColors.first.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border, width: 0.6),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: palette.textPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFooter extends StatelessWidget {
  final String label;

  const _StatusFooter({required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSpinner(color: palette.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
