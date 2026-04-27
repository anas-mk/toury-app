from pathlib import Path

p = Path("lib/core/services/realtime/booking_realtime_event_bus.dart")
t = p.read_text(encoding="utf-8", errors="replace")
t = t.replace("\r\r\n", "\n").replace("\r\n", "\n")
# fix mojibake comment
t = t.replace("Idempotent", "Idempotent").replace("\ufffd safe", " safe")
if "Idempotent" in t and "safe to call" not in t:
    t = t.replace("Idempotent safe to call", "Idempotent — safe to call")

old = """  Stream<BookingRealtimeBusEvent> get stream => _controller.stream;

  final List<StreamSubscription<dynamic>> _subs = [];

  /// Idempotent"""
new = """  Stream<BookingRealtimeBusEvent> get stream => _controller.stream;

  final List<StreamSubscription<dynamic>> _subs = [];

  /// Optional hook after each event is published (e.g. in-app banner).

  void Function(BookingRealtimeBusEvent event)? onEventPublished;

  /// Idempotent"""
if "onEventPublished" not in t:
    if old not in t:
        raise SystemExit("stream anchor missing")
    t = t.replace(old, new, 1)

old_tap = """    void tap<T>(Stream<T> source, BookingRealtimeBusEvent Function(T) wrap) {
      _subs.add(source.listen((e) => _controller.add(wrap(e))));
    }"""
new_tap = """    void tap<T>(Stream<T> source, BookingRealtimeBusEvent Function(T) wrap) {
      _subs.add(
        source.listen((e) {
          final ev = wrap(e);
          _controller.add(ev);
          onEventPublished?.call(ev);
        }),
      );
    }"""
if new_tap.strip() not in t.replace("\n", "\n"):
    if old_tap not in t:
        raise SystemExit("tap block missing")
    t = t.replace(old_tap, new_tap, 1)

p.write_text(t, encoding="utf-8", newline="\n")
print("bus patched")