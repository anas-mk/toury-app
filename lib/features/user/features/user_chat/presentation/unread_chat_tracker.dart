import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../../core/services/signalr/booking_hub_events.dart';
import '../../../../../core/services/signalr/booking_tracking_hub_service.dart';

/// App-wide tracker for unread chat messages, keyed by `bookingId`.
///
/// It subscribes to the booking-tracking hub's `chatMessageStream`
/// (which already runs for the lifetime of the session, regardless
/// of which page the user is on) and increments an in-memory counter
/// per booking whenever a message arrives **for someone other than
/// the user themselves**.
///
/// Pages that show a chat icon (live track map, booking confirmed)
/// can listen via [unreadStreamFor] to render a red dot or a number
/// badge. When the user opens the chat for that booking they call
/// [markAllRead] to clear it.
class UnreadChatTracker extends ChangeNotifier {
  UnreadChatTracker._(this._hub) {
    _sub = _hub.chatMessageStream.listen(_onMessage);
  }

  static UnreadChatTracker? _instance;

  /// Singleton accessor — wired in `main.dart` once the hub is
  /// available so we don't have to plumb DI through every page.
  static UnreadChatTracker get instance {
    final i = _instance;
    if (i == null) {
      throw StateError(
        'UnreadChatTracker.attach(...) must be called once at '
        'app bootstrap before reading instance.',
      );
    }
    return i;
  }

  static void attach(BookingTrackingHubService hub) {
    _instance ??= UnreadChatTracker._(hub);
  }

  final BookingTrackingHubService _hub;
  StreamSubscription<ChatMessagePushEvent>? _sub;

  /// `bookingId` → unread count.
  final Map<String, int> _unread = {};

  /// `bookingId` of the chat the user is *currently looking at*,
  /// if any. While set, incoming messages for this booking are
  /// considered immediately read (they're rendered in the bubbles
  /// list anyway).
  String? _activeBookingId;

  /// Per-booking broadcast streams so a page can rebuild precisely
  /// when its booking's count changes (instead of all listeners
  /// rebuilding on every message).
  final Map<String, StreamController<int>> _streams = {};

  /// Returns the current unread count for [bookingId] (0 if never
  /// received a message).
  int countFor(String bookingId) => _unread[bookingId] ?? 0;

  /// Stream of unread counts for [bookingId]. Emits an immediate
  /// initial value on subscription so widgets paint correctly on
  /// first build.
  Stream<int> unreadStreamFor(String bookingId) {
    final c = _streams.putIfAbsent(
      bookingId,
      () => StreamController<int>.broadcast(),
    );
    // Replay the current value to new listeners on the next tick so
    // a `StreamBuilder(initialData: …)` doesn't have to be paired
    // with manual seeding everywhere.
    scheduleMicrotask(() {
      if (!c.isClosed) c.add(countFor(bookingId));
    });
    return c.stream;
  }

  /// Tell the tracker the user just opened the chat for [bookingId]
  /// — increments arriving from now on are auto-marked read until
  /// [setInactive] (or another booking becomes active).
  void setActive(String bookingId) {
    _activeBookingId = bookingId;
    if ((_unread[bookingId] ?? 0) != 0) {
      _unread[bookingId] = 0;
      _emit(bookingId);
      notifyListeners();
    }
  }

  /// Tell the tracker the user left the chat for [bookingId].
  void setInactive(String bookingId) {
    if (_activeBookingId == bookingId) {
      _activeBookingId = null;
    }
  }

  /// Force-clear the unread counter for [bookingId] without
  /// changing the active booking. Useful from a "mark as read"
  /// button or after a successful API call.
  void markAllRead(String bookingId) {
    if ((_unread[bookingId] ?? 0) == 0) return;
    _unread[bookingId] = 0;
    _emit(bookingId);
    notifyListeners();
  }

  /// Drops everything for [bookingId] — call when the booking is
  /// cancelled / completed so a future booking with the same id
  /// doesn't inherit a stale counter.
  void clear(String bookingId) {
    _unread.remove(bookingId);
    _emit(bookingId);
    notifyListeners();
  }

  void _onMessage(ChatMessagePushEvent event) {
    // Only count messages addressed to the user themselves. The
    // realtime guide (§ 9.3) guarantees the sender never echoes
    // back to themselves, so any message we receive is incoming
    // by definition — but we still gate on `senderType` so any
    // future broadcast (system message, etc.) doesn't mis-count.
    final fromUser = event.senderType?.toLowerCase() == 'user';
    if (fromUser) return;
    final bookingId = event.bookingId;
    if (bookingId.isEmpty) return;
    // If the user is watching this conversation right now, the
    // chat page renders the bubble immediately — no badge needed.
    if (_activeBookingId == bookingId) return;
    final next = (_unread[bookingId] ?? 0) + 1;
    _unread[bookingId] = next;
    _emit(bookingId);
    notifyListeners();
  }

  void _emit(String bookingId) {
    final c = _streams[bookingId];
    if (c == null || c.isClosed) return;
    c.add(_unread[bookingId] ?? 0);
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final c in _streams.values) {
      c.close();
    }
    _streams.clear();
    super.dispose();
  }
}

/// Tiny helper — `null` if [count] == 0, else a short label.
/// Keeps badge widgets concise (e.g. `"9+"` for very chatty trips).
String? formatBadgeCount(int count) {
  if (count <= 0) return null;
  if (count > 9) return '9+';
  return count.toString();
}

/// Module-level convenience — guards against the tracker not being
/// attached yet (e.g. in tests). Useful for quick widget usage.
@visibleForTesting
int unreadCountFor(String bookingId) {
  if (UnreadChatTracker._instance == null) return 0;
  return UnreadChatTracker.instance.countFor(bookingId);
}
