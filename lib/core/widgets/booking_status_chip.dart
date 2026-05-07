import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_theme.dart';
import '../../features/user/features/user_booking/domain/entities/booking_detail_entity.dart';

/// Pill-shaped color-coded chip used everywhere a booking status is shown.
///
/// Design rules from Pass #2:
///   - rounded full (pill)
///   - colored background tint + matching text color
///   - tiny solid dot to make it pop on busy backgrounds
class BookingStatusChip extends StatelessWidget {
  final BookingStatus status;
  final bool dense;

  const BookingStatusChip({
    super.key,
    required this.status,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(status);
    final padH = dense ? 8.0 : AppTheme.spaceSM + 2;
    final padV = dense ? 2.0 : 4.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: spec.color.withValues(alpha: 0.32), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: spec.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            spec.label,
            style: TextStyle(
              color: spec.color,
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  static _StatusSpec _specFor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pendingHelperResponse:
        return _StatusSpec('Pending', AppColor.warningColor);
      case BookingStatus.acceptedByHelper:
        return _StatusSpec('Accepted', AppColor.accentColor);
      case BookingStatus.confirmedAwaitingPayment:
        return _StatusSpec('Awaiting payment', AppColor.warningColor);
      case BookingStatus.confirmedPaid:
        return _StatusSpec('Confirmed', AppColor.accentColor);
      case BookingStatus.upcoming:
        return _StatusSpec('Upcoming', AppColor.secondaryColor);
      case BookingStatus.inProgress:
        return _StatusSpec('In progress', AppColor.secondaryColor);
      case BookingStatus.completed:
        return _StatusSpec('Completed', AppColor.accentColor);
      case BookingStatus.declinedByHelper:
        return _StatusSpec('Declined', AppColor.errorColor);
      case BookingStatus.expiredNoResponse:
        return _StatusSpec('Expired', AppColor.errorColor);
      case BookingStatus.reassignmentInProgress:
        return _StatusSpec('Reassigning', AppColor.warningColor);
      case BookingStatus.waitingForUserAction:
        return _StatusSpec('Action needed', AppColor.warningColor);
      case BookingStatus.cancelledByUser:
        return _StatusSpec('Cancelled', AppColor.errorColor);
      case BookingStatus.cancelledByHelper:
        return _StatusSpec('Cancelled', AppColor.errorColor);
      case BookingStatus.cancelledByTraveler:
        return _StatusSpec('Cancelled', AppColor.errorColor);
      case BookingStatus.cancelledBySystem:
        return _StatusSpec('Cancelled', AppColor.errorColor);
    }
  }

  /// Whether a status counts as a live booking we should surface on the
  /// home screen "Your active trip" section.
  static bool isActive(BookingStatus s) {
    return s == BookingStatus.inProgress ||
        s == BookingStatus.acceptedByHelper ||
        s == BookingStatus.confirmedAwaitingPayment ||
        s == BookingStatus.confirmedPaid ||
        s == BookingStatus.upcoming ||
        s == BookingStatus.pendingHelperResponse ||
        s == BookingStatus.reassignmentInProgress ||
        s == BookingStatus.waitingForUserAction;
  }
}

class _StatusSpec {
  final String label;
  final Color color;
  const _StatusSpec(this.label, this.color);
}
