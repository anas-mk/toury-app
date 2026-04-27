import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Production-grade debouncer + in-memory LRU cache for autocomplete
/// search inputs (Mapbox / Nominatim).
///
/// Goals:
///   - Fire one network request per *thought*, not per keystroke.
///   - Cancel any in-flight stale request the moment the user types
///     another character.
///   - De-duplicate trailing identical queries (e.g. user pastes the
///     same string twice, focus thrash, etc.).
///   - Cache the last N successful query → results pairs in memory so
///     repeated queries (back/forward through suggestions, repeated
///     typing of the same prefix) feel instant and free.
///
/// Why 400ms?
///   - Sub-300ms feels jumpy and burns API quota — a typist easily
///     pauses 250ms between keys, which would fire one request per
///     letter.
///   - 500ms+ feels laggy, the dropdown visibly trails the user.
///   - 350–450ms is the standard recommendation across Google
///     Material guidelines, Algolia and Mapbox's own docs. We pick
///     the sweet spot at **400 ms** — you stop typing for ~half a
///     beat and results pop in almost instantly.
class SearchDebouncer<T> {
  /// How long to wait after the *last* keystroke before firing.
  final Duration delay;

  /// Minimum query length before any work is done. Mapbox / Nominatim
  /// both perform poorly on 1–2 char prefixes.
  final int minLength;

  /// LRU cache capacity. 32 is plenty for one map session — typical
  /// users explore 5–10 unique queries before confirming.
  final int cacheSize;

  /// The actual fetcher. Receives the trimmed query and a CancelToken
  /// the debouncer will cancel when the query becomes stale.
  final Future<List<T>> Function(String query, CancelToken cancelToken)
      fetcher;

  /// Optional normaliser for cache keys (lowercases + collapses
  /// whitespace by default). Override if you want stricter / looser
  /// hits.
  final String Function(String raw) normaliseKey;

  Timer? _timer;
  CancelToken? _inFlight;
  String? _lastFiredKey;

  // Insertion-order LinkedHashMap doubles as our LRU: on hit, we
  // remove + re-insert to bump recency.
  final LinkedHashMap<String, List<T>> _cache = LinkedHashMap();

  SearchDebouncer({
    required this.fetcher,
    this.delay = const Duration(milliseconds: 400),
    this.minLength = 3,
    this.cacheSize = 32,
    String Function(String raw)? normaliseKey,
  }) : normaliseKey = normaliseKey ?? _defaultNormalise;

  static String _defaultNormalise(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Synchronous cache lookup. Returns `null` on miss. Use this from
  /// the caller's `onChanged` to render cached rows instantly while a
  /// new debounced request may be queued.
  List<T>? cachedFor(String raw) {
    final key = normaliseKey(raw);
    if (key.length < minLength) return null;
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit;
      return hit;
    }
    return null;
  }

  /// Schedule a search. The result is delivered through callbacks so
  /// the caller doesn't have to manage Futures from inside an
  /// onChanged handler.
  ///
  /// - [onResult] fires once the network call completes (or the cache
  ///   was used).
  /// - [onError] fires on any non-cancellation failure.
  /// - [onSkipped] fires if we deliberately skipped the request
  ///   (too short, duplicate, cancelled). The caller can use it to
  ///   clear the spinner.
  void schedule(
    String raw, {
    required void Function(String key, List<T> results) onResult,
    required void Function(String key, Object error) onError,
    void Function(String key, SearchSkipReason reason)? onSkipped,
  }) {
    _timer?.cancel();
    final key = normaliseKey(raw);

    // Below threshold → drop everything, never hit the network.
    if (key.length < minLength) {
      _inFlight?.cancel('below-threshold');
      _inFlight = null;
      onSkipped?.call(key, SearchSkipReason.tooShort);
      return;
    }

    // Cache hit → fire synchronously, no debounce needed.
    final cached = cachedFor(raw);
    if (cached != null) {
      _inFlight?.cancel('cache-hit');
      _inFlight = null;
      _lastFiredKey = key;
      onResult(key, cached);
      return;
    }

    // Identical key as the last fired one and a request is in flight
    // → don't queue another one, the existing future will resolve.
    if (key == _lastFiredKey && _inFlight != null && !_inFlight!.isCancelled) {
      onSkipped?.call(key, SearchSkipReason.duplicate);
      return;
    }

    _timer = Timer(delay, () => _fire(key, onResult, onError, onSkipped));
  }

  Future<void> _fire(
    String key,
    void Function(String key, List<T> results) onResult,
    void Function(String key, Object error) onError,
    void Function(String key, SearchSkipReason reason)? onSkipped,
  ) async {
    // Re-check cache one more time — the user may have typed the
    // same prefix while we were waiting on `delay`.
    final cached = _cache[key];
    if (cached != null) {
      _lastFiredKey = key;
      onResult(key, cached);
      return;
    }

    _inFlight?.cancel('superseded');
    final token = CancelToken();
    _inFlight = token;
    _lastFiredKey = key;

    try {
      final results = await fetcher(key, token);
      if (token.isCancelled) {
        onSkipped?.call(key, SearchSkipReason.cancelled);
        return;
      }
      _putInCache(key, results);
      onResult(key, results);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || token.isCancelled) {
        onSkipped?.call(key, SearchSkipReason.cancelled);
        return;
      }
      if (kDebugMode) debugPrint('[SearchDebouncer] $key error: $e');
      onError(key, e);
    } catch (e) {
      if (token.isCancelled) {
        onSkipped?.call(key, SearchSkipReason.cancelled);
        return;
      }
      if (kDebugMode) debugPrint('[SearchDebouncer] $key error: $e');
      onError(key, e);
    }
  }

  void _putInCache(String key, List<T> results) {
    if (_cache.containsKey(key)) _cache.remove(key);
    _cache[key] = results;
    while (_cache.length > cacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Forget any pending timer + cancel any in-flight request.
  /// Call from State.dispose().
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _inFlight?.cancel('disposed');
    _inFlight = null;
    _cache.clear();
  }

  /// Clear in-flight + pending without touching the cache. Use when
  /// the search field is cleared.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _inFlight?.cancel('cleared');
    _inFlight = null;
    _lastFiredKey = null;
  }
}

/// Reasons the debouncer chose NOT to deliver a network result.
/// Surfaced through `onSkipped` so the UI can react (e.g. hide
/// spinner, fall back to a "Recent" panel, etc.).
enum SearchSkipReason { tooShort, duplicate, cancelled }
