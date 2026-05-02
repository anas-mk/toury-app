import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Lenient JSON helpers
//
// SignalR's .NET JSON serializer ships keys in PascalCase (`BookingId`),
// but `signalr_netcore` lowercases the first letter on the wire (`bookingId`).
// FCM data payloads are camelCase (`bookingId`). We therefore look up keys
// case-insensitively to be safe in both directions.
// ─────────────────────────────────────────────────────────────────────────────

dynamic _readKey(Map raw, String key) {
  if (raw.containsKey(key)) return raw[key];
  // PascalCase variant.
  final pascal = key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';
  if (raw.containsKey(pascal)) return raw[pascal];
  // Last resort: case-insensitive scan.
  final lower = key.toLowerCase();
  for (final k in raw.keys) {
    if (k is String && k.toLowerCase() == lower) return raw[k];
  }
  return null;
}

String? _str(Map raw, String key) => _readKey(raw, key)?.toString();

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toUtc();
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toUtc();
  return null;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Common envelope
// ─────────────────────────────────────────────────────────────────────────────

/// All booking-derived events share this header. Pulled out so the dedup
/// cache, logger, and router can read it generically.
mixin EventEnvelope {
  String get eventId;
  DateTime? get occurredAt;
  int? get version;
}

/// Pulls `EventId` / `OccurredAt` / `V` (or their camelCase siblings).
({String eventId, DateTime? occurredAt, int? version}) _readEnvelope(Map raw) {
  return (
    eventId: _str(raw, 'eventId') ?? '',
    occurredAt: _parseDate(_readKey(raw, 'occurredAt')),
    version: _toInt(_readKey(raw, 'v')) ?? _toInt(_readKey(raw, 'version')),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking lifecycle events
// ─────────────────────────────────────────────────────────────────────────────

class BookingStatusChangedEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String bookingId;
  final String? userId;
  final String? helperId;
  final String oldStatus;
  final String newStatus;
  final String? paymentStatus;

  const BookingStatusChangedEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.bookingId,
    this.userId,
    this.helperId,
    required this.oldStatus,
    required this.newStatus,
    this.paymentStatus,
  });

  factory BookingStatusChangedEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return BookingStatusChangedEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      bookingId: _str(map, 'bookingId') ?? '',
      userId: _str(map, 'userId'),
      helperId: _str(map, 'helperId'),
      oldStatus: _str(map, 'oldStatus') ?? '',
      newStatus: _str(map, 'newStatus') ?? '',
      paymentStatus: _str(map, 'paymentStatus'),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        bookingId,
        userId,
        helperId,
        oldStatus,
        newStatus,
        paymentStatus,
      ];
}

class BookingCancelledEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String bookingId;
  final String? userId;
  final String? helperId;
  final String? cancelledBy;
  final String? reason;

  const BookingCancelledEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.bookingId,
    this.userId,
    this.helperId,
    this.cancelledBy,
    this.reason,
  });

  factory BookingCancelledEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return BookingCancelledEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      bookingId: _str(map, 'bookingId') ?? '',
      userId: _str(map, 'userId'),
      helperId: _str(map, 'helperId'),
      cancelledBy: _str(map, 'cancelledBy'),
      reason: _str(map, 'reason'),
    );
  }

  @override
  List<Object?> get props =>
      [eventId, bookingId, userId, helperId, cancelledBy, reason];
}

class BookingPaymentChangedEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String bookingId;
  final String? userId;
  final String? helperId;
  final String? paymentId;
  final double? amount;
  final String? currency;
  final String? method;
  final String status;
  final String? failureReason;
  final double? refundedAmount;

  const BookingPaymentChangedEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.bookingId,
    this.userId,
    this.helperId,
    this.paymentId,
    this.amount,
    this.currency,
    this.method,
    required this.status,
    this.failureReason,
    this.refundedAmount,
  });

  factory BookingPaymentChangedEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return BookingPaymentChangedEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      bookingId: _str(map, 'bookingId') ?? '',
      userId: _str(map, 'userId'),
      helperId: _str(map, 'helperId'),
      paymentId: _str(map, 'paymentId'),
      amount: _toDouble(_readKey(map, 'amount')),
      currency: _str(map, 'currency'),
      method: _str(map, 'method'),
      status: _str(map, 'status') ?? 'Unknown',
      failureReason: _str(map, 'failureReason'),
      refundedAmount: _toDouble(_readKey(map, 'refundedAmount')),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        bookingId,
        userId,
        helperId,
        paymentId,
        amount,
        currency,
        method,
        status,
        failureReason,
        refundedAmount,
      ];
}

class BookingTripStartedEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String bookingId;
  final String? userId;
  final String? helperId;
  final DateTime? startedAt;

  const BookingTripStartedEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.bookingId,
    this.userId,
    this.helperId,
    this.startedAt,
  });

  factory BookingTripStartedEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return BookingTripStartedEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      bookingId: _str(map, 'bookingId') ?? '',
      userId: _str(map, 'userId'),
      helperId: _str(map, 'helperId'),
      startedAt: _parseDate(_readKey(map, 'startedAt')),
    );
  }

  @override
  List<Object?> get props =>
      [eventId, bookingId, userId, helperId, startedAt];
}

class BookingTripEndedEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String bookingId;
  final String? userId;
  final String? helperId;
  final DateTime? completedAt;
  final double? finalPrice;
  final String? paymentStatus;

  const BookingTripEndedEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.bookingId,
    this.userId,
    this.helperId,
    this.completedAt,
    this.finalPrice,
    this.paymentStatus,
  });

  factory BookingTripEndedEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return BookingTripEndedEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      bookingId: _str(map, 'bookingId') ?? '',
      userId: _str(map, 'userId'),
      helperId: _str(map, 'helperId'),
      completedAt: _parseDate(_readKey(map, 'completedAt')),
      finalPrice: _toDouble(_readKey(map, 'finalPrice')),
      paymentStatus: _str(map, 'paymentStatus'),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        bookingId,
        userId,
        helperId,
        completedAt,
        finalPrice,
        paymentStatus,
      ];
}

class HelperLocationUpdateEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String bookingId;
  final String? helperId;
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKmh;
  final DateTime? capturedAt;
  final double? distanceToPickupKm;
  final int? etaToPickupMinutes;
  final double? distanceToDestinationKm;
  final int? etaToDestinationMinutes;

  /// `"OnTheWay"` | `"InProgress"` (raw backend string).
  final String? phase;

  const HelperLocationUpdateEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.bookingId,
    this.helperId,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speedKmh,
    this.capturedAt,
    this.distanceToPickupKm,
    this.etaToPickupMinutes,
    this.distanceToDestinationKm,
    this.etaToDestinationMinutes,
    this.phase,
  });

  factory HelperLocationUpdateEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return HelperLocationUpdateEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      bookingId: _str(map, 'bookingId') ?? '',
      helperId: _str(map, 'helperId'),
      latitude: _toDouble(_readKey(map, 'latitude')) ?? 0,
      longitude: _toDouble(_readKey(map, 'longitude')) ?? 0,
      heading: _toDouble(_readKey(map, 'heading')),
      speedKmh: _toDouble(_readKey(map, 'speedKmh')),
      capturedAt: _parseDate(_readKey(map, 'capturedAt')),
      distanceToPickupKm: _toDouble(_readKey(map, 'distanceToPickupKm')),
      etaToPickupMinutes: _toInt(_readKey(map, 'etaToPickupMinutes')),
      distanceToDestinationKm:
          _toDouble(_readKey(map, 'distanceToDestinationKm')),
      etaToDestinationMinutes:
          _toInt(_readKey(map, 'etaToDestinationMinutes')),
      phase: _str(map, 'phase'),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        bookingId,
        helperId,
        latitude,
        longitude,
        heading,
        speedKmh,
        capturedAt,
        distanceToPickupKm,
        etaToPickupMinutes,
        distanceToDestinationKm,
        etaToDestinationMinutes,
        phase,
      ];
}

class ChatMessagePushEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String bookingId;
  final String? conversationId;
  final String? messageId;
  final String? senderId;
  final String? senderType;
  final String? senderName;
  final String? recipientId;
  final String? recipientType;
  final String? messageType;
  final String? text;
  final String? preview;
  final DateTime? sentAt;

  const ChatMessagePushEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.bookingId,
    this.conversationId,
    this.messageId,
    this.senderId,
    this.senderType,
    this.senderName,
    this.recipientId,
    this.recipientType,
    this.messageType,
    this.text,
    this.preview,
    this.sentAt,
  });

  factory ChatMessagePushEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return ChatMessagePushEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      bookingId: _str(map, 'bookingId') ?? '',
      conversationId: _str(map, 'conversationId'),
      messageId: _str(map, 'messageId') ?? _str(map, 'id'),
      senderId: _str(map, 'senderId'),
      senderType: _str(map, 'senderType'),
      senderName: _str(map, 'senderName'),
      recipientId: _str(map, 'recipientId'),
      recipientType: _str(map, 'recipientType'),
      messageType: _str(map, 'messageType'),
      text: _str(map, 'text'),
      preview: _str(map, 'preview'),
      sentAt: _parseDate(_readKey(map, 'sentAt')),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        bookingId,
        conversationId,
        messageId,
        senderId,
        senderType,
        senderName,
        recipientId,
        recipientType,
        messageType,
        text,
        preview,
        sentAt,
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Reports / SOS / Pong (NEW — were missing before this audit)
// ─────────────────────────────────────────────────────────────────────────────

/// `HelperReportResolved` — fired when a helper-on-user report is resolved.
/// The user is the *target* of the report (the report was filed against them).
class HelperReportResolvedEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String reportId;
  final String? bookingId;
  final String? userId;
  final String? helperId;
  final String? resolution;
  final String? notes;

  const HelperReportResolvedEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.reportId,
    this.bookingId,
    this.userId,
    this.helperId,
    this.resolution,
    this.notes,
  });

  factory HelperReportResolvedEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return HelperReportResolvedEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      reportId: _str(map, 'reportId') ?? '',
      bookingId: _str(map, 'bookingId'),
      userId: _str(map, 'userId'),
      helperId: _str(map, 'helperId'),
      resolution: _str(map, 'resolution'),
      notes: _str(map, 'notes'),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        reportId,
        bookingId,
        userId,
        helperId,
        resolution,
        notes,
      ];
}

/// `ReportResolved` — fired when a report filed BY the user is resolved.
class ReportResolvedEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String reportId;
  final String? bookingId;
  final String? userId;
  final String? helperId;
  final String? resolution;
  final String? notes;

  const ReportResolvedEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.reportId,
    this.bookingId,
    this.userId,
    this.helperId,
    this.resolution,
    this.notes,
  });

  factory ReportResolvedEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return ReportResolvedEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      reportId: _str(map, 'reportId') ?? '',
      bookingId: _str(map, 'bookingId'),
      userId: _str(map, 'userId'),
      helperId: _str(map, 'helperId'),
      resolution: _str(map, 'resolution'),
      notes: _str(map, 'notes'),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        reportId,
        bookingId,
        userId,
        helperId,
        resolution,
        notes,
      ];
}

class SosTriggeredEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String sosId;
  final String? bookingId;
  final String? userId;
  final String? helperId;
  final String? triggeredBy;
  final double? latitude;
  final double? longitude;
  final String? note;

  const SosTriggeredEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.sosId,
    this.bookingId,
    this.userId,
    this.helperId,
    this.triggeredBy,
    this.latitude,
    this.longitude,
    this.note,
  });

  factory SosTriggeredEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return SosTriggeredEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      sosId: _str(map, 'sosId') ?? '',
      bookingId: _str(map, 'bookingId'),
      userId: _str(map, 'userId'),
      helperId: _str(map, 'helperId'),
      triggeredBy: _str(map, 'triggeredBy'),
      latitude: _toDouble(_readKey(map, 'latitude')),
      longitude: _toDouble(_readKey(map, 'longitude')),
      note: _str(map, 'note'),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        sosId,
        bookingId,
        userId,
        helperId,
        triggeredBy,
        latitude,
        longitude,
        note,
      ];
}

class SosResolvedEvent extends Equatable with EventEnvelope {
  @override
  final String eventId;
  @override
  final DateTime? occurredAt;
  @override
  final int? version;

  final String sosId;
  final String? bookingId;
  final String? userId;
  final String? helperId;
  final String? resolution;
  final String? notes;

  const SosResolvedEvent({
    required this.eventId,
    this.occurredAt,
    this.version,
    required this.sosId,
    this.bookingId,
    this.userId,
    this.helperId,
    this.resolution,
    this.notes,
  });

  factory SosResolvedEvent.fromMap(Map<String, dynamic> map) {
    final env = _readEnvelope(map);
    return SosResolvedEvent(
      eventId: env.eventId,
      occurredAt: env.occurredAt,
      version: env.version,
      sosId: _str(map, 'sosId') ?? '',
      bookingId: _str(map, 'bookingId'),
      userId: _str(map, 'userId'),
      helperId: _str(map, 'helperId'),
      resolution: _str(map, 'resolution'),
      notes: _str(map, 'notes'),
    );
  }

  @override
  List<Object?> get props => [
        eventId,
        sosId,
        bookingId,
        userId,
        helperId,
        resolution,
        notes,
      ];
}

/// Server response to `Ping()` — used purely for connection health diagnostics.
class PongEvent extends Equatable {
  final int serverTimestampMs;
  final DateTime receivedAt;

  PongEvent({
    required this.serverTimestampMs,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  @override
  List<Object?> get props => [serverTimestampMs, receivedAt];
}
