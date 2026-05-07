import 'package:dio/dio.dart';

class DirectionsResult {
  final double distanceKm;
  final int? durationSeconds;

  const DirectionsResult({
    required this.distanceKm,
    this.durationSeconds,
  });
}

class DirectionsService {
  DirectionsService({Dio? dio}) : _dio = dio ?? Dio();

  static const _baseUrl = 'https://router.project-osrm.org';

  final Dio _dio;

  Future<DirectionsResult?> estimate({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    if (!_validCoord(fromLat, fromLng) || !_validCoord(toLat, toLng)) {
      return null;
    }
    final url = '$_baseUrl/route/v1/driving/$fromLng,$fromLat;$toLng,$toLat'
        '?overview=false&alternatives=false';
    try {
      final response = await _dio.get<dynamic>(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );
      final data = response.data;
      if (data is! Map) return null;
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final first = routes.first;
      if (first is! Map) return null;
      final distMeters = first['distance'];
      if (distMeters is! num) return null;
      final durSec = first['duration'];
      final km = (distMeters / 1000).toDouble();
      final clamped = km < 0 ? 0.0 : (km > 5000 ? 5000.0 : km);
      return DirectionsResult(
        distanceKm: clamped,
        durationSeconds: durSec is num ? durSec.toInt() : null,
      );
    } catch (_) {
      return null;
    }
  }

  bool _validCoord(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}
