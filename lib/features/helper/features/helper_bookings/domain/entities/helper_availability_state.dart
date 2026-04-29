import 'package:flutter/foundation.dart';

enum HelperAvailabilityState {
  availableNow,
  scheduledOnly,
  busy,
  offline;

  String get toApiValue {
    switch (this) {
      case HelperAvailabilityState.availableNow:
        return 'AvailableNow';
      case HelperAvailabilityState.scheduledOnly:
        return 'ScheduledOnly';
      case HelperAvailabilityState.offline:
        return 'Offline';
      case HelperAvailabilityState.busy:
        return 'Busy';
    }
  }

  static HelperAvailabilityState fromApiValue(String status) {
    switch (status.toLowerCase()) {
      case 'availablenow':
      case 'online':
        return HelperAvailabilityState.availableNow;
      case 'scheduledonly':
        return HelperAvailabilityState.scheduledOnly;
      case 'busy':
        return HelperAvailabilityState.busy;
      case 'offline':
        return HelperAvailabilityState.offline;
      default:
        debugPrint('[Availability][STATE] Unknown value received: $status');
        return HelperAvailabilityState.offline;
    }
  }
}
