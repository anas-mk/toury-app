import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toury/features/tourist/features/user_booking/domain/entities/booking_detail_entity.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';

class ActiveBookingBanner extends StatelessWidget {
  final BookingDetailEntity booking;

  const ActiveBookingBanner({
    super.key,
    required this.booking,
  });

  /// Decides where tapping the banner should take the user.
  ///
  /// Pending **instant** bookings should land on the live waiting
  /// screen so the user picks up exactly where they left off (radar
  /// + countdown), instead of opening the generic booking-details
  /// page (which is built around scheduled-trip lifecycle).
  ///
  /// Everything else (scheduled, accepted, in-progress, completed)
  /// keeps the original behaviour and goes to `booking-details`.
  void _onTap(BuildContext context) {
    final isInstantPending = booking.type == BookingType.instant &&
        _isPendingHelperResponse(booking.status);
    if (isInstantPending) {
      context.push(
        AppRouter.instantWaiting.replaceFirst(':id', booking.id),
      );
      return;
    }
    context.pushNamed(
      'booking-details',
      pathParameters: {'id': booking.id},
      extra: {'booking': booking},
    );
  }

  static bool _isPendingHelperResponse(BookingStatus s) {
    return s == BookingStatus.pendingHelperResponse ||
        s == BookingStatus.reassignmentInProgress ||
        s == BookingStatus.waitingForUserAction;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: AppColor.secondaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: AppColor.secondaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: AppColor.secondaryColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: const Icon(
                Icons.map_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Trip to ${booking.destinationCity}',
                        style: AppTheme.bodyLarge
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: AppTheme.spaceSM),
                      _buildStatusChip(booking.status),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    'With ${booking.helper?.name ?? "Helper"}',
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColor.secondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    switch (status) {
      case BookingStatus.inProgress:
        color = AppColor.secondaryColor;
        break;
      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmedPaid:
      case BookingStatus.upcoming:
        color = AppColor.accentColor;
        break;
      default:
        color = AppColor.warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
