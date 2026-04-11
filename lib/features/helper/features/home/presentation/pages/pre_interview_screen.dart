import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/services/camera_service.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../cubit/exams_cubit.dart';
import '../cubit/exams_state.dart';

class PreInterviewScreen extends StatefulWidget {
  const PreInterviewScreen({super.key});

  @override
  State<PreInterviewScreen> createState() => _PreInterviewScreenState();
}

enum PreInterviewState { initializing, idle, recording, preparing, reviewing, error }

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
      if (_videoPlayerController != null && _videoPlayerController!.value.isPlaying) {
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
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: _state != PreInterviewState.recording && _state != PreInterviewState.preparing,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(
          title: const Text('Pre-Interview Test'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLG),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getHeaderText(),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spaceLG),
                          Container(
                            height: 400,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                              border: Border.all(
                                color: _state == PreInterviewState.error
                                    ? Colors.red
                                    : theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _buildMainContent(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceLG),
                  child: _buildActionButtons(),
                ),
              ],
            ),

            // ── Full-screen overlay during hardware handoff ──
            if (_state == PreInterviewState.preparing)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: AppTheme.spaceLG),
                      Text(
                        'Preparing interview...',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
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
      case PreInterviewState.initializing: return 'Initializing hardware...';
      case PreInterviewState.idle:         return 'Record a 10s selfie clip to test your setup';
      case PreInterviewState.recording:    return 'Recording test clip...';
      case PreInterviewState.preparing:    return 'Secured! Preparing interview...';
      case PreInterviewState.reviewing:    return 'Does the video and audio look good?';
      case PreInterviewState.error:        return 'Something went wrong';
    }
  }

  Widget _buildMainContent() {
    if (_state == PreInterviewState.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(_errorMessage,
              style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
        ),
      );
    }

    if (_state == PreInterviewState.preparing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_state == PreInterviewState.reviewing && _videoPlayerController != null) {
      return AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: VideoPlayer(_videoPlayerController!),
      );
    }

    // ── Always use CameraService.instance.controller for preview ──
    final controller = _camera.controller;
    if (controller != null && controller.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          if (_state == PreInterviewState.recording)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${_secondsRemaining}s',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildActionButtons() {
    if (_state == PreInterviewState.recording) {
      return ElevatedButton.icon(
        onPressed: _stopRecording,
        icon: const Icon(Icons.stop_rounded),
        label: const Text('Stop Recording'),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 56)),
      );
    }

    if (_state == PreInterviewState.reviewing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _onRetake,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
              child: const Text('Retake'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<ExamsCubit, ExamsState>(
              // Only rebuild this button when navigation lock changes
              buildWhen: (prev, cur) => prev.isNavigating != cur.isNavigating,
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: state.isNavigating ? null : _onConfirmAndStart,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 56), backgroundColor: Colors.green),
                  child: const Text('Confirm & Start'),
                );
              },
            ),
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: _state == PreInterviewState.idle ? _startRecording : null,
      icon: const Icon(Icons.videocam_rounded),
      label: const Text('Start Test Recording'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
    );
  }
}
