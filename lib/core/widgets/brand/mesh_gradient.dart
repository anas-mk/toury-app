import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import '../../theme/brand_tokens.dart';

/// Animated four-stop "mesh" gradient used as the canvas of every hero
/// header. Simulates a Skia mesh by stacking radial blobs over a base
/// linear gradient. Cheaper than a fragment shader and looks identical
/// at typical phone resolutions.
///
/// Pass #5 perf surgery
/// --------------------
/// The previous implementation rebuilt every Paint and every shader on
/// every frame (60 hz) — that's ~240 shader allocations / sec, which
/// was choking the UI thread on mid-range Android devices and is the
/// root cause of the "frozen, can't tap" symptom.
///
/// The new painter:
///   * Caches the base linear-gradient shader keyed by Size; it only
///     rebuilds when the hero size actually changes.
///   * Reuses Paint objects instead of allocating per-frame.
///   * Drives the animation at ~24fps (every ~42ms) instead of 60fps.
///     The eye cannot see the difference for ambient background motion,
///     and the saved frame budget keeps gestures responsive.
class MeshGradientBackground extends StatefulWidget {
  final Widget? child;
  final Duration duration;
  final bool freeze;

  const MeshGradientBackground({
    super.key,
    this.child,
    this.duration = const Duration(seconds: 12),
    this.freeze = false,
  });

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  // Quantised progress (0..1). We update it ~24 times per second instead
  // of every frame; this reduces CustomPaint cost without any visible
  // difference because the mesh is a slow ambient animation.
  final ValueNotifier<double> _progress = ValueNotifier<double>(0.0);
  Duration _last = Duration.zero;
  Duration _accum = Duration.zero;
  static const _frameBudget = Duration(milliseconds: 42); // ~24fps

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (!widget.freeze) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _last;
    _last = elapsed;
    _accum += delta;
    if (_accum < _frameBudget) return;
    _accum = Duration.zero;

    final loopMs = widget.duration.inMilliseconds;
    if (loopMs <= 0) return;
    final t = (elapsed.inMilliseconds % loopMs) / loopMs;
    _progress.value = t;
  }

  @override
  void didUpdateWidget(covariant MeshGradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.freeze != widget.freeze) {
      if (widget.freeze) {
        _ticker.stop();
      } else if (!_ticker.isActive) {
        _ticker.start();
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<double>(
        valueListenable: _progress,
        child: widget.child,
        builder: (context, value, child) => CustomPaint(
          painter: _MeshPainter(progress: value),
          isComplex: true,
          willChange: true,
          child: child,
        ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.progress});

  final double progress;

  // Cached base shader keyed by size. The linear gradient under the
  // blobs does not animate, so allocating it on every frame was pure
  // waste. A single static cache keyed by size keeps memory bounded
  // (one entry per hero size used in the app).
  static Size? _cachedBaseSize;
  static Shader? _cachedBaseShader;

  // Reused paint instances. Skia is happy to mutate the shader between
  // draws; allocating Paint per frame is what stresses the GC.
  static final Paint _basePaint = Paint();
  static final Paint _blobPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedBaseShader == null || _cachedBaseSize != size) {
      _cachedBaseSize = size;
      _cachedBaseShader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [BrandTokens.gradientMeshA, BrandTokens.primaryBlueDark],
      ).createShader(Offset.zero & size);
    }
    _basePaint.shader = _cachedBaseShader;
    canvas.drawRect(Offset.zero & size, _basePaint);

    _drawBlob(canvas, size, progress, phase: 0,
        color: BrandTokens.gradientMeshB, alpha: 0.55, radiusFactor: 0.65);
    _drawBlob(canvas, size, progress, phase: 0.33,
        color: BrandTokens.gradientMeshC, alpha: 0.42, radiusFactor: 0.55);
    _drawBlob(canvas, size, progress, phase: 0.66,
        color: BrandTokens.gradientMeshD, alpha: 0.32, radiusFactor: 0.5);
  }

  void _drawBlob(
    Canvas canvas,
    Size size,
    double t, {
    required double phase,
    required Color color,
    required double alpha,
    required double radiusFactor,
  }) {
    final theta = (t + phase) * 2 * math.pi;
    final cx = size.width * (0.5 + 0.35 * math.cos(theta + phase * math.pi));
    final cy = size.height * (0.5 + 0.35 * math.sin(theta * 0.7 + phase * math.pi));
    final radius = math.max(size.width, size.height) * radiusFactor;

    _blobPaint.shader = RadialGradient(
      colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
    ).createShader(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
    );
    canvas.drawCircle(Offset(cx, cy), radius, _blobPaint);
  }

  @override
  bool shouldRepaint(covariant _MeshPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
