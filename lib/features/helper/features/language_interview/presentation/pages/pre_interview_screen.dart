import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/camera_service.dart';
import '../../../../../../core/services/haptic_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/app_camera_preview.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../cubit/exams_cubit.dart';
import '../cubit/exams_state.dart';

/// Pre-interview hardware test screen.
///
/// Records a 10s test clip so the helper can verify camera + mic before
/// committing to the actual interview. Hardware is owned by [CameraService].
class PreInterviewScreen extends StatefulWidget {
  const PreInterviewScreen({super.key});

  @override
  State<PreInterviewScreen> createState() => _PreInterviewScreenState();
}

enum _PreInterviewState {
  initializing,
  idle,
  recording,
  preparing,
  reviewing,
  error,
}

class _PreInterviewScreenState extends State<PreInterviewScreen> {
  final _camera = CameraService.instance;
  late ExamsCubit _cubit;

  VideoPlayerController? _videoPlayerController;
  _PreInterviewState _state = _PreInterviewState.initializing;
  String _errorMessage = '';
  File? _testVideoFile;
  Timer? _timer;
  int _secondsRemaining = 10;

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

    _checkPermissionsAndInit();
  }

  Future<void> _checkPermissionsAndInit() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted && micStatus.isGranted) {
      await _initializeCamera();
    } else {
      if (!mounted) return;
      setState(() {
        _state = _PreInterviewState.error;
        _errorMessage = 'Camera and Microphone permissions are required.';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _camera.initialize();
      if (mounted) setState(() => _state = _PreInterviewState.idle);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _PreInterviewState.error;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoPlayerController?.dispose();
    _deleteTestFile();
    super.dispose();
  }

  void _deleteTestFile() {
    try {
      if (_testVideoFile != null && _testVideoFile!.existsSync()) {
        _testVideoFile!.deleteSync();
      }
    } catch (e) {
      debugPrint('PreInterviewScreen: Test file deletion error: $e');
    }
  }

  // ─── Recording ─────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (!_camera.isInitialized || _camera.isRecording) return;

    try {
      await _camera.startRecording();
      if (!mounted) return;
      HapticService.medium();
      setState(() {
        _state = _PreInterviewState.recording;
        _secondsRemaining = 10;
      });
      _startTimer();
    } catch (e) {
      debugPrint('PreInterviewScreen: Start recording error: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        _stopRecording();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    if (!_camera.isRecording) return;

    if (mounted) setState(() => _state = _PreInterviewState.preparing);

    try {
      final xFile = await _camera.stopRecording();
      if (!mounted || xFile == null) return;
      _testVideoFile = File(xFile.path);
      await _initializePreview();
    } catch (e) {
      debugPrint('PreInterviewScreen: Stop recording error: $e');
    }
  }

  Future<void> _initializePreview() async {
    if (_testVideoFile == null) return;

    await _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(_testVideoFile!);

    try {
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.play();
      if (mounted) setState(() => _state = _PreInterviewState.reviewing);
    } catch (e) {
      debugPrint('PreInterviewScreen: Preview init error: $e');
    }
  }

  void _onRetake() {
    HapticService.light();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _deleteTestFile();
    _testVideoFile = null;
    setState(() => _state = _PreInterviewState.idle);
  }

  Future<void> _onConfirmAndStart() async {
    if (_cubit.state.isNavigating) return;

    HapticService.medium();
    setState(() => _state = _PreInterviewState.preparing);
    _cubit.setNavigating(true);

    _timer?.cancel();

    try {
      if (_videoPlayerController != null &&
          _videoPlayerController!.value.isPlaying) {
        await _videoPlayerController!.pause();
      }
    } catch (_) {}

    await _videoPlayerController?.dispose();
    _videoPlayerController = null;

    final interviewId = _cubit.state.interview?.id ?? '';
    _cubit.completePreInterview(interviewId);

    _deleteTestFile();
    _testVideoFile = null;

    await _camera.dispose();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    context.push(AppRouter.interviewScreen);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return PopScope(
      canPop: _state != _PreInterviewState.recording &&
          _state != _PreInterviewState.preparing,
      child: Scaffold(
        backgroundColor: palette.scaffold,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _TopBar(
                    title: 'Pre-Interview Test',
                    canPop: _state != _PreInterviewState.recording &&
                        _state != _PreInterviewState.preparing,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InstructionCard(state: _state),
                          const SizedBox(height: 16),
                          _PreviewFrame(
                            state: _state,
                            secondsRemaining: _secondsRemaining,
                            errorMessage: _errorMessage,
                            videoPlayerController: _videoPlayerController,
                            cameraController: _camera.controller,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: _ActionArea(
                      state: _state,
                      onStart: _startRecording,
                      onStop: _stopRecording,
                      onRetake: _onRetake,
                      onConfirm: _onConfirmAndStart,
                    ),
                  ),
                ],
              ),
              if (_state == _PreInterviewState.preparing) const _LoadingScrim(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final bool canPop;

  const _TopBar({required this.title, required this.canPop});

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
            icon: Icon(
              Icons.arrow_back_rounded,
              color: palette.textPrimary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: palette.surface,
              shape: const CircleBorder(),
              side: BorderSide(color: palette.border, width: 0.5),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Instruction Card ────────────────────────────────────────────────────────

class _InstructionCard extends StatelessWidget {
  final _PreInterviewState state;

  const _InstructionCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    final IconData icon;
    final String title;
    final String message;
    final Color color;

    switch (state) {
      case _PreInterviewState.initializing:
        icon = Icons.settings_rounded;
        title = 'Initializing hardware';
        message = 'Setting up your camera and microphone…';
        color = palette.primary;
        break;
      case _PreInterviewState.idle:
        icon = Icons.lightbulb_rounded;
        title = 'Quick check before we start';
        message =
            'Record a 10-second test clip to verify your camera and microphone work properly.';
        color = palette.primary;
        break;
      case _PreInterviewState.recording:
        icon = Icons.fiber_manual_record;
        title = 'Recording test clip';
        message = 'Speak naturally — this is just a sound and video check.';
        color = palette.danger;
        break;
      case _PreInterviewState.preparing:
        icon = Icons.hourglass_top_rounded;
        title = 'Securing recording';
        message = 'Releasing camera and preparing the interview…';
        color = palette.primary;
        break;
      case _PreInterviewState.reviewing:
        icon = Icons.play_circle_outline_rounded;
        title = 'How does it look?';
        message =
            'If the video and audio look good, confirm to start your interview.';
        color = const Color(0xFF22C55E);
        break;
      case _PreInterviewState.error:
        icon = Icons.error_outline_rounded;
        title = 'Something went wrong';
        message = '';
        color = palette.danger;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: palette.isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: palette.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Preview Frame ───────────────────────────────────────────────────────────

class _PreviewFrame extends StatelessWidget {
  final _PreInterviewState state;
  final int secondsRemaining;
  final String errorMessage;
  final VideoPlayerController? videoPlayerController;
  final dynamic cameraController;

  const _PreviewFrame({
    required this.state,
    required this.secondsRemaining,
    required this.errorMessage,
    required this.videoPlayerController,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final isError = state == _PreInterviewState.error;

    final frameColor = isError
        ? palette.danger
        : state == _PreInterviewState.recording
            ? palette.danger
            : palette.primary;

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: frameColor.withValues(alpha: isError ? 1.0 : 0.55),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: frameColor.withValues(alpha: 0.18),
              blurRadius: 24,
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
              if (state == _PreInterviewState.recording)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _CountdownPill(seconds: secondsRemaining),
                ),
              if (state == _PreInterviewState.recording)
                Positioned(
                  top: 12,
                  left: 12,
                  child: _RecBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final palette = AppColors.of(context);

    if (state == _PreInterviewState.error) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    if (state == _PreInterviewState.preparing) {
      return Center(child: AppSpinner.large(color: palette.primary));
    }

    if (state == _PreInterviewState.reviewing &&
        videoPlayerController != null) {
      return AspectRatio(
        aspectRatio: videoPlayerController!.value.aspectRatio,
        child: VideoPlayer(videoPlayerController!),
      );
    }

    final controller = cameraController;
    if (controller != null && controller.value.isInitialized) {
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
  final _PreInterviewState state;
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
    if (state == _PreInterviewState.recording) {
      return _GradientButton(
        label: 'Stop recording',
        icon: Icons.stop_rounded,
        colors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
        onTap: onStop,
      );
    }

    if (state == _PreInterviewState.reviewing) {
      return Row(
        children: [
          Expanded(
            child: _OutlineButton(
              label: 'Retake',
              icon: Icons.refresh_rounded,
              onTap: onRetake,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BlocBuilder<ExamsCubit, ExamsState>(
              buildWhen: (p, c) => p.isNavigating != c.isNavigating,
              builder: (context, examsState) {
                return _GradientButton(
                  label: 'Confirm & start',
                  icon: Icons.check_rounded,
                  colors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                  onTap: examsState.isNavigating ? null : onConfirm,
                );
              },
            ),
          ),
        ],
      );
    }

    return _GradientButton(
      label: 'Start test recording',
      icon: Icons.videocam_rounded,
      onTap: state == _PreInterviewState.idle ? onStart : null,
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

// ─── Loading Scrim ───────────────────────────────────────────────────────────

class _LoadingScrim extends StatelessWidget {
  const _LoadingScrim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSpinner.large(color: palette.onPrimary),
          const SizedBox(height: 16),
          Text(
            'Preparing interview…',
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

