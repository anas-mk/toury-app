// Modern bottom-sheet content used by `ActiveBookingPage`. Displays:
//   • Drag handle.
//   • Traveler hero block with status pulse + chat shortcut.
//   • Quick stat chips (Payout in EGP, Language, Type, Distance).
//   • Pickup / drop-off timeline.
//   • Sticky action footer (Start Trip / End Trip / SOS cancel).

import 'package:flutter/material.dart';

import '../../../../../../../core/config/api_config.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../../../../../core/utils/currency_format.dart';
import '../../../../../../../core/widgets/map_tracking_chrome.dart';
import '../../../../helper_sos/presentation/cubit/helper_sos_cubit.dart';
import '../../../domain/entities/helper_booking_entities.dart';
import '../shared/booking_action_button.dart';
import '../shared/route_stop_row.dart';

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
                _QuickStatsRow(
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
            icon: Icons.play_arrow_rounded,
            onTap: canStartNow ? onStartTrip : null,
            actionType: 'start',
          ),
        ],
      );
    }
    if (booking.canEndTrip || tripActive) {
      final isSosActive = sosState.status == SosStatus.active;
      final isSosPending = sosState.status == SosStatus.deactivating ||
          sosState.status == SosStatus.activating;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSosActive || isSosPending) ...[
            BookingActionButton.tripAction(
              label: isSosPending ? 'Cancelling SOS...' : 'Cancel SOS Alert',
              color: palette.danger,
              icon: Icons.cancel_outlined,
              onTap: isSosPending ? null : onCancelSos,
              actionType: 'cancel_sos',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          BookingActionButton.tripAction(
            label: 'End Trip',
            color: palette.danger,
            icon: Icons.stop_circle_rounded,
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
        icon: Icons.stop_circle_rounded,
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

class _QuickStatsRow extends StatelessWidget {
  final HelperBooking booking;
  final bool isStarted;
  final double? distanceToPickupMeters;

  const _QuickStatsRow({
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

    return Row(
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
            label: distanceLabel != null ? 'To Pickup' : 'Type',
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
    );
  }
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
