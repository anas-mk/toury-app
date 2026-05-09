import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single persisted helper location snapshot, used to keep the live
/// tracking screen useful even when the device's network drops or the
/// helper's GPS pauses (e.g. tunnel, low-signal area, screen-off).
///
/// The shape is intentionally a strict subset of the wire format —
/// just enough to render a marker, an ETA hint, and a "last seen X
/// ago" label.
@immutable
class LastHelperLocation {
  final String bookingId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKmh;

  /// Backend-computed ETA-to-pickup at the time this sample was sent.
  final int? etaToPickupMinutes;

  /// Backend-computed ETA-to-destination at the time this sample was sent.
  final int? etaToDestinationMinutes;

  /// `"OnTheWay"` (pre-`/start`) or `"InProgress"` (after `/start`).
  /// Used by the UI to decide which ETA to surface.
  final String? phase;

  /// When the snapshot landed on the server (not when we cached it).
  /// Drives the "X min ago" staleness label.
  final DateTime capturedAt;

  const LastHelperLocation({
    required this.bookingId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speedKmh,
    this.etaToPickupMinutes,
    this.etaToDestinationMinutes,
    this.phase,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
        'bookingId': bookingId,
        'latitude': latitude,
        'longitude': longitude,
        if (heading != null) 'heading': heading,
        if (speedKmh != null) 'speedKmh': speedKmh,
        if (etaToPickupMinutes != null)
          'etaToPickupMinutes': etaToPickupMinutes,
        if (etaToDestinationMinutes != null)
          'etaToDestinationMinutes': etaToDestinationMinutes,
        if (phase != null) 'phase': phase,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
      };

  static LastHelperLocation? fromJson(Map<String, dynamic> json) {
    try {
      return LastHelperLocation(
        bookingId: json['bookingId'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
        speedKmh: (json['speedKmh'] as num?)?.toDouble(),
        etaToPickupMinutes: (json['etaToPickupMinutes'] as num?)?.toInt(),
        etaToDestinationMinutes:
            (json['etaToDestinationMinutes'] as num?)?.toInt(),
        phase: json['phase'] as String?,
        capturedAt: DateTime.parse(json['capturedAt'] as String).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  /// How long ago this snapshot was captured. Useful for stale-data
  /// labels like "Last seen 3 min ago" when GPS goes silent.
  Duration get ageFromNow =>
      DateTime.now().toUtc().difference(capturedAt.toUtc());
}

/// Singleton cache for the freshest helper location we've heard about
/// — per booking. Backed by SharedPreferences so the value survives
/// app restarts and SignalR disconnections.
///
/// Usage:
///   - Call [save] from every `HelperLocationUpdate` handler.
///   - Call [load] when a screen mounts so the helper marker can be
///     drawn on first paint, even before the next realtime tick.
///   - Call [clear] when the trip ends or the booking is cancelled.
class LastHelperLocationStore {
  LastHelperLocationStore._();

  static final LastHelperLocationStore instance =
      LastHelperLocationStore._();

  static const _keyPrefix = 'last_helper_loc::';

  /// In-memory cache so reads in the same session don't hit disk.
  final Map<String, LastHelperLocation> _memory = {};

  String _keyFor(String bookingId) => '$_keyPrefix$bookingId';

  /// Persists the latest known location. Best-effort; failures are
  /// logged in debug only — the live stream remains source of truth.
  Future<void> save(LastHelperLocation snapshot) async {
    _memory[snapshot.bookingId] = snapshot;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyFor(snapshot.bookingId),
        jsonEncode(snapshot.toJson()),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LastHelperLocationStore] save error: $e');
      }
    }
  }

  /// Returns the freshest cached snapshot for [bookingId], or `null`
  /// if we don't have one. In-memory hits skip disk.
  Future<LastHelperLocation?> load(String bookingId) async {
    final cached = _memory[bookingId];
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyFor(bookingId));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final snapshot = LastHelperLocation.fromJson(decoded);
        if (snapshot != null) {
          _memory[bookingId] = snapshot;
        }
        return snapshot;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LastHelperLocationStore] load error: $e');
      }
      return null;
    }
  }

  /// Drops the cached entry for [bookingId] — call this when the
  /// trip ends or the booking is cancelled, so the next instant
  /// trip with the same id (rare but possible) doesn't pick up a
  /// stale marker.
  Future<void> clear(String bookingId) async {
    _memory.remove(bookingId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyFor(bookingId));
    } catch (_) {/* best effort */}
  }
}
