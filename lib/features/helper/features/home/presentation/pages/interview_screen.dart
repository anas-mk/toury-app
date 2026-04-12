import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/camera_service.dart';
import '../../../../../../core/theme/app_theme.dart';
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
    final isDark = theme.brightness == Brightness.dark;

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
        } else if (state.status == ExamsStatus.interviewError && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.redAccent),
          );
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
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final currentQuestion = interview.questions[state.currentQuestionIndex];
          final totalQuestions = interview.totalQuestions;
          final progress = (state.currentQuestionIndex + 1) / totalQuestions;

          return Scaffold(
            backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
            appBar: AppBar(
              title: Text('${interview.languageName} Interview'),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: state.isNavigating ? null : () => Navigator.pop(context),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${currentQuestion.index + 1} of $totalQuestions',
                        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                      ),
                      _buildAttemptsBadge(state.attemptsLeft),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Text(
                    currentQuestion.questionText,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppTheme.spaceLG),

                  // ── Experience Area ──
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          _buildMainContent(state),
                          if (state.isRecording) _buildRecordingOverlay(state),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceLG),
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

  Widget _buildAttemptsBadge(int attemptsLeft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: attemptsLeft > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXS),
      ),
      child: Text(
        '$attemptsLeft attempts left',
        style: TextStyle(
          color: attemptsLeft > 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMainContent(ExamsState state) {
    if (state.status == ExamsStatus.reviewing && _videoPlayerController != null) {
      return VideoPlayer(_videoPlayerController!);
    }

    // ── Use CameraService.instance.controller for preview ──
    final controller = _camera.controller;
    if (_localCameraReady && controller != null && controller.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildRecordingOverlay(ExamsState state) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _RecordingDot(),
              const SizedBox(width: 8),
              const Text('REC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: Text(
              '${state.recordingDuration}s',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, ExamsState state) {
    // ── Block all interactions during navigation ──
    if (state.isNavigating) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ExamsStatus.interviewInProgress || 
        state.status == ExamsStatus.interviewSubmitting || 
        state.status == ExamsStatus.interviewUnderReview) {
      return Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(state.status == ExamsStatus.interviewSubmitting 
                ? 'Finalizing interview...' 
                : 'Saving your answer...'),
          ],
        ),
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
                icon: const Icon(Icons.refresh),
                label: const Text('Retake'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
                ),
              ),
            ),
          if (state.attemptsLeft > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _onConfirm,
              icon: const Icon(Icons.check),
              label: const Text('Confirm'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 56),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
              ),
            ),
          ),
        ],
      );
    }

    // Default: ready to record
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: state.isRecording ? _stopRecording : _startRecording,
        icon: Icon(state.isRecording ? Icons.stop : Icons.fiber_manual_record),
        label: Text(state.isRecording ? 'Stop Recording' : 'Start Recording'),
        style: ElevatedButton.styleFrom(
          backgroundColor: state.isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMD)),
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

class _RecordingDotState extends State<_RecordingDot> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }
}
