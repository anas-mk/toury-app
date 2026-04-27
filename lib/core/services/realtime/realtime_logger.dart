import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// One row in the realtime debug log.
class RealtimeLogEntry {
  final DateTime at;
  final String source;
  final String name;
  final String? eventId;
  final String summary;
  final bool isError;

  const RealtimeLogEntry({
    required this.at,
    required this.source,
    required this.name,
    required this.summary,
    this.eventId,
    this.isError = false,
  });

  String formatted() {
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    final ss = at.second.toString().padLeft(2, '0');
    final ms = at.millisecond.toString().padLeft(3, '0');
    final id = eventId == null
        ? ''
        : ' eid=${eventId!.substring(0, eventId!.length.clamp(0, 8))}';
    return '$hh:$mm:$ss.$ms [$source] $name$id — $summary';
  }
}

/// Singleton ring-buffer logger for everything realtime / push-related.
///
/// Use this everywhere instead of `debugPrint` so the diagnostics page
/// (`/dev/realtime`) can show the last 100 events. Every call also goes
/// through `debugPrint` so you can grep `RT:` in `flutter run`.
class RealtimeLogger {
  RealtimeLogger._();
  static final RealtimeLogger instance = RealtimeLogger._();

  static const int _maxEntries = 100;
  final Queue<RealtimeLogEntry> _buffer = Queue<RealtimeLogEntry>();
  final StreamController<RealtimeLogEntry> _stream =
      StreamController<RealtimeLogEntry>.broadcast();

  List<RealtimeLogEntry> get entries => _buffer.toList().reversed.toList();
  Stream<RealtimeLogEntry> get stream => _stream.stream;

  void log(
    String source,
    String name,
    String summary, {
    String? eventId,
    bool isError = false,
  }) {
    final entry = RealtimeLogEntry(
      at: DateTime.now(),
      source: source,
      name: name,
      summary: summary,
      eventId: eventId,
      isError: isError,
    );
    _buffer.addLast(entry);
    while (_buffer.length > _maxEntries) {
      _buffer.removeFirst();
    }
    _stream.add(entry);
    debugPrint('RT: ${entry.formatted()}');
  }

  void clear() {
    _buffer.clear();
    _stream.add(RealtimeLogEntry(
      at: DateTime.now(),
      source: 'Logger',
      name: 'cleared',
      summary: 'log cleared',
    ));
  }
}
