// Modernized route card showing pickup → destination on a polished timeline
// alongside grouped meta-stats (date, time, duration, travelers).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../domain/entities/helper_booking_entities.dart';
import '../shared/route_stop_row.dart';

class BookingRouteCard extends StatelessWidget {
  final HelperBooking booking;
  const BookingRouteCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.30 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.route_rounded,
                    size: AppSize.iconSm,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Trip Logistics',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Timeline
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceInset,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: palette.border.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  RouteStopRow(
                    icon: Icons.circle,
                    color: palette.success,
                    label: 'PICKUP',
                    value: booking.pickupLocation,
                    emphasize: true,
                  ),
                  const RouteStopConnector(height: 24),
                  RouteStopRow(
                    icon: Icons.location_on_rounded,
                    color: palette.danger,
                    label: 'DESTINATION',
                    value: booking.destinationLocation,
                    emphasize: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Meta stats grid
            Row(
              children: [
                Expanded(
                  child: _MetaTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value:
                        DateFormat('EEE, MMM d').format(booking.startTime),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetaTile(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: DateFormat('hh:mm a').format(booking.startTime),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _MetaTile(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: _formatDuration(booking.durationInMinutes),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MetaTile(
                    icon: Icons.people_outline_rounded,
                    label: 'Travelers',
                    value: '${booking.travelersCount} '
                        '${booking.travelersCount == 1 ? "Person" : "People"}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 1),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, color: palette.primary, size: AppSize.iconSm),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
