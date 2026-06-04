import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks bookings whose ratings are pending submission.
///
/// Two persisted sets:
///   • `pending_ratings_v1`  — bookings still awaiting a rating.
///   • `submitted_ratings_v1` — bookings whose rating was successfully
///     submitted. [markPending] silently ignores any id already in this
///     set, preventing the mandatory overlay from re-appearing after:
///       - SignalR reconnect replaying a `TripEnded` event.
///       - A second FCM `TripEnded` tap.
///       - Any other stale source calling [markPending] too late.
class PendingRatingTracker {
  PendingRatingTracker({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _pendingKey   = 'pending_ratings_v1';
  static const String _submittedKey = 'submitted_ratings_v1';

  final SharedPreferences _prefs;
  final StreamController<Set<String>> _changes =
      StreamController<Set<String>>.broadcast();

  /// In-memory guard updated SYNCHRONOUSLY by [markSubmitted] so that
  /// any [markPending] call arriving while the async SharedPreferences
  /// write is still in flight is already blocked. Persisted writes back
  /// this up across restarts.
  final Set<String> _sessionSubmitted = {};

  Stream<Set<String>> get changes => _changes.stream;

  // ── Read helpers ───────────────────────────────────────────────────────────

  /// Snapshot of pending booking ids. Safe to call at any time.
  Set<String> peekPending() {
    final raw = _prefs.getStringList(_pendingKey) ?? const <String>[];
    return raw.where((e) => e.isNotEmpty).toSet();
  }

  Set<String> _peekSubmitted() {
    final raw = _prefs.getStringList(_submittedKey) ?? const <String>[];
    return raw.where((e) => e.isNotEmpty).toSet();
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  /// Adds [bookingId] to the pending set.
  ///
  /// No-op if already pending OR already submitted. The in-memory
  /// [_sessionSubmitted] check fires synchronously, blocking any
  /// [markPending] call that races with an in-flight [markSubmitted]
  /// before its SharedPreferences write completes.
  Future<void> markPending(String bookingId) async {
    if (bookingId.isEmpty) return;
    if (_sessionSubmitted.contains(bookingId) ||
        _peekSubmitted().contains(bookingId)) {
      _log('markPending.skip', 'booking=$bookingId — already submitted');
      return;
    }
    final current = peekPending();
    if (current.contains(bookingId)) return;
    current.add(bookingId);
    await _persistPending(current);
    _log('markPending', 'booking=$bookingId total=${current.length}');
  }

  /// Removes [bookingId] from pending and records it as submitted so
  /// future [markPending] calls for the same id are permanently ignored.
  ///
  /// The in-memory [_sessionSubmitted] set is updated SYNCHRONOUSLY so
  /// any concurrent [markPending] call is blocked immediately, before
  /// the async SharedPreferences write completes.
  Future<void> markSubmitted(String bookingId) async {
    if (bookingId.isEmpty) return;
    // Block concurrent markPending calls immediately (sync).
    _sessionSubmitted.add(bookingId);

    final pending = peekPending();
    pending.remove(bookingId);
    await _persistPending(pending);

    final submitted = _peekSubmitted();
    if (submitted.add(bookingId)) {
      await _prefs.setStringList(_submittedKey, submitted.toList());
    }

    _log('markSubmitted', 'booking=$bookingId remaining=${pending.length}');
  }

  /// Wipes both sets. Call on logout so a new user on the same device
  /// starts with a clean slate.
  Future<void> clear() async {
    await _prefs.remove(_pendingKey);
    await _prefs.remove(_submittedKey);
    _changes.add(<String>{});
    _log('clear', 'wiped');
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _persistPending(Set<String> next) async {
    await _prefs.setStringList(_pendingKey, next.toList());
    _changes.add(next);
  }

  void _log(String action, String detail) {
    debugPrint('[Rating] $action $detail');
  }

  Future<void> dispose() async {
    await _changes.close();
  }
}
