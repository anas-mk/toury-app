import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../theme/brand_tokens.dart';

/// Helpers that paint custom Mapbox-friendly PNG markers in memory so
/// we don't have to bundle PNG assets (and don't depend on the
/// Mapbox Streets sprite — it isn't loaded on the Light style we use,
/// which is why `iconImage: 'marker-15'` showed up as nothing).
///
/// Every helper returns a [Uint8List] you pass to
/// `PointAnnotationOptions(image: …)`. According to the plugin's
/// pigeon contract:
///   > The bitmap image for this Annotation. Will NOT take effect if
///   > [iconImage] has been set.
///
/// So when you switch to these markers, drop the `iconImage` field
/// from the options or the bytes will be ignored silently.
class MapMarkers {
  MapMarkers._();

  /// Pickup pin — primary-blue teardrop, white inner dot.
  /// Used as the start of the journey on the live-track map.
  static Future<Uint8List> pickupPin({double scale = 3.0}) {
    return _teardropPin(
      color: BrandTokens.primaryBlue,
      innerDotColor: const Color(0xFFFFFFFF),
      scale: scale,
    );
  }

  /// Destination pin — warm amber, matches the brand's secondary
  /// accent so it reads visually distinct from the pickup pin.
  static Future<Uint8List> destinationPin({double scale = 3.0}) {
    return _teardropPin(
      color: const Color(0xFF924C00),
      innerDotColor: const Color(0xFFFFFFFF),
      scale: scale,
    );
  }

  /// Live helper marker — orange dot with white halo so it pops on
  /// the light map style and feels alive while the helper moves.
  /// Smaller than a teardrop pin since it's a position, not an
  /// anchored landmark.
  static Future<Uint8List> helperDot({double scale = 3.0}) {
    final size = (44 * scale).toInt();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final center = ui.Offset(size / 2, size / 2);
    final outerR = size / 2 - 2 * scale;
    final innerR = outerR * 0.6;

    // Soft outer halo.
    canvas.drawCircle(
      center,
      outerR + 4 * scale,
      ui.Paint()
        ..color = const Color(0xFFFE9331).withValues(alpha: 0.20)
        ..style = ui.PaintingStyle.fill,
    );
    // White ring (border).
    canvas.drawCircle(
      center,
      outerR,
      ui.Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.fill,
    );
    // Filled accent dot.
    canvas.drawCircle(
      center,
      innerR,
      ui.Paint()
        ..color = const Color(0xFFFE9331)
        ..style = ui.PaintingStyle.fill,
    );

    return _toPng(recorder, size, size);
  }

  /// Generic teardrop pin used by [pickupPin] and [destinationPin].
  /// Roughly 30 × 40 logical px, scaled by [scale] for retina-quality
  /// rendering on the map.
  static Future<Uint8List> _teardropPin({
    required Color color,
    required Color innerDotColor,
    double scale = 3.0,
  }) async {
    final w = (30 * scale).toInt();
    final h = (40 * scale).toInt();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final cx = w / 2;
    final headRadius = (w / 2 - scale).toDouble();

    // Drop shadow (blurred ellipse below the pin).
    final shadowPath = ui.Path()
      ..addOval(
        ui.Rect.fromCenter(
          center: ui.Offset(cx, h - 2 * scale),
          width: w * 0.55,
          height: 4 * scale,
        ),
      );
    canvas.drawPath(
      shadowPath,
      ui.Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.18)
        ..maskFilter = ui.MaskFilter.blur(
          ui.BlurStyle.normal,
          2 * scale,
        ),
    );

    // Build the teardrop: a circle for the head, plus a triangle
    // pointing down to the geographic anchor.
    final pinPath = ui.Path()
      ..moveTo(cx - headRadius * 0.55, headRadius * 1.25)
      ..lineTo(cx, h - 4 * scale)
      ..lineTo(cx + headRadius * 0.55, headRadius * 1.25)
      ..close()
      ..addOval(
        ui.Rect.fromCircle(
          center: ui.Offset(cx, headRadius + scale),
          radius: headRadius,
        ),
      );

    // White outline first, then the coloured body — gives the pin a
    // crisp edge on busy map tiles.
    canvas.drawPath(
      pinPath,
      ui.Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 4 * scale
        ..strokeJoin = ui.StrokeJoin.round,
    );
    canvas.drawPath(
      pinPath,
      ui.Paint()
        ..color = color
        ..style = ui.PaintingStyle.fill,
    );

    // Inner white dot (anchor).
    canvas.drawCircle(
      ui.Offset(cx, headRadius + scale),
      headRadius * 0.42,
      ui.Paint()
        ..color = innerDotColor
        ..style = ui.PaintingStyle.fill,
    );

    return _toPng(recorder, w, h);
  }

  static Future<Uint8List> _toPng(
    ui.PictureRecorder recorder,
    int width,
    int height,
  ) async {
    final picture = recorder.endRecording();
    final img = await picture.toImage(width, height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('MapMarkers: failed to encode marker as PNG');
    }
    return byteData.buffer.asUint8List();
  }
}
