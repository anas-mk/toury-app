import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';

/// Strongly-typed result from the Mapbox Directions API.
class RouteResult {
  /// GeoJSON-style coordinates: each element is [longitude, latitude].
  final List<List<double>> coordinates;

  /// Total route distance in metres.
  final double distanceMeters;

  /// Estimated travel time in seconds.
  final double durationSeconds;

  const RouteResult({
    required this.coordinates,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  String get durationLabel {
    final mins = (durationSeconds / 60).round();
    if (mins >= 60) {
      final h = mins ~/ 60;
      final m = mins % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '$mins min';
  }
}

class MapboxDirectionsService {
  final Dio _dio;
  final String _token;

  MapboxDirectionsService({Dio? dio, String? token})
      : _token = token ?? ApiConfig.mapboxToken,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// Fetches a road-following route between two coordinates.
  ///
  /// [profile] can be `'driving'`, `'walking'`, or `'cycling'`.
  /// Returns `null` if the request fails or no route is found — the
  /// caller is expected to draw a straight-line fallback in that case
  /// (we explicitly do NOT throw because the live-track page must
  /// keep rendering even when this network call fails).
  ///
  /// Logging is loud-on-debug and silent-on-release. The most common
  /// failure (and the one that has burned us in the past) is a
  /// missing or invalid `MAPBOX_TOKEN` build-time env var, which
  /// surfaces as `401 Unauthorized` from Mapbox. We log that case
  /// distinctly so the symptom ("straight line on the map") is
  /// immediately diagnosable from `flutter run` logs.
  Future<RouteResult?> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String profile = 'driving',
  }) async {
    if (_token.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[MapboxDirections] MAPBOX_TOKEN is empty — pass it via '
          '`flutter run --dart-define=MAPBOX_TOKEN=pk.xxx` or your '
          'build script. Falling back to a straight line on the map.',
        );
      }
      return null;
    }

    final url =
        '${ApiConfig.mapboxDirectionsEndpoint}/$fromLng,$fromLat;$toLng,$toLat';

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'access_token': _token,
          // Pre-decoded geometry, no manual polyline-decoding needed.
          'geometries': 'geojson',
          // Full geometry, not the over-simplified low-zoom version.
          'overview': 'full',
          // We only need the shape, not turn-by-turn instructions.
          'steps': 'false',
        },
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            '[MapboxDirections] HTTP ${response.statusCode} — '
            '${response.data}',
          );
        }
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[MapboxDirections] No routes returned for '
            '($fromLat,$fromLng) → ($toLat,$toLng)',
          );
        }
        return null;
      }

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final rawCoords = geometry['coordinates'] as List;

      // Mapbox returns `[[lng, lat], [lng, lat], …]`.
      final coordinates = rawCoords.map<List<double>>((c) {
        final pair = c as List;
        return [(pair[0] as num).toDouble(), (pair[1] as num).toDouble()];
      }).toList();

      return RouteResult(
        coordinates: coordinates,
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        final code = e.response?.statusCode;
        final body = e.response?.data;
        if (code == 401) {
          debugPrint(
            '[MapboxDirections] 401 Unauthorized — your MAPBOX_TOKEN '
            'is invalid or expired. Map will fall back to a straight '
            'line. body=$body',
          );
        } else {
          debugPrint('[MapboxDirections] Dio error $code: $e\nbody=$body');
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[MapboxDirections] Error: $e');
      return null;
    }
  }
}
