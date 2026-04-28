import 'package:flutter/foundation.dart';

/// Surfaces non-fatal UI when the booking hub drops with an auth-shaped
/// failure (so we do not spin reconnect forever without feedback).
class RealtimeConnectionIssueNotifier extends ChangeNotifier {
  bool showAuthBanner = false;
  String bannerMessage =
      'Live updates paused (session issue). Open menu and try again, or pull to refresh.';

  static bool looksAuthRelated(Object? error) {
    final t = error?.toString() ?? '';
    final lower = t.toLowerCase();
    return lower.contains('401') ||
        lower.contains('403') ||
        lower.contains('unauthorized') ||
        lower.contains('forbidden') ||
        lower.contains('not authorized');
  }

  void reportHubClosedWithPossibleAuthIssue(Object? error) {
    if (!looksAuthRelated(error)) return;
    showAuthBanner = true;
    notifyListeners();
  }

  void clear() {
    if (!showAuthBanner) return;
    showAuthBanner = false;
    notifyListeners();
  }
}
