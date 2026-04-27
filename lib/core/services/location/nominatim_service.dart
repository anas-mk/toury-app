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
  final String? category; // poi / road / address / city ... (used for icons)

  const NominatimResult({
    required this.lat,
    required this.lng,
    required this.name,
    required this.displayName,
    this.category,
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
      category: (json['category'] ?? json['type'])?.toString(),
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
      category: (json['category'] ?? json['type'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'name': name,
        'displayName': displayName,
        if (category != null) 'category': category,
      };

  factory NominatimResult.fromCacheJson(Map<String, dynamic> json) =>
      NominatimResult(
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        name: (json['name'] ?? '').toString(),
        displayName: (json['displayName'] ?? '').toString(),
        category: json['category']?.toString(),
      );

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
///
/// Pass #5 upgrades for Egyptian region coverage:
///  - `countrycodes=eg` biases every search to Egypt first.
///  - Defaults to `Accept-Language: ar,en` so road / district names come
///    back in Arabic when available, with English as a graceful fallback.
///  - Optional viewbox + bounded around the user's current location.
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
    int limit = 8,
    String acceptLanguage = 'ar,en',
    String countryCodes = 'eg',
    double? nearLat,
    double? nearLng,
    CancelToken? cancelToken,
  }) async {
    if (query.trim().length < 2) return const [];
    try {
      final params = <String, dynamic>{
        'q': query,
        'format': 'jsonv2',
        'addressdetails': 1,
        'limit': limit,
        'countrycodes': countryCodes,
        'dedupe': 1,
      };
      // Bias the search around the user's current map view if we have it.
      // ~0.5° box ≈ 55km — good enough to prefer local results without
      // becoming an exclusive bounded search.
      if (nearLat != null && nearLng != null) {
        const span = 0.5;
        params['viewbox'] =
            '${nearLng - span},${nearLat + span},${nearLng + span},${nearLat - span}';
        params['bounded'] = 0;
      }
      if (kDebugMode) {
        debugPrint('[Nominatim] GET $_searchEndpoint q="$query" cc=$countryCodes');
      }
      final res = await _dio.get<String>(
        _searchEndpoint,
        cancelToken: cancelToken,
        queryParameters: params,
        options: Options(
          headers: {
            'User-Agent': _userAgent,
            'Accept-Language': acceptLanguage,
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
      if (kDebugMode) debugPrint('[Nominatim] search failed: ${e.message}');
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[Nominatim] search error: $e');
      rethrow;
    }
  }

  Future<NominatimResult?> reverse({
    required double lat,
    required double lng,
    String acceptLanguage = 'ar,en',
    CancelToken? cancelToken,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[Nominatim] GET $_reverseEndpoint lat=$lat lng=$lng');
      }
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
            'Accept-Language': acceptLanguage,
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
      if (kDebugMode) debugPrint('[Nominatim] reverse failed: ${e.message}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[Nominatim] reverse error: $e');
      return null;
    }
  }
}
