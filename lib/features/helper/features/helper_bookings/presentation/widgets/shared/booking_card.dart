// Modern boarding-pass style booking card used in the helper bookings center
// (Requests / Upcoming / History tabs).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../../core/config/api_config.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/haptic_service.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../../../../../core/utils/currency_format.dart';
import '../../../domain/entities/helper_booking_entities.dart';
import '../../../domain/entities/helper_booking_status_x.dart';

class BookingCard extends StatelessWidget {
  final HelperBooking booking;
  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final accent = _accent(palette);
    final isHistory = booking.isHistory;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md + 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: () {
            HapticService.light();
            final route = booking.isPending
                ? AppRouter.helperRequestDetails
                : AppRouter.helperBookingDetails;
            context.push(route.replaceFirst(':id', booking.id));
          },
          child: Container(
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: palette.isDark ? 0.30 : 0.04,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left status stripe.
                    Container(
                      width: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accent,
                            Color.lerp(accent, Colors.black, 0.32)!,
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                _Avatar(
                                  name: booking.travelerName,
                                  imageUrl: booking.travelerImage,
                                ),
                                const SizedBox(width: AppSpacing.sm + 2),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        booking.travelerName.isEmpty
                                            ? 'Traveler'
                                            : booking.travelerName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat('EEE · MMM d · hh:mm a')
                                            .format(booking.startTime),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: palette.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _StatusChip(
                                  label: _statusLabel(),
                                  color: accent,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Route stops
                            _Stop(
                              icon: Icons.circle,
                              color: palette.success,
                              text: booking.pickupLocation,
                              showConnector: true,
                            ),
                            _Stop(
                              icon: Icons.location_on_rounded,
                              color: palette.danger,
                              text: booking.destinationLocation,
                              showConnector: false,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Type pill row
                            Row(
                              children: [
                                _TypeChip(isInstant: booking.isInstant),
                                const SizedBox(width: AppSpacing.xs),
                                _MetaPill(
                                  icon: Icons.timer_outlined,
                                  label: _formatDuration(
                                    booking.durationInMinutes,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                _MetaPill(
                                  icon: Icons.people_outline_rounded,
                                  label: '${booking.travelersCount}',
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    palette.border.withValues(alpha: 0),
                                    palette.border,
                                    palette.border.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Footer (payout + CTA)
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isHistory
                                            ? 'Total Earned'
                                            : 'Expected Payout',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: palette.textMuted,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      Text(
                                        Money.egp(booking.payout),
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: palette.primary,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isHistory)
                                  _CtaPill(
                                    label: _ctaLabel(),
                                    color: accent,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accent(AppColors p) {
    if (booking.isPending) return p.warning;
    if (booking.isActive) return p.success;
    if (booking.isCompleted) return p.textMuted;
    if (booking.isCancelled) return p.danger;
    return p.primary;
  }

  String _statusLabel() {
    if (booking.isPending) return 'NEW';
    if (booking.isActive) return 'LIVE';
    if (booking.isConfirmed) return 'CONFIRMED';
    if (booking.isCompleted) return 'DONE';
    if (booking.isCancelled) return 'CLOSED';
    return booking.status;
  }

  String _ctaLabel() {
    if (booking.isPending) return 'Review';
    if (booking.isActive) return 'Track';
    if (booking.isConfirmed) return 'Open';
    return 'Open';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  const _Avatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final resolved = ApiConfig.resolveImageUrl(imageUrl);

    final fallback = Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: theme.textTheme.titleMedium?.copyWith(
          color: palette.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
      width: AppSize.avatarMd,
      height: AppSize.avatarMd,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.primary.withValues(alpha: 0.10),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
      child: ClipOval(
        child: resolved.isNotEmpty
            ? Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool showConnector;

  const _Stop({
    required this.icon,
    required this.color,
    required this.text,
    required this.showConnector,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 7, color: Colors.white),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 2,
                bottom: showConnector ? AppSpacing.sm : 0,
              ),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final bool isInstant;
  const _TypeChip({required this.isInstant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final color = isInstant ? palette.warning : palette.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 1,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInstant ? Icons.flash_on_rounded : Icons.event_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isInstant ? 'Instant' : 'Scheduled',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: palette.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: palette.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaPill extends StatelessWidget {
  final String label;
  final Color color;
  const _CtaPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm - 1,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.18)!],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.34),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 14,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
