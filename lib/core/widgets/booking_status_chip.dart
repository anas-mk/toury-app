// lib/core/widgets/booking_status_chip.dart
//
// Pill-shaped status chip used across booking lists, details, and
// notifications. Public API (`BookingStatusChip(status: ...)`) is
// preserved — only the visual is modernized to use theme-aware tokens
// and the unified design system spacing/radius scale.

import 'package:flutter/material.dart';

import '../../features/user/features/user_booking/domain/entities/booking_detail_entity.dart';
import '../theme/app_color.dart';
import '../theme/app_dimens.dart';

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
    final palette = AppColors.of(context);
    final spec = _specFor(status, palette);
    final padH = dense ? 8.0 : 10.0;
    final padV = dense ? 3.0 : 5.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: spec.color.withValues(alpha: palette.isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: spec.color.withValues(alpha: 0.32),
          width: 1,
        ),
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

  static _StatusSpec _specFor(BookingStatus s, AppColors palette) {
    switch (s) {
      case BookingStatus.pendingHelperResponse:
        return _StatusSpec('Pending', palette.warning);
      case BookingStatus.acceptedByHelper:
        return _StatusSpec('Accepted', palette.success);
      case BookingStatus.confirmedAwaitingPayment:
        return _StatusSpec('Awaiting payment', palette.warning);
      case BookingStatus.confirmedPaid:
        return _StatusSpec('Confirmed', palette.success);
      case BookingStatus.upcoming:
        return _StatusSpec('Upcoming', palette.primary);
      case BookingStatus.inProgress:
        return _StatusSpec('In progress', palette.primary);
      case BookingStatus.completed:
        return _StatusSpec('Completed', palette.success);
      case BookingStatus.declinedByHelper:
        return _StatusSpec('Declined', palette.danger);
      case BookingStatus.expiredNoResponse:
        return _StatusSpec('Expired', palette.danger);
      case BookingStatus.reassignmentInProgress:
        return _StatusSpec('Reassigning', palette.warning);
      case BookingStatus.waitingForUserAction:
        return _StatusSpec('Action needed', palette.warning);
      case BookingStatus.cancelledByUser:
        return _StatusSpec('Cancelled', palette.danger);
      case BookingStatus.cancelledByHelper:
        return _StatusSpec('Cancelled', palette.danger);
      case BookingStatus.cancelledByTraveler:
        return _StatusSpec('Cancelled', palette.danger);
      case BookingStatus.cancelledBySystem:
        return _StatusSpec('Cancelled', palette.danger);
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
