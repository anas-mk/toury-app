import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../domain/entities/helper_booking_entities.dart';
import '../../cubit/trip_action_cubit.dart';
import '../../../../helper_sos/presentation/cubit/helper_sos_cubit.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1624) : BrandTokens.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: BrandTokens.borderSoft.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: BrandTokens.borderSoft.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLG,
                AppTheme.spaceLG,
                AppTheme.spaceLG,
                0,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BrandTokens.bgSoft.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: BrandTokens.borderSoft.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: BrandTokens.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            booking.travelerName.isNotEmpty
                                ? booking.travelerName[0].toUpperCase()
                                : '?',
                            style: BrandTypography.title(
                              color: BrandTokens.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(booking.travelerName, style: BrandTypography.title()),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isStarted
                                        ? BrandTokens.successGreen
                                        : BrandTokens.warningAmber,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isStarted ? 'Trip in progress' : 'Ready to start',
                                  style: BrandTypography.caption(
                                    color: BrandTokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _SheetIconButton(
                        icon: Icons.chat_bubble_rounded,
                        color: BrandTokens.primaryBlue,
                        onTap: onChat,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                Row(
                  children: [
                    _StatItem(label: 'Payout', value: '\$${booking.payout.toStringAsFixed(0)}', icon: Icons.attach_money_rounded),
                    _StatItem(label: 'Language', value: booking.language ?? 'Any', icon: Icons.translate_rounded),
                    _StatItem(label: 'Type', value: booking.isInstant ? 'Instant' : 'Scheduled', icon: Icons.bolt_rounded),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceXL),
                _RouteInfo(pickup: booking.pickupLocation, destination: booking.destinationLocation),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1624) : BrandTokens.surfaceWhite,
              border: Border(top: BorderSide(color: BrandTokens.borderSoft.withValues(alpha: 0.2))),
            ),
            child: SafeArea(
              top: false,
              child: _buildActions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final s = status.toLowerCase();
    final tripActive = isStarted || s.contains('progress') || s.contains('started');
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
            Text(
              distanceLabel,
              style: BrandTypography.caption(color: BrandTokens.textSecondary),
            ),
            const SizedBox(height: AppTheme.spaceSM),
          ],
          _TripBtn(
            label: canStartNow ? 'Start Trip' : 'Reach Pickup to Start',
            color: BrandTokens.successGreen,
            icon: Icons.play_arrow_rounded,
            onTap: canStartNow ? onStartTrip : null,
            actionType: 'start',
          ),
        ],
      );
    }
    if (booking.canEndTrip || tripActive) {
      final isSosActive = sosState.status == SosStatus.active;
      final isSosPending = sosState.status == SosStatus.deactivating || sosState.status == SosStatus.activating;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSosActive || isSosPending) ...[
            _TripBtn(
              label: isSosPending ? 'Cancelling SOS...' : 'Cancel SOS Alert',
              color: BrandTokens.dangerRed,
              icon: Icons.cancel_outlined,
              onTap: isSosPending ? null : onCancelSos,
              actionType: 'cancel_sos',
            ),
            const SizedBox(height: AppTheme.spaceMD),
          ],
          _TripBtn(
            label: 'End Trip',
            color: BrandTokens.dangerRed,
            icon: Icons.stop_circle_rounded,
            onTap: onEndTrip,
            actionType: 'end',
          ),
        ],
      );
    }
    if (s != 'completed' && s != 'cancelled') {
      return _TripBtn(
        label: 'End Trip',
        color: BrandTokens.dangerRed,
        icon: Icons.stop_circle_rounded,
        onTap: onEndTrip,
        actionType: 'end',
      );
    }
    return const SizedBox.shrink();
  }
}

class ActiveBlurredCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const ActiveBlurredCircleButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.black.withValues(alpha: 0.26),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class ActiveRouteInfoChip extends StatelessWidget {
  final String distance;
  final String duration;
  const ActiveRouteInfoChip({super.key, required this.distance, required this.duration});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.straighten_rounded, size: 16, color: BrandTokens.primaryBlue),
              const SizedBox(width: 6),
              Text(distance, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: BrandTokens.textPrimary)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 1,
                height: 16,
                color: BrandTokens.borderSoft,
              ),
              const Icon(Icons.schedule_rounded, size: 16, color: BrandTokens.primaryBlue),
              const SizedBox(width: 6),
              Text(duration, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: BrandTokens.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: BrandTokens.bgSoft.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: BrandTokens.textSecondary, size: 18),
            const SizedBox(height: 4),
            Text(value, style: BrandTypography.body(weight: FontWeight.bold)),
            Text(label, style: BrandTypography.caption(color: BrandTokens.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RouteInfo extends StatelessWidget {
  final String pickup, destination;
  const _RouteInfo({required this.pickup, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.bgSoft.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandTokens.borderSoft.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          _RouteRow(icon: Icons.trip_origin_rounded, color: BrandTokens.successGreen, label: 'Pickup', value: pickup),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 2, height: 20, color: BrandTokens.borderSoft),
            ),
          ),
          _RouteRow(icon: Icons.location_on_rounded, color: BrandTokens.dangerRed, label: 'Drop-off', value: destination),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _RouteRow({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: BrandTypography.caption(color: BrandTokens.textSecondary)),
              Text(value, style: BrandTypography.body(weight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final String? actionType;

  const _TripBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.actionType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripActionCubit, TripActionState>(
      builder: (context, state) {
        final loading = state is TripActionLoading && state.actionType == actionType;
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onTap,
            icon: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, color: Colors.white),
            label: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      },
    );
  }
}

class _SheetIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SheetIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
