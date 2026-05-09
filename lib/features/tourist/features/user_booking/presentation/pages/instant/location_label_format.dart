import 'location_pick_result.dart';

/// Pure helpers for turning a [LocationPickResult] into a friendly,
/// human-facing label.
///
/// The map picker falls back to a coordinate string (e.g.
/// `"30.09225, 31.26464"`) when reverse-geocoding hasn't completed yet
/// or a road-network lookup failed. Without these helpers, that ugly
/// coordinate ends up rendered verbatim across the booking flow
/// ("MEETING POINT: 30.09225, 31.26464"), which is technically
/// correct but reads like garbage to the user.
///
/// The strategy is:
///   1. Detect whether [LocationPickResult.name] is just raw coords.
///   2. If yes, prefer [LocationPickResult.address] when available.
///   3. Otherwise, surface a friendly placeholder ("Pinned location")
///      and expose the coords as a small subtitle so the data is still
///      visible if the user wants to verify it.
class LocationLabel {
  LocationLabel._();

  /// Matches the picker's coord fallback format
  /// (`"<lat 5dp>, <lng 5dp>"`, e.g. `"30.09225, 31.26464"`). Allows
  /// negative numbers and an arbitrary number of decimals so any
  /// future change in precision still detects the pattern correctly.
  static final RegExp _coordsPattern = RegExp(
    r'^\s*-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?\s*$',
  );

  /// `true` if [name] looks like a raw lat/lng pair instead of a
  /// human-readable place name.
  static bool isCoordinatesOnly(String? name) {
    if (name == null) return true;
    return _coordsPattern.hasMatch(name);
  }

  /// Best-effort human title:
  ///   1. If [LocationPickResult.name] is a real place name → use it.
  ///   2. Else if [LocationPickResult.address] is present → use it.
  ///   3. Else → return [fallback] (default `"Pinned location"`).
  static String title(
    LocationPickResult? loc, {
    String fallback = 'Pinned location',
  }) {
    if (loc == null) return fallback;
    if (!isCoordinatesOnly(loc.name)) return loc.name;
    final addr = (loc.address ?? '').trim();
    if (addr.isNotEmpty && !isCoordinatesOnly(addr)) return addr;
    return fallback;
  }

  /// Optional secondary line (the address). Returned only when it
  /// adds information — i.e. it's not empty and not the same as the
  /// title we'd already show.
  static String? subtitle(LocationPickResult? loc) {
    if (loc == null) return null;
    final t = title(loc);
    final addr = (loc.address ?? '').trim();
    if (addr.isEmpty) return null;
    if (addr == t) return null;
    if (isCoordinatesOnly(addr)) return null;
    return addr;
  }

  /// Compact pickup/destination name used inside small chips and
  /// route visuals — keeps just the first comma segment and
  /// truncates very long names with an ellipsis. Returns the
  /// [fallback] when no place name is available at all.
  static String shortChip(
    LocationPickResult? loc, {
    int maxLen = 18,
    String fallback = 'Pinned location',
  }) {
    final base = title(loc, fallback: fallback);
    final firstSegment = base.split(',').first.trim();
    if (firstSegment.isEmpty) return fallback;
    if (firstSegment.length <= maxLen) return firstSegment;
    return '${firstSegment.substring(0, maxLen - 1)}…';
  }
}
