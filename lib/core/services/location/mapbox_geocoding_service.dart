import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../config/api_config.dart';
import 'nominatim_service.dart';

/// Mapbox Geocoding API client (Egypt-biased, Arabic-first).
///
/// Mapbox returns much richer results inside Egypt than Nominatim does —
/// it knows district names, POIs and Arabic place names that OSM is
/// missing. We use it as the *primary* search backend whenever the user
/// has set a public access token, and fall back to Nominatim transparently
/// otherwise (or on any network error).
///
/// To enable the Mapbox backend:
///   1. Sign up at https://account.mapbox.com/ (free tier is fine).
///   2. Copy the "Default public token" (looks like `pk.eyJ1...`).
///   3. Pass it through `--dart-define=MAPBOX_TOKEN=pk.eyJ1...` at run/
///      build time, or set the [token] argument when constructing this
///      service.
///
/// The class is intentionally a thin shim returning the same
/// [NominatimResult] shape so the picker UI doesn't need to know which
/// backend produced a row.
class MapboxGeocodingService {
  static const String _endpoint =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';

  final Dio _dio;
  final String _token;

  MapboxGeocodingService({Dio? dio, String? token})
      : _token = (token == null || token.isEmpty) ? ApiConfig.mapboxToken : token,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 6),
              sendTimeout: const Duration(seconds: 5),
              headers: const {'Accept': 'application/json'},
              responseType: ResponseType.plain,
            ));

  bool get isConfigured => _token.isNotEmpty;

  /// Forward geocoding (text → coordinates).
  ///
  /// Always biases to Egypt (`country=eg`) and prefers Arabic labels with
  /// English fallback. If [proximityLng] / [proximityLat] are provided
  /// Mapbox will rank results closer to that point higher — perfect for
  /// "show me nearby pickup options".
  Future<List<NominatimResult>> search({
    required String query,
    int limit = 8,
    String language = 'ar,en',
    double? proximityLat,
    double? proximityLng,
    CancelToken? cancelToken,
  }) async {
    if (!isConfigured || query.trim().length < 2) return const [];
    final encoded = Uri.encodeComponent(query.trim());
    final url = '$_endpoint/$encoded.json';
    final params = <String, dynamic>{
      'access_token': _token,
      'language': language,
      'country': 'eg',
      'limit': limit,
      'autocomplete': 'true',
      'types': 'address,place,locality,neighborhood,poi,postcode,district',
    };
    if (proximityLat != null && proximityLng != null) {
      params['proximity'] = '$proximityLng,$proximityLat';
    }
    try {
      final res = await _dio.get<String>(
        url,
        cancelToken: cancelToken,
        queryParameters: params,
      );
      return _parseFeatureCollection(res.data);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return const [];
      if (kDebugMode) debugPrint('[Mapbox] search failed: ${e.message}');
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[Mapbox] search error: $e');
      rethrow;
    }
  }

  /// Reverse geocoding (coordinates → human label).
  Future<NominatimResult?> reverse({
    required double lat,
    required double lng,
    String language = 'ar,en',
    CancelToken? cancelToken,
  }) async {
    if (!isConfigured) return null;
    final url = '$_endpoint/$lng,$lat.json';
    try {
      final res = await _dio.get<String>(
        url,
        cancelToken: cancelToken,
        queryParameters: {
          'access_token': _token,
          'language': language,
          'limit': 1,
          'types': 'address,place,locality,neighborhood,poi',
        },
      );
      final list = _parseFeatureCollection(res.data);
      if (list.isEmpty) return null;
      final first = list.first;
      return NominatimResult(
        lat: lat,
        lng: lng,
        name: first.name,
        displayName: first.displayName,
        category: first.category,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      if (kDebugMode) debugPrint('[Mapbox] reverse failed: ${e.message}');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[Mapbox] reverse error: $e');
      return null;
    }
  }

  List<NominatimResult> _parseFeatureCollection(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const [];
      final features = decoded['features'];
      if (features is! List) return const [];
      final out = <NominatimResult>[];
      for (final f in features) {
        if (f is! Map<String, dynamic>) continue;
        final center = f['center'];
        if (center is! List || center.length < 2) continue;
        final lng = (center[0] as num).toDouble();
        final lat = (center[1] as num).toDouble();
        final text = (f['text'] ?? f['text_ar'] ?? '').toString();
        final placeName = (f['place_name'] ??
                f['place_name_ar'] ??
                f['place_name_en'] ??
                '')
            .toString();
        final placeType = (f['place_type'] is List &&
                (f['place_type'] as List).isNotEmpty)
            ? (f['place_type'] as List).first.toString()
            : null;
        out.add(NominatimResult(
          lat: lat,
          lng: lng,
          name: text.isNotEmpty
              ? text
              : (placeName.isNotEmpty
                  ? placeName.split(',').first.trim()
                  : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'),
          displayName: placeName,
          category: placeType,
        ));
      }
      return out;
    } catch (e) {
      if (kDebugMode) debugPrint('[Mapbox] parse error: $e');
      return const [];
    }
  }
}

/// Aggregator that prefers Mapbox when configured, transparently falls
/// back to Nominatim otherwise (or on a Mapbox failure). The picker page
/// only ever talks to this class, so swapping providers / adding a new
/// one stays local.
class GeocodingService {
  final MapboxGeocodingService _mapbox;
  final NominatimService _nominatim;

  GeocodingService({
    MapboxGeocodingService? mapbox,
    NominatimService? nominatim,
  })  : _mapbox = mapbox ?? MapboxGeocodingService(),
        _nominatim = nominatim ?? NominatimService();

  Future<List<NominatimResult>> search({
    required String query,
    int limit = 8,
    String language = 'ar,en',
    double? nearLat,
    double? nearLng,
    CancelToken? cancelToken,
  }) async {
    if (_mapbox.isConfigured) {
      try {
        final r = await _mapbox.search(
          query: query,
          limit: limit,
          language: language,
          proximityLat: nearLat,
          proximityLng: nearLng,
          cancelToken: cancelToken,
        );
        if (r.isNotEmpty) return r;
      } catch (_) {/* fall through to Nominatim */}
    }
    return _nominatim.search(
      query: query,
      limit: limit,
      acceptLanguage: language,
      nearLat: nearLat,
      nearLng: nearLng,
      cancelToken: cancelToken,
    );
  }

  Future<NominatimResult?> reverse({
    required double lat,
    required double lng,
    String language = 'ar,en',
    CancelToken? cancelToken,
  }) async {
    if (_mapbox.isConfigured) {
      try {
        final r = await _mapbox.reverse(
          lat: lat,
          lng: lng,
          language: language,
          cancelToken: cancelToken,
        );
        if (r != null) return r;
      } catch (_) {}
    }
    return _nominatim.reverse(
      lat: lat,
      lng: lng,
      acceptLanguage: language,
      cancelToken: cancelToken,
    );
  }
}
