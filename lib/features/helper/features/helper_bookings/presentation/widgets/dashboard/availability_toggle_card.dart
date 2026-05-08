import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/widgets/app_loading.dart';
import '../../../domain/entities/helper_availability_state.dart';
import '../../cubit/helper_bookings_cubits.dart';

/// Modern availability card with animated status ring, large action button,
/// and pill-segmented secondary status options.
class AvailabilityToggleCard extends StatelessWidget {
  final HelperAvailabilityState currentStatus;
  final Animation<double> pulseAnimation;
  final ValueChanged<HelperAvailabilityState> onStatusChanged;

  const AvailabilityToggleCard({
    super.key,
    required this.currentStatus,
    required this.pulseAnimation,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
    final isOnline = currentStatus == HelperAvailabilityState.availableNow;

    return BlocBuilder<HelperAvailabilityCubit, HelperAvailabilityStatus>(
      builder: (context, availState) {
        final isUpdating = availState is AvailabilityUpdating;
        final accent = _accentForStatus(currentStatus, palette);
        final statusLabel = _label(currentStatus);
        final statusDesc = _description(currentStatus);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: isOnline
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: palette.isDark
                        ? [
                            palette.primary.withValues(alpha: 0.30),
                            const Color(0xFF22C55E).withValues(alpha: 0.20),
                          ]
                        : [
                            palette.primary,
                            palette.primaryStrong,
                          ],
                  )
                : null,
            color: isOnline ? null : palette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isOnline
                  ? Colors.white.withValues(alpha: 0.15)
                  : palette.border,
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: isOnline
                    ? palette.primary.withValues(alpha: palette.isDark ? 0.18 : 0.30)
                    : Colors.black.withValues(alpha: palette.isDark ? 0.18 : 0.04),
                blurRadius: isOnline ? 26 : 14,
                offset: Offset(0, isOnline ? 12 : 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative orbs (only when online)
              if (isOnline) ...[
                Positioned(
                  top: -50,
                  right: -30,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -20,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ],

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusOrb(
                          color: isOnline ? Colors.white : accent,
                          isLive: isOnline,
                          pulse: pulseAnimation,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusLabel,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isOnline
                                      ? Colors.white
                                      : palette.textPrimary,
                                  fontSize: 19,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                statusDesc,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isOnline
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _GoOnlineToggle(
                          isOnline: isOnline,
                          isUpdating: isUpdating,
                          onTap: () {
                            if (isUpdating) return;
                            onStatusChanged(
                              isOnline
                                  ? HelperAvailabilityState.offline
                                  : HelperAvailabilityState.availableNow,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isOnline ? Colors.white : palette.border)
                                .withValues(alpha: 0),
                            isOnline
                                ? Colors.white.withValues(alpha: 0.20)
                                : palette.border,
                            (isOnline ? Colors.white : palette.border)
                                .withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: HelperAvailabilityState.values.map((s) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: s == HelperAvailabilityState.values.last ? 0 : 6,
                            ),
                            child: _StatusSegment(
                              status: s,
                              isSelected: s == currentStatus,
                              isOnlineMode: isOnline,
                              onTap: isUpdating ? null : () => onStatusChanged(s),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _accentForStatus(HelperAvailabilityState s, AppColors palette) {
    switch (s) {
      case HelperAvailabilityState.availableNow:
        return const Color(0xFF22C55E);
      case HelperAvailabilityState.scheduledOnly:
        return const Color(0xFFFFB020);
      case HelperAvailabilityState.busy:
        return palette.danger;
      case HelperAvailabilityState.offline:
        return palette.textMuted;
    }
  }

  String _label(HelperAvailabilityState s) {
    switch (s) {
      case HelperAvailabilityState.availableNow:
        return 'Active & Online';
      case HelperAvailabilityState.scheduledOnly:
        return 'Scheduled Only';
      case HelperAvailabilityState.busy:
        return 'Busy';
      case HelperAvailabilityState.offline:
        return 'Currently Offline';
    }
  }

  String _description(HelperAvailabilityState s) {
    switch (s) {
      case HelperAvailabilityState.availableNow:
        return 'You\'re visible to nearby travelers';
      case HelperAvailabilityState.scheduledOnly:
        return 'Only scheduled bookings reach you';
      case HelperAvailabilityState.busy:
        return 'New requests are paused';
      case HelperAvailabilityState.offline:
        return 'Tap "Go Online" to start receiving jobs';
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  STATUS ORB (animated outer ring)
// ──────────────────────────────────────────────────────────────────────────────

class _StatusOrb extends StatelessWidget {
  final Color color;
  final bool isLive;
  final Animation<double> pulse;

  const _StatusOrb({
    required this.color,
    required this.isLive,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final t = isLive ? pulse.value : 1.0;
        return SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLive)
                Container(
                  width: 44 * t,
                  height: 44 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.25 * (1 - t + 0.4)),
                  ),
                ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.20),
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: isLive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  GO ONLINE / GO OFFLINE TOGGLE BUTTON
// ──────────────────────────────────────────────────────────────────────────────

class _GoOnlineToggle extends StatelessWidget {
  final bool isOnline;
  final bool isUpdating;
  final VoidCallback onTap;

  const _GoOnlineToggle({
    required this.isOnline,
    required this.isUpdating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isOnline ? Colors.white : palette.primary,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: (isOnline ? Colors.white : palette.primary)
                    .withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isUpdating
              ? SizedBox(
                  width: 56,
                  height: 18,
                  child: Center(
                    child: AppSpinner(
                      size: 16,
                      strokeWidth: 2,
                      color: isOnline ? palette.primary : Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.power_settings_new_rounded : Icons.flash_on_rounded,
                      size: 14,
                      color: isOnline ? palette.primary : Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? 'Go Offline' : 'Go Online',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isOnline ? palette.primary : Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  STATUS SEGMENT
// ──────────────────────────────────────────────────────────────────────────────

class _StatusSegment extends StatelessWidget {
  final HelperAvailabilityState status;
  final bool isSelected;
  final bool isOnlineMode;
  final VoidCallback? onTap;

  const _StatusSegment({
    required this.status,
    required this.isSelected,
    required this.isOnlineMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final accent = _accent(status, palette);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 50,
          decoration: BoxDecoration(
            color: isSelected
                ? (isOnlineMode
                    ? Colors.white.withValues(alpha: 0.18)
                    : accent.withValues(alpha: palette.isDark ? 0.18 : 0.10))
                : (isOnlineMode
                    ? Colors.white.withValues(alpha: 0.08)
                    : palette.surface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? (isOnlineMode
                      ? Colors.white.withValues(alpha: 0.40)
                      : accent.withValues(alpha: 0.50))
                  : (isOnlineMode
                      ? Colors.white.withValues(alpha: 0.10)
                      : palette.border),
              width: isSelected ? 1.0 : 0.6,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? (isOnlineMode ? Colors.white : accent)
                      : (isOnlineMode
                          ? Colors.white.withValues(alpha: 0.45)
                          : palette.textMuted),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _label(status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? (isOnlineMode ? Colors.white : palette.textPrimary)
                      : (isOnlineMode
                          ? Colors.white.withValues(alpha: 0.7)
                          : palette.textSecondary),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(HelperAvailabilityState s) {
    switch (s) {
      case HelperAvailabilityState.availableNow:
        return 'Online';
      case HelperAvailabilityState.scheduledOnly:
        return 'Scheduled';
      case HelperAvailabilityState.busy:
        return 'Busy';
      case HelperAvailabilityState.offline:
        return 'Offline';
    }
  }

  Color _accent(HelperAvailabilityState s, AppColors palette) {
    switch (s) {
      case HelperAvailabilityState.availableNow:
        return const Color(0xFF22C55E);
      case HelperAvailabilityState.scheduledOnly:
        return const Color(0xFFFFB020);
      case HelperAvailabilityState.busy:
        return palette.danger;
      case HelperAvailabilityState.offline:
        return palette.textMuted;
    }
  }
}
