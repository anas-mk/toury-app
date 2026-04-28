import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks bookings whose ratings are pending submission.
///
/// Phase 4 (mandatory rating popup) requirements:
///   1. Persist across app restarts via [SharedPreferences]
///      (key: `pending_ratings_v1`).
///   2. Survive cold start so the popup re-shows even if the user killed
///      the app to skip rating.
///   3. Expose a stream so the overlay can reactively refresh whenever a
///      trip ends (Phase 3 [AppRealtimeCubit] writes new entries) or a
///      rating is submitted.
class PendingRatingTracker {
  PendingRatingTracker({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _prefsKey = 'pending_ratings_v1';

  final SharedPreferences _prefs;
  final StreamController<Set<String>> _changes =
      StreamController<Set<String>>.broadcast();

  /// Emits the full set of pending booking ids whenever it changes.
  /// Always emits the latest snapshot when a listener subscribes.
  Stream<Set<String>> get changes => _changes.stream;

  /// Snapshot of pending booking ids. Safe to call at any time.
  Set<String> peekPending() {
    final raw = _prefs.getStringList(_prefsKey) ?? const <String>[];
    return raw.where((e) => e.isNotEmpty).toSet();
  }

  /// Adds a booking id to the pending set. No-op if already present.
  Future<void> markPending(String bookingId) async {
    if (bookingId.isEmpty) return;
    final current = peekPending();
    if (current.contains(bookingId)) return;
    current.add(bookingId);
    await _persist(current);
    _log('markPending', 'booking=$bookingId total=${current.length}');
  }

  /// Removes a booking id from the pending set. No-op if absent.
  Future<void> markSubmitted(String bookingId) async {
    if (bookingId.isEmpty) return;
    final current = peekPending();
    if (!current.remove(bookingId)) return;
    await _persist(current);
    _log('markSubmitted', 'booking=$bookingId remaining=${current.length}');
  }

  /// Wipes every pending entry. Reserved for logout flows so a new user
  /// signing in on the same device doesn't inherit ghosts.
  Future<void> clear() async {
    await _prefs.remove(_prefsKey);
    _changes.add(<String>{});
    _log('clear', 'wiped');
  }

  Future<void> _persist(Set<String> next) async {
    await _prefs.setStringList(_prefsKey, next.toList());
    _changes.add(next);
  }

  void _log(String action, String detail) {
    debugPrint('[Rating] $action $detail');
  }

  Future<void> dispose() async {
    await _changes.close();
  }
}