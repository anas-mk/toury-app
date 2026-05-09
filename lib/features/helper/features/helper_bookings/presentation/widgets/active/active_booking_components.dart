// Modern bottom-sheet content used by `ActiveBookingPage`. Displays:
//   • Drag handle.
//   • Traveler hero block with status pulse + chat shortcut.
//   • Quick stat chips (Payout in EGP, Language, Type, Distance).
//   • Pickup / drop-off timeline.
//   • Sticky action footer (Start Trip / End Trip / SOS cancel).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../../core/config/api_config.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../../../../../core/utils/currency_format.dart';
import '../../../../../../../core/widgets/map_tracking_chrome.dart';
import '../../../../helper_sos/presentation/cubit/helper_sos_cubit.dart';
import '../../../domain/entities/helper_booking_entities.dart';
import '../shared/booking_action_button.dart';
import '../shared/route_stop_row.dart';

class ActiveMapTopCard extends StatelessWidget {
  final bool isStarted;
  final double payout;
  final String? distance;
  final String? duration;
  final bool requiresCar;

  const ActiveMapTopCard({
    super.key,
    required this.isStarted,
    required this.payout,
    required this.requiresCar,
    this.distance,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final stageColor = isStarted ? palette.success : palette.warning;
    final hasRouteInfo = (distance?.isNotEmpty ?? false) && (duration?.isNotEmpty ?? false);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceElevated.withValues(alpha: palette.isDark ? 0.84 : 0.93),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: stageColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  isStarted ? 'Trip in progress' : 'Heading to pickup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                Money.egp(payout, decimals: false),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      requiresCar
                          ? Icons.directions_car_filled_rounded
                          : Icons.directions_walk_rounded,
                      size: AppSize.iconSm,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        requiresCar ? 'Driving route' : 'Walking route',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasRouteInfo) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      children: [
                        Icon(
                          Icons.straighten_rounded,
                          size: AppSize.iconSm,
                          color: palette.primary,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          distance!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.schedule_rounded,
                          size: AppSize.iconSm,
                          color: palette.primary,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          duration!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ActiveTrackingSheet extends StatelessWidget {
  final ScrollController scrollController;
  final HelperBooking booking;
  final bool isStarted;
  final String status;
  final VoidCallback onEndTrip;
  final VoidCallback onStartTrip;
  final VoidCallback onChat;
  final HelperSosState sosState;
  final VoidCallback onCancelSos;
  final bool hasArrivedAtPickup;
  final double? distanceToPickupMeters;

  const ActiveTrackingSheet({
    super.key,
    required this.scrollController,
    required this.booking,
    required this.isStarted,
    required this.status,
    required this.onEndTrip,
    required this.onStartTrip,
    required this.onChat,
    required this.sosState,
    required this.onCancelSos,
    required this.hasArrivedAtPickup,
    required this.distanceToPickupMeters,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return MapTrackingSheetSurface(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                0,
              ),
              children: [
                const MapTrackingDragHandle(),
                _TravelerHero(
                  booking: booking,
                  isStarted: isStarted,
                  onChat: onChat,
                ),
                const SizedBox(height: AppSpacing.lg),
                _TripOverviewSection(
                  booking: booking,
                  isStarted: isStarted,
                  distanceToPickupMeters: distanceToPickupMeters,
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: palette.surfaceInset,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: palette.border.withValues(alpha: 0.40),
                    ),
                  ),
                  child: RouteStopList(
                    pickup: booking.pickupLocation,
                    destination: booking.destinationLocation,
                  ),
                ),
                if ((booking.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _InfoCard(
                    title: 'Trip Notes',
                    icon: Icons.sticky_note_2_outlined,
                    child: Text(
                      booking.notes!.trim(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _InfoCard(
                  title: 'Booking Details',
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Booking ID',
                        value: booking.id,
                      ),
                      _InfoRow(
                        label: 'Status',
                        value: _formatStatusLabel(booking.status),
                      ),
                      _InfoRow(
                        label: 'Booking Category',
                        value: booking.bookingType,
                      ),
                      _InfoRow(
                        label: 'City',
                        value: booking.destinationCity,
                      ),
                      _InfoRow(
                        label: 'Start Time',
                        value: DateFormat('EEE, MMM d • h:mm a').format(
                          booking.startTime.toLocal(),
                        ),
                      ),
                      _InfoRow(
                        label: 'Expected Duration',
                        value: '${booking.durationInMinutes} min',
                      ),
                      _InfoRow(
                        label: 'Created At',
                        value: DateFormat('EEE, MMM d • h:mm a').format(
                          booking.createdAt.toLocal(),
                        ),
                      ),
                      _InfoRow(
                        label: 'Response Deadline',
                        value: DateFormat('EEE, MMM d • h:mm a').format(
                          booking.responseDeadline.toLocal(),
                        ),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              border: Border(
                top: BorderSide(
                  color: palette.border.withValues(alpha: 0.30),
                ),
              ),
            ),
            child: SafeArea(top: false, child: _buildActions(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final s = status.toLowerCase();
    final tripActive =
        isStarted || s.contains('progress') || s.contains('started');

    if (booking.canStartTrip || (s.contains('accept') && !tripActive)) {
      final canStartNow = hasArrivedAtPickup;
      final distanceLabel = distanceToPickupMeters == null
          ? 'Calculating distance to pickup...'
          : distanceToPickupMeters! >= 1000
              ? '${(distanceToPickupMeters! / 1000).toStringAsFixed(1)} km to pickup'
              : '${distanceToPickupMeters!.round()} m to pickup';
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!canStartNow) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_rounded,
                  size: AppSize.iconSm,
                  color: palette.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  distanceLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          BookingActionButton.tripAction(
            label: canStartNow ? 'Start Trip' : 'Reach Pickup to Start',
            color: palette.success,
            onTap: canStartNow ? onStartTrip : null,
            actionType: 'start',
          ),
        ],
      );
    }
    if (booking.canEndTrip || tripActive) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BookingActionButton.tripAction(
            label: 'End Trip',
            color: palette.danger,
            onTap: onEndTrip,
            actionType: 'end',
          ),
        ],
      );
    }
    if (s != 'completed' && s != 'cancelled') {
      return BookingActionButton.tripAction(
        label: 'End Trip',
        color: palette.danger,
        onTap: onEndTrip,
        actionType: 'end',
      );
    }
    return const SizedBox.shrink();
  }
}

class _TravelerHero extends StatelessWidget {
  final HelperBooking booking;
  final bool isStarted;
  final VoidCallback onChat;
  const _TravelerHero({
    required this.booking,
    required this.isStarted,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final dotColor = isStarted ? palette.success : palette.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          _Avatar(
            name: booking.travelerName,
            imageUrl: booking.travelerImage,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  booking.travelerName.isEmpty
                      ? 'Traveler'
                      : booking.travelerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _PulseDot(color: dotColor, animate: isStarted),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      isStarted ? 'Trip in progress' : 'Heading to pickup',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _RoundIconButton(
            icon: Icons.chat_bubble_rounded,
            color: palette.primary,
            onTap: onChat,
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  final bool animate;
  const _PulseDot({required this.color, required this.animate});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1300),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
      ),
    );
    if (_ctrl == null) return dot;
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl!,
            builder: (_, __) => Container(
              width: 8 + 6 * _ctrl!.value,
              height: 8 + 6 * _ctrl!.value,
              decoration: BoxDecoration(
                color: widget.color
                    .withValues(alpha: 0.40 * (1 - _ctrl!.value)),
                shape: BoxShape.circle,
              ),
            ),
          ),
          dot,
        ],
      ),
    );
  }
}

class _TripOverviewSection extends StatelessWidget {
  final HelperBooking booking;
  final bool isStarted;
  final double? distanceToPickupMeters;

  const _TripOverviewSection({
    required this.booking,
    required this.isStarted,
    required this.distanceToPickupMeters,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    String? distanceLabel;
    if (!isStarted && distanceToPickupMeters != null) {
      distanceLabel = distanceToPickupMeters! >= 1000
          ? '${(distanceToPickupMeters! / 1000).toStringAsFixed(1)} km'
          : '${distanceToPickupMeters!.round()} m';
    }

    return _InfoCard(
      title: 'Trip Overview',
      icon: Icons.dashboard_customize_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Payout',
                  value: Money.egp(booking.payout, decimals: false),
                  icon: Icons.account_balance_wallet_rounded,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  label: distanceLabel != null ? 'To Pickup' : 'Trip Type',
                  value: distanceLabel ??
                      (booking.isInstant ? 'Instant' : 'Scheduled'),
                  icon: distanceLabel != null
                      ? Icons.directions_car_rounded
                      : (booking.isInstant
                          ? Icons.flash_on_rounded
                          : Icons.event_outlined),
                  color:
                      distanceLabel != null ? palette.success : palette.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  label: 'Language',
                  value: booking.language ?? 'Any',
                  icon: Icons.translate_rounded,
                  color: palette.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            label: 'Travelers',
            value: '${booking.travelersCount}',
          ),
          _InfoRow(
            label: 'Vehicle Required',
            value: booking.requiresCar ? 'Yes' : 'No',
          ),
          _InfoRow(
            label: 'Meeting Point',
            value: (booking.meetingPointType ?? 'Not specified').trim(),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSize.iconMd, color: palette.primary),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: palette.border.withValues(alpha: 0.35)),
              ),
            ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatStatusLabel(String status) {
  final clean = status.trim();
  if (clean.isEmpty) return 'Unknown';
  final words = clean
      .replaceAll('-', ' ')
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.trim().isNotEmpty)
      .map((w) {
        final lower = w.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
  return words;
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border.withValues(alpha: 0.40)),
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: AppSpacing.xs + 1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
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
      width: AppSize.avatarLg - AppSpacing.sm,
      height: AppSize.avatarLg - AppSpacing.sm,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.primarySoft,
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

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Icon(icon, color: color, size: AppSize.iconMd),
        ),
      ),
    );
  }
}
