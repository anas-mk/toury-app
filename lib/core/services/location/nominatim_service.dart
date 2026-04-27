import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// One Nominatim search result.
///
/// `name` is the short human label we render in the dropdown row and that we
/// later persist as the booking's pickup/destination name. `displayName` is
/// Nominatim's full multi-line description.
class NominatimResult {
  final double lat;
  final double lng;
  final String name;
  final String displayName;

  const NominatimResult({
    required this.lat,
    required this.lng,
    required this.name,
    required this.displayName,
  });

  factory NominatimResult.fromSearchJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '') ?? 0;
    final lon = double.tryParse(json['lon']?.toString() ?? '') ?? 0;
    final displayName = (json['display_name'] ?? '').toString();
    return NominatimResult(
      lat: lat,
      lng: lon,
      name: _shortLabelFromSearch(json, displayName),
      displayName: displayName,
    );
  }

  factory NominatimResult.fromReverseJson(
    Map<String, dynamic> json, {
    required double lat,
    required double lng,
  }) {
    final displayName = (json['display_name'] ?? '').toString();
    return NominatimResult(
      lat: lat,
      lng: lng,
      name: _shortLabelFromReverse(json, displayName, lat, lng),
      displayName: displayName,
    );
  }

  static String _shortLabelFromSearch(
    Map<String, dynamic> json,
    String displayName,
  ) {
    final name = (json['name'] ?? '').toString();
    if (name.isNotEmpty) return name;
    final address = json['address'];
    if (address is Map) {
      final picks = [
        address['attraction'],
        address['tourism'],
        address['amenity'],
        address['shop'],
        address['building'],
        address['road'],
        address['suburb'],
        address['neighbourhood'],
        address['city'],
        address['town'],
        address['village'],
      ];
      for (final p in picks) {
        if (p is String && p.trim().isNotEmpty) return p.trim();
      }
    }
    if (displayName.isNotEmpty) {
      return displayName.split(',').first.trim();
    }
    return displayName;
  }

  static String _shortLabelFromReverse(
    Map<String, dynamic> json,
    String displayName,
    double lat,
    double lng,
  ) {
    final address = json['address'];
    if (address is Map) {
      final road = (address['road'] ?? '').toString().trim();
      final neighbourhood = (address['neighbourhood'] ?? '').toString().trim();
      final suburb = (address['suburb'] ?? '').toString().trim();
      final city = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              '')
          .toString()
          .trim();
      final attraction = (address['attraction'] ??
              address['tourism'] ??
              address['amenity'] ??
              '')
          .toString()
          .trim();
      final preferred = [
        if (attraction.isNotEmpty) attraction,
        if (road.isNotEmpty) road,
        if (suburb.isNotEmpty) suburb,
        if (neighbourhood.isNotEmpty) neighbourhood,
        if (city.isNotEmpty) city,
      ];
      if (preferred.isNotEmpty) {
        return preferred.take(2).join(', ');
      }
    }
    if (displayName.isNotEmpty) {
      return displayName.split(',').take(2).join(',').trim();
    }
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}

/// Thin client around the public OpenStreetMap Nominatim API.
///
/// Nominatim REQUIRES a meaningful `User-Agent` (their abuse policy will
/// block clients otherwise), so we always inject one. We also expose the
/// in-flight `CancelToken` so the caller can stop a stale request when the
/// user keeps typing.
class NominatimService {
  static const String _userAgent =
      'RAFIQ-UserApp/1.0 (contact: support@rafiq.app)';
  static const String _searchEndpoint =
      'https://nominatim.openstreetmap.org/search';
  static const String _reverseEndpoint =
      'https://nominatim.openstreetmap.org/reverse';

  final Dio _dio;

  NominatimService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              // Tight timeouts so the search bar surfaces a clear
              // "Search failed. Try again." pill within ~6s instead of
              // sitting on a spinner for almost 20s when Nominatim is
              // slow or the emulator network is flaky.
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 6),
              sendTimeout: const Duration(seconds: 5),
              headers: const {
                'User-Agent': _userAgent,
                'Accept': 'application/json',
              },
              responseType: ResponseType.plain,
            ));

  Future<List<NominatimResult>> search({
    required String query,
    int limit = 6,
    String? acceptLanguage,
    CancelToken? cancelToken,
  }) async {
    if (query.trim().length < 2) return const [];
    try {
      debugPrint('[Nominatim] GET $_searchEndpoint?q=$query');
      final res = await _dio.get<String>(
        _searchEndpoint,
        cancelToken: cancelToken,
        queryParameters: {
          'q': query,
          'format': 'jsonv2',
          'addressdetails': 1,
          'limit': limit,
        },
        options: Options(
          headers: {
            'User-Agent': _userAgent,
            if (acceptLanguage != null) 'Accept-Language': acceptLanguage,
          },
        ),
      );
      final raw = res.data ?? '[]';
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NominatimResult.fromSearchJson)
          .where((r) => r.lat != 0 || r.lng != 0)
          .toList();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return const [];
      debugPrint('[Nominatim] search failed: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[Nominatim] search error: $e');
      rethrow;
    }
  }

  Future<NominatimResult?> reverse({
    required double lat,
    required double lng,
    String? acceptLanguage,
    CancelToken? cancelToken,
  }) async {
    try {
      debugPrint('[Nominatim] GET $_reverseEndpoint?lat=$lat&lon=$lng');
      final res = await _dio.get<String>(
        _reverseEndpoint,
        cancelToken: cancelToken,
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'jsonv2',
          'addressdetails': 1,
          'zoom': 18,
        },
        options: Options(
          headers: {
            'User-Agent': _userAgent,
            if (acceptLanguage != null) 'Accept-Language': acceptLanguage,
          },
        ),
      );
      final raw = res.data;
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return NominatimResult.fromReverseJson(decoded, lat: lat, lng: lng);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      debugPrint('[Nominatim] reverse failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[Nominatim] reverse error: $e');
      return null;
    }
  }
}
