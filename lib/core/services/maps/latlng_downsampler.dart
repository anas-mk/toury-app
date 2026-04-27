import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Geometry helpers used to keep map overlays cheap to draw.
///
/// `flutter_map` redraws every polyline point on every map repaint. With a
/// 30-minute trip recorded at 1 Hz that's 1800 points per polyline — at
/// 60 fps that's 108 000 points/s. We Douglas-Peucker downsample to a
/// target point count before passing the list to `Polyline.points`.
class LatLngDownsampler {
  LatLngDownsampler._();

  /// Run Douglas-Peucker until the resulting list has at most [maxPoints]
  /// points. We bisect the epsilon between iterations.
  static List<LatLng> downsample(List<LatLng> input, {int maxPoints = 200}) {
    if (input.length <= maxPoints) return input;

    double lo = 0;
    double hi = 0.001;
    List<LatLng> best = input;
    for (var i = 0; i < 16; i++) {
      final mid = (lo + hi) / 2;
      final out = _douglasPeucker(input, mid);
      if (out.length > maxPoints) {
        lo = mid;
        if (mid >= hi - 1e-9) hi *= 2;
      } else {
        best = out;
        hi = mid;
      }
    }
    return best.length <= maxPoints ? best : _stride(best, maxPoints);
  }

  static List<LatLng> _stride(List<LatLng> pts, int target) {
    if (pts.length <= target) return pts;
    final step = pts.length / target;
    final out = <LatLng>[];
    for (var i = 0; i < target; i++) {
      out.add(pts[(i * step).floor()]);
    }
    out.add(pts.last);
    return out;
  }

  static List<LatLng> _douglasPeucker(List<LatLng> pts, double epsilon) {
    if (pts.length < 3) return pts;
    var maxDist = 0.0;
    var idx = 0;
    final end = pts.length - 1;
    for (var i = 1; i < end; i++) {
      final d = _perpendicularDistance(pts[i], pts.first, pts[end]);
      if (d > maxDist) {
        maxDist = d;
        idx = i;
      }
    }
    if (maxDist > epsilon) {
      final left = _douglasPeucker(pts.sublist(0, idx + 1), epsilon);
      final right = _douglasPeucker(pts.sublist(idx), epsilon);
      return [...left.sublist(0, left.length - 1), ...right];
    }
    return [pts.first, pts.last];
  }

  static double _perpendicularDistance(LatLng p, LatLng a, LatLng b) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    final norm = math.sqrt(dx * dx + dy * dy);
    if (norm == 0) return _haversine(p, a);
    final t = ((p.longitude - a.longitude) * dx +
            (p.latitude - a.latitude) * dy) /
        (norm * norm);
    final px = a.longitude + t * dx;
    final py = a.latitude + t * dy;
    final ddx = p.longitude - px;
    final ddy = p.latitude - py;
    return math.sqrt(ddx * ddx + ddy * ddy);
  }

  static double _haversine(LatLng a, LatLng b) {
    final dx = a.longitude - b.longitude;
    final dy = a.latitude - b.latitude;
    return math.sqrt(dx * dx + dy * dy);
  }
}
