import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'brand_tokens.dart';

/// Warms up the Skia shader cache for every gradient + shadow combo the
/// brand kit uses, so the user never sees the 30-80 ms first-tap compile
/// stall on Android.
///
/// Skia compiles shaders the first time they are needed. The brand kit
/// uses a dozen distinct gradients (blue CTA, amber CTA, mesh hero,
/// success, danger, etc.) and several colored-shadow combos — without
/// warming, every one of those produces a single jank frame the first
/// time it appears.
///
/// We rasterize a one-frame `Picture` containing a small example of each
/// gradient + shadow on a tiny offscreen surface. The work is done
/// post-first-frame (so we don't delay startup) and never appears on screen.
abstract class ShaderWarmup {
  static bool _done = false;

  static Future<void> warmUp() async {
    if (_done) return;
    _done = true;

    // Run as a microtask after the next frame so we don't fight the scheduler
    // on the very-first-frame path.
    SchedulerBinding.instance.scheduleTask<void>(
      _paint,
      Priority.idle,
    );
  }

  static Future<void> _paint() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      // Each gradient gets a small rect; offscreen, never composited.
      const w = 32.0;
      const h = 32.0;
      double y = 0;

      for (final gradient in <List<ui.Color>>[
        const [BrandTokens.primaryBlue, BrandTokens.primaryBlueDark],
        const [BrandTokens.gradientMeshA, BrandTokens.gradientMeshB],
        const [BrandTokens.gradientMeshC, BrandTokens.gradientMeshD],
        const [BrandTokens.accentAmber, BrandTokens.warningAmber],
        const [BrandTokens.successGreen, BrandTokens.gradientMeshB],
        const [BrandTokens.dangerRed, BrandTokens.dangerRedSoft],
      ]) {
        final shader = ui.Gradient.linear(
          ui.Offset(0, y),
          ui.Offset(w, y + h),
          gradient,
        );
        final paint = ui.Paint()..shader = shader;
        canvas.drawRRect(
          ui.RRect.fromLTRBR(0, y, w, y + h, const ui.Radius.circular(8)),
          paint,
        );

        // Colored shadow shader (a blurred MaskFilter pass).
        final shadow = ui.Paint()
          ..color = gradient.first.withValues(alpha: 0.4)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
        canvas.drawRRect(
          ui.RRect.fromLTRBR(w + 4, y, w + 4 + w, y + h, const ui.Radius.circular(8)),
          shadow,
        );

        y += h + 4;
      }

      final picture = recorder.endRecording();
      // toImage forces Skia to actually rasterize, which is what compiles the
      // shader. We immediately dispose because we never want the bytes.
      final image = await picture.toImage(64, y.toInt() + 8);
      image.dispose();
      picture.dispose();
    } catch (e) {
      if (kDebugMode) debugPrint('ShaderWarmup failed: $e');
    }
  }
}
