import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:toury/features/tourist/features/user_booking/domain/entities/booking_detail_entity.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/app_network_image.dart';

class RecentBookingCard extends StatelessWidget {
  final BookingDetailEntity booking;

  const RecentBookingCard({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.pushNamed(
        'booking-details',
        pathParameters: {'id': booking.id},
        extra: {'booking': booking},
      ),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: isDark ? AppColor.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: isDark ? AppColor.darkBorder : AppColor.lightBorder),
          boxShadow: AppTheme.shadowLight(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColor.lightBorder,
                  backgroundImage: booking.helper?.profileImageUrl != null
                      ? NetworkImage(booking.helper!.profileImageUrl!)
                      : null,
                  child: booking.helper?.profileImageUrl == null
                      ? const Icon(Icons.person, size: 20, color: AppColor.primaryColor)
                      : null,
                ),
                const Spacer(),
                _buildStatusDot(booking.status),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMD),
            Text(
              booking.destinationCity,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spaceXS),
            Text(
              DateFormat('MMM dd, yyyy').format(booking.requestedDate ?? DateTime.now()),
              style: AppTheme.bodySmall.copyWith(color: AppColor.lightTextSecondary),
            ),
            const Spacer(),
            Text(
              '${booking.finalPrice} ${booking.currency}',
              style: AppTheme.labelMedium.copyWith(color: AppColor.accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(BookingStatus status) {
    Color color;
    switch (status) {
      case BookingStatus.completed:
        color = AppColor.accentColor;
        break;
      case BookingStatus.cancelledByUser:
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
        color = AppColor.errorColor;
        break;
      default:
        color = AppColor.warningColor;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
