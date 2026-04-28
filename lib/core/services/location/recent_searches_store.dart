import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nominatim_service.dart';

/// Simple LRU-style store for the last few places the user picked, kept
/// in `SharedPreferences` so the picker can offer "Recent" rows the
/// instant the bottom sheet opens — no network needed.
class RecentSearchesStore {
  static const _key = 'rafiq.location_picker.recent_v1';
  static const _maxItems = 6;

  Future<List<NominatimResult>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NominatimResult.fromCacheJson)
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[RecentSearches] load error: $e');
      return const [];
    }
  }

  Future<void> add(NominatimResult result) async {
    try {
      final current = await load();
      final filtered = current
          .where((r) =>
              !(r.lat.toStringAsFixed(5) == result.lat.toStringAsFixed(5) &&
                  r.lng.toStringAsFixed(5) == result.lng.toStringAsFixed(5)))
          .toList()
        ..insert(0, result);
      final trimmed =
          filtered.take(_maxItems).map((e) => e.toJson()).toList(growable: false);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(trimmed));
    } catch (e) {
      if (kDebugMode) debugPrint('[RecentSearches] add error: $e');
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
