from pathlib import Path

p = Path("lib/core/services/notifications/messaging_service.dart")
t = p.read_text(encoding="utf-8")
# normalize newlines
t = t.replace("\r\r\n", "\n").replace("\r\n", "\n")

# channel id
t = t.replace("_androidChannelId = 'toury_high_priority'", "_androidChannelId = 'rafiq_default'")
if "_androidChannelId = 'rafiq_default'" not in t and "rafiq_default" not in t:
    raise SystemExit("channel id replace failed")

# add bus import after event_dedup
needle = "import '../realtime/event_dedup_cache.dart';\n\nimport '../realtime/realtime_logger.dart';"
repl = "import '../realtime/booking_realtime_event_bus.dart';\nimport '../realtime/event_dedup_cache.dart';\n\nimport '../realtime/realtime_logger.dart';"
if needle not in t:
    raise SystemExit("import anchor missing")
t = t.replace(needle, repl, 1)

# AndroidNotificationChannel enableVibration
old_ch = """        const channel = AndroidNotificationChannel(

          _androidChannelId,

          _androidChannelName,

          description: _androidChannelDescription,

          importance: Importance.high,

        );"""
new_ch = """        const channel = AndroidNotificationChannel(

          _androidChannelId,

          _androidChannelName,

          description: _androidChannelDescription,

          importance: Importance.high,

          enableVibration: true,

        );"""
if old_ch not in t:
    raise SystemExit("channel block not found")
t = t.replace(old_ch, new_ch, 1)

old_fg = """  void _onForegroundMessage(RemoteMessage message) {

    final data = _stringifyData(message.data);

    final eventId = data['eventId'];

    RealtimeLogger.instance.log(

      'FCM',

      'onMessage',

      'type=${data['notificationType']} '

          'title=${message.notification?.title ?? '-'}',

      eventId: eventId,

    );

    if (data['notificationType'] == 'Test') {

      _postFrameSnackFromRoot('Test push (dev)');

      final eid = eventId?.toString();

      if (eid != null && eid.isNotEmpty) {

        EventDedupCache.instance.mark(eid);

      }

      return;

    }

    final isDup = EventDedupCache.instance.isDuplicate(eventId);

    _showHeadsUp(message, isDuplicate: isDup);

  }"""
new_fg = """  void _onForegroundMessage(RemoteMessage message) {

    final data = _stringifyData(message.data);

    final eventId = message.data['eventId']?.toString();

    RealtimeLogger.instance.log(

      'FCM',

      'foreground',

      'data=${message.data} notification=${message.notification?.title}',

      eventId: eventId,

    );

    if (data['notificationType'] == 'Test') {

      _postFrameSnackFromRoot('Test push (dev)');

      if (eventId != null && eventId.isNotEmpty) {

        EventDedupCache.instance.mark(eventId);

      }

      return;

    }

    final isDup = EventDedupCache.instance.contains(eventId);

    _showHeadsUp(message, isDuplicate: isDup);

    if (!isDup && eventId != null && eventId.isNotEmpty) {

      EventDedupCache.instance.mark(eventId);

    }

  }"""
if old_fg not in t:
    raise SystemExit("foreground block not found")
t = t.replace(old_fg, new_fg, 1)

# insert showInAppBanner + maybeInApp after _onForegroundMessage (before _postFrame)
anchor = """  }



  void _postFrameSnackFromRoot(String text) {"""
insert = """  }



  void showInAppBanner(String title, String body, [Map<String, dynamic>? data]) {

    final line = title.isEmpty

        ? body

        : (body.isEmpty ? title : '$title: $body');

    _postFrameSnackFromRoot(line);

  }



  void maybeInAppBannerFromBusEvent(BookingRealtimeBusEvent e) {

    late final String eventId;

    String title = 'Rafiq';

    String body = '';

    if (e is BusBookingStatusChanged) {

      if (e.event.newStatus != 'Confirmed') return;

      eventId = e.event.eventId;

      title = 'Booking update';

      body = e.event.newStatus;

    } else if (e is BusBookingTripStarted) {

      eventId = e.event.eventId;

      title = 'Trip started';

      body = 'Your trip is underway.';

    } else if (e is BusBookingTripEnded) {

      eventId = e.event.eventId;

      title = 'Trip ended';

      body = 'Time to complete payment.';

    } else if (e is BusBookingPaymentChanged) {

      eventId = e.event.eventId;

      title = 'Payment';

      body = e.event.status;

    } else {

      return;

    }

    if (eventId.isNotEmpty && EventDedupCache.instance.contains(eventId)) {

      return;

    }

    showInAppBanner(title, body);

  }



  void _postFrameSnackFromRoot(String text) {"""
if insert.split("void _postFrame")[1][:20] not in t:  # weak check
    pass
if anchor not in t:
    raise SystemExit("postframe anchor missing")
t = t.replace(anchor, insert, 1)

p.write_text(t, encoding="utf-8", newline="\n")
print("messaging_service patched")