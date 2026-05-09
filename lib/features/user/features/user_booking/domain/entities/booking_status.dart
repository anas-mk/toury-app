/// Backend `BookingStatus` enum values, used as wire strings.
///
/// We keep the wire string as `raw` and parse a Dart enum for switch
/// statements. Unknown future values map to [unknown] so the app never crashes.
///
/// IMPORTANT: this enum mirrors the backend `BookingStatus` exactly. Do
/// NOT add values here that the backend doesn't emit, and do NOT keep
/// values that have been removed on the backend — the parse step would
/// silently downgrade real statuses to `unknown`.
enum BookingStatus {
  pendingHelperResponse('PendingHelperResponse'),
  acceptedByHelper('AcceptedByHelper'),
  declinedByHelper('DeclinedByHelper'),
  expiredNoResponse('ExpiredNoResponse'),
  reassignmentInProgress('ReassignmentInProgress'),
  waitingForUserAction('WaitingForUserAction'),
  confirmedAwaitingPayment('ConfirmedAwaitingPayment'),
  confirmedPaid('ConfirmedPaid'),
  upcoming('Upcoming'),
  inProgress('InProgress'),
  completed('Completed'),
  cancelledByUser('CancelledByUser'),
  cancelledByHelper('CancelledByHelper'),
  cancelledBySystem('CancelledBySystem'),
  unknown('Unknown');

  final String raw;
  const BookingStatus(this.raw);

  static BookingStatus parse(String? value) {
    if (value == null) return BookingStatus.unknown;
    for (final s in BookingStatus.values) {
      if (s.raw == value) return s;
    }
    return BookingStatus.unknown;
  }

  bool get isTerminal =>
      this == completed ||
      this == cancelledByUser ||
      this == cancelledByHelper ||
      this == cancelledBySystem;

  bool get isCancelled =>
      this == cancelledByUser ||
      this == cancelledByHelper ||
      this == cancelledBySystem;

  bool get needsAlternatives =>
      this == declinedByHelper ||
      this == expiredNoResponse ||
      this == waitingForUserAction;

  /// "The booking is firm — go to confirmed/tracking."
  ///
  /// Covers every backend status that means a helper has been locked in,
  /// regardless of payment phase: `AcceptedByHelper`,
  /// `ConfirmedAwaitingPayment`, `ConfirmedPaid`, `Upcoming`.
  bool get isFirm =>
      this == acceptedByHelper ||
      this == confirmedAwaitingPayment ||
      this == confirmedPaid ||
      this == upcoming;
}

enum PaymentStatusWire {
  notRequired('NotRequired'),
  awaitingPayment('AwaitingPayment'),
  paymentPending('PaymentPending'),
  paid('Paid'),
  refunded('Refunded'),
  failed('Failed'),
  unknown('Unknown');

  final String raw;
  const PaymentStatusWire(this.raw);

  static PaymentStatusWire parse(String? value) {
    if (value == null) return PaymentStatusWire.unknown;
    for (final s in PaymentStatusWire.values) {
      if (s.raw == value) return s;
    }
    return PaymentStatusWire.unknown;
  }
}
