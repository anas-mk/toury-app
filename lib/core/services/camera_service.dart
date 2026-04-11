import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Pure hardware singleton — the ONLY class allowed to own CameraController.
/// No Bloc, no UI, no navigation layer may touch CameraController directly.
class CameraService {
  CameraService._();
  static final CameraService instance = CameraService._();

  CameraController? _controller;

  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isDisposing = false;

  /// Mutex-style lock: blocks concurrent init/dispose calls.
  bool _isLocked = false;

  /// Cooldown timestamp after dispose — prevents CLOSING→REOPENING loops.
  DateTime? _lastDisposedAt;
  static const _disposeCooldownMs = 800;

  // ─── Public Getters ───────────────────────────────────────────────────────────

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;

  // ─── Initialize ───────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Block if currently disposing or locked
    if (_isDisposing || _isLocked) {
      debugPrint('CameraService: initialize() blocked (disposing=$_isDisposing, locked=$_isLocked)');
      return;
    }

    // Block if recording is in progress — NEVER reinitialize during capture
    if (_isRecording) {
      debugPrint('CameraService: initialize() blocked — recording in progress');
      return;
    }

    // Post-dispose cooldown — prevents CLOSING→REOPENING loop
    if (_lastDisposedAt != null) {
      final elapsed = DateTime.now().difference(_lastDisposedAt!).inMilliseconds;
      if (elapsed < _disposeCooldownMs) {
        final wait = _disposeCooldownMs - elapsed;
        debugPrint('CameraService: Cooldown active — waiting ${wait}ms before reinit');
        await Future.delayed(Duration(milliseconds: wait));
      }
    }

    // Idempotency guard
    if (_isInitialized && _controller != null) {
      debugPrint('CameraService: Already initialized, skipping');
      return;
    }

    _isLocked = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No hardware cameras available');

      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _controller!.initialize();
      _isInitialized = true;
      debugPrint('CameraService: Hardware initialized ✓');
    } catch (e) {
      _isInitialized = false;
      _controller = null;
      debugPrint('CameraService: Hardware initialization failed: $e');
      rethrow;
    } finally {
      _isLocked = false;
    }
  }

  // ─── Start Recording ──────────────────────────────────────────────────────────

  Future<void> startRecording() async {
    if (_isDisposing || _isLocked || _isRecording) {
      debugPrint('CameraService: startRecording() blocked (state invalid)');
      return;
    }
    if (!_isInitialized || _controller == null) {
      debugPrint('CameraService: startRecording() blocked — not initialized');
      return;
    }

    _isLocked = true;
    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      debugPrint('CameraService: Video capture active ✓');
    } catch (e) {
      _isRecording = false;
      debugPrint('CameraService: startRecording error: $e');
      rethrow;
    } finally {
      _isLocked = false;
    }
  }

  // ─── Stop Recording ───────────────────────────────────────────────────────────

  Future<XFile?> stopRecording() async {
    if (_isDisposing || _isLocked) {
      debugPrint('CameraService: stopRecording() blocked (disposing/locked)');
      return null;
    }
    if (!_isRecording || _controller == null) {
      debugPrint('CameraService: stopRecording() called but not recording');
      return null;
    }

    _isLocked = true;
    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;
      debugPrint('CameraService: Video capture stopped ✓');
      return file;
    } catch (e) {
      _isRecording = false;
      debugPrint('CameraService: stopRecording error: $e');
      rethrow;
    } finally {
      _isLocked = false;
    }
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    if (_isDisposing) {
      debugPrint('CameraService: dispose() already in progress — ignored');
      return;
    }

    _isDisposing = true;
    _isLocked = true;

    debugPrint('CameraService: Releasing hardware...');

    try {
      if (_isRecording) {
        try { await _controller?.stopVideoRecording(); } catch (_) {}
        _isRecording = false;
      }

      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _lastDisposedAt = DateTime.now(); // Start cooldown timer
      debugPrint('CameraService: Hardware released ✓ (cooldown started)');
    } catch (e) {
      debugPrint('CameraService: dispose error: $e');
    } finally {
      _isDisposing = false;
      _isLocked = false;
    }
  }
}
