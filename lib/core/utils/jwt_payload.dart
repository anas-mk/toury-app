import 'dart:convert';

/// Lightweight JWT payload reader.
///
/// We do not need cryptographic verification here - the server already did
/// that. The client only wants to read claims like `username` to greet the
/// user without making an extra `/profile` call. Keeping this dependency-free
/// (no `jwt_decoder` package) avoids dragging another dep into the bundle.
class JwtPayload {
  static Map<String, dynamic>? read(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final normalized = base64.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) return json;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Best-effort first name extracted from common claims emitted by our
  /// backend. Falls back to `null` so the caller can render a default.
  static String? firstName(String? token) {
    final payload = read(token);
    if (payload == null) return null;
    final candidates = [
      payload['firstName'],
      payload['given_name'],
      payload['username'],
      payload[
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'],
      payload['name'],
      payload['email'],
    ];
    for (final raw in candidates) {
      if (raw is String && raw.trim().isNotEmpty) {
        final cleaned = raw.trim();
        if (cleaned.contains('@')) {
          return cleaned.split('@').first;
        }
        if (cleaned.contains(' ')) {
          return cleaned.split(' ').first;
        }
        return cleaned;
      }
    }
    return null;
  }
}
