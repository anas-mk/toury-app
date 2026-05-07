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
    return '${mins} min';
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

  /// Fetches a road route between two coordinates.
  ///
  /// [profile] can be `'driving'`, `'walking'`, or `'cycling'`.
  /// Returns `null` if the request fails or no route is found.
  Future<RouteResult?> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String profile = 'driving',
  }) async {
    final url =
        '${ApiConfig.mapboxDirectionsEndpoint}/$fromLng,$fromLat;$toLng,$toLat';

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'access_token': _token,
          'geometries': 'geojson', // pre-decoded coordinates, no manual decoding needed
          'overview': 'full',     // full geometry, not simplified
          'steps': 'false',       // we only need the shape, not turn-by-turn
        },
      );

      if (response.statusCode != 200) return null;

      final data = response.data as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final rawCoords = geometry['coordinates'] as List;

      // Mapbox returns [[lng, lat], [lng, lat], ...]
      final coordinates = rawCoords.map<List<double>>((c) {
        final pair = c as List;
        return [(pair[0] as num).toDouble(), (pair[1] as num).toDouble()];
      }).toList();

      return RouteResult(
        coordinates: coordinates,
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[MapboxDirections] Error: $e');
      return null;
    }
  }
}
