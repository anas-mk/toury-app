/// Tiny helpers for parsing the backend JSON envelopes.
library;

/// Pulls `data` out of an `ApiResponse<T> { success, message, data }`
/// envelope. Throws if `data` is missing — every endpoint we hit returns
/// `data` on success, and a missing `data` is an unrecoverable contract bug.
Map<String, dynamic> envelopeData(Map<String, dynamic> json) {
  if (json['data'] is Map<String, dynamic>) {
    return json['data'] as Map<String, dynamic>;
  }
  throw const FormatException('Response envelope is missing `data` object');
}

/// Same as [envelopeData] but expects a JSON array.
List<dynamic> envelopeDataList(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is List) return data;
  throw const FormatException('Response envelope is missing `data` array');
}

/// Returns `null` if the value is absent or fails to parse.
DateTime? tryParseUtc(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) {
    final s = value.trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toUtc();
  }
  return null;
}

double parseDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    final v = double.tryParse(value);
    if (v != null) return v;
  }
  return fallback;
}

double? parseDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.toInt();
  if (value is String) {
    final v = int.tryParse(value);
    if (v != null) return v;
  }
  return fallback;
}

int? parseIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.toLowerCase().trim();
    if (v == 'true') return true;
    if (v == 'false') return false;
  }
  return fallback;
}

List<String> parseStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
  }
  return const [];
}
