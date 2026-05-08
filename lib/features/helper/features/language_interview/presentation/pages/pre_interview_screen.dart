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
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/widgets/app_camera_preview.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../cubit/exams_cubit.dart';
import '../cubit/exams_state.dart';

class PreInterviewScreen extends StatefulWidget {
  const PreInterviewScreen({super.key});

  @override
  State<PreInterviewScreen> createState() => _PreInterviewScreenState();
}

enum PreInterviewState {
  initializing,
  idle,
  recording,
  preparing,
  reviewing,
  error,
}

class _PreInterviewScreenState extends State<PreInterviewScreen> {
  // ── CameraService is the sole hardware authority ──
  final _camera = CameraService.instance;

  // ── Cubit cached here — NEVER call context.read() inside dispose() ──
  late ExamsCubit _cubit;

  // ── Local video player for review phase only ──
  VideoPlayerController? _videoPlayerController;
  PreInterviewState _state = PreInterviewState.initializing;
  String _errorMessage = '';
  File? _testVideoFile;
  Timer? _timer;
  int _secondsRemaining = 10;

  @override
  void initState() {
    super.initState();
    // Cache cubit reference while widget is alive and context is valid
    _cubit = context.read<ExamsCubit>();

    // POST-SUBMIT LOCK: Eject immediately — do not request permissions or init camera
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
      if (mounted) {
        setState(() {
          _state = PreInterviewState.error;
          _errorMessage = 'Camera and Microphone permissions are required.';
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _camera.initialize();
      if (mounted) setState(() => _state = PreInterviewState.idle);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = PreInterviewState.error;
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoPlayerController?.dispose();
    // Delete temp test file — camera hardware owned by CameraService, not disposed here
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

  // ─── Recording Logic ──────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (!_camera.isInitialized || _camera.isRecording) return;

    try {
      await _camera.startRecording();
      if (!mounted) return;
      setState(() {
        _state = PreInterviewState.recording;
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

    if (mounted) setState(() => _state = PreInterviewState.preparing);

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
      if (mounted) setState(() => _state = PreInterviewState.reviewing);
    } catch (e) {
      debugPrint('PreInterviewScreen: Preview init error: $e');
    }
  }

  void _onRetake() {
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _deleteTestFile();
    _testVideoFile = null;
    setState(() => _state = PreInterviewState.idle);
  }

  // ─── Confirm & Navigate ───────────────────────────────────────────────────────

  Future<void> _onConfirmAndStart() async {
    if (_cubit.state.isNavigating) return;

    setState(() => _state = PreInterviewState.preparing);
    _cubit.setNavigating(true);

    _timer?.cancel();

    // Stop video player first
    try {
      if (_videoPlayerController != null &&
          _videoPlayerController!.value.isPlaying) {
        await _videoPlayerController!.pause();
      }
    } catch (_) {}

    // Dispose video player
    await _videoPlayerController?.dispose();
    _videoPlayerController = null;

    // Mark pre-interview complete for this session
    final interviewId = _cubit.state.interview?.id ?? '';
    _cubit.completePreInterview(interviewId);

    // Cleanup test file
    _deleteTestFile();
    _testVideoFile = null;

    // Release camera hardware via CameraService
    await _camera.dispose();

    // Safety delay for OS to release audio/camera session
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    // Navigate by path only — cubit is singleton, resolved by GoRouter via GetIt
    context.push(AppRouter.interviewScreen);
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final cs = theme.colorScheme;

    return PopScope(
      canPop:
          _state != PreInterviewState.recording &&
          _state != PreInterviewState.preparing,
      child: AppScaffold(
        backgroundColor: palette.scaffold,
        appBar: AppBar(
          title: Text(
            'Pre-Interview Test',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: palette.textPrimary,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageGutter,
                        vertical: AppSpacing.lg,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final targetH = (constraints.maxHeight * 0.62).clamp(
                            220.0,
                            460.0,
                          );
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getHeaderText(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              SizedBox(
                                height: targetH,
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                    border: Border.all(
                                      color: _state == PreInterviewState.error
                                          ? palette.danger
                                          : palette.primary,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
                                    child: _buildMainContent(),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageGutter,
                    AppSpacing.sm,
                    AppSpacing.pageGutter,
                    AppSpacing.lg,
                  ),
                  child: _buildActionButtons(context),
                ),
              ],
            ),

            // ── Full-screen overlay during hardware handoff ──
            if (_state == PreInterviewState.preparing)
              ColoredBox(
                color: palette.scrim,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSpinner.large(color: palette.onPrimary),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Preparing interview…',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: palette.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getHeaderText() {
    switch (_state) {
      case PreInterviewState.initializing:
        return 'Initializing hardware...';
      case PreInterviewState.idle:
        return 'Record a 10s selfie clip to test your setup';
      case PreInterviewState.recording:
        return 'Recording test clip...';
      case PreInterviewState.preparing:
        return 'Secured! Preparing interview...';
      case PreInterviewState.reviewing:
        return 'Does the video and audio look good?';
      case PreInterviewState.error:
        return 'Something went wrong';
    }
  }

  Widget _buildMainContent() {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);

    if (_state == PreInterviewState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            _errorMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textInverse,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_state == PreInterviewState.preparing) {
      return Center(child: AppSpinner.large(color: palette.primary));
    }

    if (_state == PreInterviewState.reviewing &&
        _videoPlayerController != null) {
      return AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: VideoPlayer(_videoPlayerController!),
      );
    }

    // ── Always use CameraService.instance.controller for preview ──
    final controller = _camera.controller;
    if (controller != null && controller.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          AppCameraPreview(controller: controller),
          if (_state == PreInterviewState.recording)
            Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              child: DecoratedBox(
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
                    '${_secondsRemaining}s',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: palette.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Center(child: AppSpinner.large(color: palette.primary));
  }

  Widget _buildActionButtons(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = AppColors.of(context);

    final primaryBtnShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );

    if (_state == PreInterviewState.recording) {
      return FilledButton.icon(
        onPressed: _stopRecording,
        icon: const Icon(Icons.stop_rounded),
        label: const Text('Stop recording'),
        style: FilledButton.styleFrom(
          backgroundColor: cs.error,
          foregroundColor: cs.onError,
          minimumSize: const Size(double.infinity, AppSize.buttonLg),
          shape: primaryBtnShape,
        ),
      );
    }

    if (_state == PreInterviewState.reviewing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _onRetake,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSize.buttonLg),
                shape: primaryBtnShape,
              ),
              child: const Text('Retake'),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: BlocBuilder<ExamsCubit, ExamsState>(
              buildWhen: (prev, cur) => prev.isNavigating != cur.isNavigating,
              builder: (context, state) {
                return FilledButton(
                  onPressed: state.isNavigating ? null : _onConfirmAndStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.success,
                    foregroundColor: palette.onPrimary,
                    minimumSize: const Size(0, AppSize.buttonLg),
                    shape: primaryBtnShape,
                  ),
                  child: const Text('Confirm & start'),
                );
              },
            ),
          ),
        ],
      );
    }

    return FilledButton.icon(
      onPressed: _state == PreInterviewState.idle ? _startRecording : null,
      icon: const Icon(Icons.videocam_rounded),
      label: const Text('Start test recording'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, AppSize.buttonLg),
        shape: primaryBtnShape,
      ),
    );
  }
}
