import 'dart:async';

import '../signalr/booking_hub_events.dart';
import '../signalr/booking_tracking_hub_service.dart';
import 'realtime_logger.dart';

/// Fan-in envelope (single broadcast stream for the user app).
abstract class BookingRealtimeBusEvent {
  const BookingRealtimeBusEvent();
}

class BusBookingStatusChanged extends BookingRealtimeBusEvent {
  final BookingStatusChangedEvent event;
  const BusBookingStatusChanged(this.event);
}

class BusBookingCancelled extends BookingRealtimeBusEvent {
  final BookingCancelledEvent event;
  const BusBookingCancelled(this.event);
}

class BusBookingPaymentChanged extends BookingRealtimeBusEvent {
  final BookingPaymentChangedEvent event;
  const BusBookingPaymentChanged(this.event);
}

class BusBookingTripStarted extends BookingRealtimeBusEvent {
  final BookingTripStartedEvent event;
  const BusBookingTripStarted(this.event);
}

class BusBookingTripEnded extends BookingRealtimeBusEvent {
  final BookingTripEndedEvent event;
  const BusBookingTripEnded(this.event);
}

class BusHelperLocationUpdate extends BookingRealtimeBusEvent {
  final HelperLocationUpdateEvent event;
  const BusHelperLocationUpdate(this.event);
}

class BusChatMessage extends BookingRealtimeBusEvent {
  final ChatMessagePushEvent event;
  const BusChatMessage(this.event);
}

class BusHelperReportResolved extends BookingRealtimeBusEvent {
  final HelperReportResolvedEvent event;
  const BusHelperReportResolved(this.event);
}

class BusReportResolved extends BookingRealtimeBusEvent {
  final ReportResolvedEvent event;
  const BusReportResolved(this.event);
}

class BusPong extends BookingRealtimeBusEvent {
  final PongEvent event;
  const BusPong(this.event);
}

/// Subscribes once at app boot to [BookingTrackingHubService] typed streams
/// and republishes onto a single broadcast [stream].
class BookingRealtimeEventBus {
  BookingRealtimeEventBus._();
  static final BookingRealtimeEventBus instance = BookingRealtimeEventBus._();

  final StreamController<BookingRealtimeBusEvent> _controller =
      StreamController<BookingRealtimeBusEvent>.broadcast();

  Stream<BookingRealtimeBusEvent> get stream => _controller.stream;

  final List<StreamSubscription<dynamic>> _subs = [];

  /// Idempotent — safe to call again; cancels prior fan-in taps.
  void attach(BookingTrackingHubService hub) {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();

    void tap<T>(Stream<T> source, BookingRealtimeBusEvent Function(T) wrap) {
      _subs.add(source.listen((e) => _controller.add(wrap(e))));
    }

    tap(hub.bookingStatusChangedStream, BusBookingStatusChanged.new);
    tap(hub.bookingCancelledStream, BusBookingCancelled.new);
    tap(hub.bookingPaymentChangedStream, BusBookingPaymentChanged.new);
    tap(hub.bookingTripStartedStream, BusBookingTripStarted.new);
    tap(hub.bookingTripEndedStream, BusBookingTripEnded.new);
    tap(hub.helperLocationUpdateStream, BusHelperLocationUpdate.new);
    tap(hub.chatMessageStream, BusChatMessage.new);
    tap(hub.helperReportResolvedStream, BusHelperReportResolved.new);
    tap(hub.reportResolvedStream, BusReportResolved.new);
    tap(hub.pongStream, BusPong.new);

    RealtimeLogger.instance.log(
      'SignalR',
      'bus.attach',
      'fan-in attached (server handlers still on hub)',
    );
  }
}
