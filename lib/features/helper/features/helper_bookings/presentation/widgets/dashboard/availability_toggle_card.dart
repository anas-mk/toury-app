import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../domain/entities/helper_availability_state.dart';
import '../../cubit/helper_bookings_cubits.dart';

/// Availability card — three mode pills only (no duplicate header).
/// "Busy" is never shown here; it is set automatically by the backend
/// when the helper has an active trip.
class AvailabilityToggleCard extends StatelessWidget {
  final HelperAvailabilityState currentStatus;
  final ValueChanged<HelperAvailabilityState> onStatusChanged;

  const AvailabilityToggleCard({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  // The three states the helper can manually pick — Busy is excluded because
  // it is controlled automatically by the system when a trip is active.
  static const _selectable = [
    HelperAvailabilityState.availableNow,
    HelperAvailabilityState.scheduledOnly,
    HelperAvailabilityState.offline,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HelperAvailabilityCubit, HelperAvailabilityStatus>(
      builder: (context, availState) {
        final isUpdating = availState is AvailabilityUpdating;
        final isOnline = currentStatus == HelperAvailabilityState.availableNow;

        return _CardShell(
          isOnline: isOnline,
          child: Row(
            children: _selectable.map((s) {
              final isLast = s == _selectable.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 6),
                  child: _ModePill(
                    status: s,
                    isSelected: s == currentStatus,
                    isOnlineMode: isOnline,
                    onTap: isUpdating ? null : () => onStatusChanged(s),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ─── Card shell ──────────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final bool isOnline;
  final Widget child;
  const _CardShell({required this.isOnline, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: isOnline
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.isDark
                    ? [
                        palette.primary.withValues(alpha: 0.30),
                        palette.primaryStrong.withValues(alpha: 0.18),
                      ]
                    : [palette.primary, palette.primaryStrong],
              )
            : null,
        color: isOnline ? null : palette.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? Colors.white.withValues(alpha: 0.14)
              : palette.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? palette.primary.withValues(alpha: palette.isDark ? 0.18 : 0.24)
                : Colors.black.withValues(alpha: palette.isDark ? 0.14 : 0.04),
            blurRadius: isOnline ? 24 : 10,
            offset: Offset(0, isOnline ? 10 : 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Mode pill ───────────────────────────────────────────────────────────────

class _ModePill extends StatelessWidget {
  final HelperAvailabilityState status;
  final bool isSelected;
  final bool isOnlineMode;
  final VoidCallback? onTap;

  const _ModePill({
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
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 38,
          decoration: BoxDecoration(
            color: isSelected
                ? (isOnlineMode
                    ? Colors.white.withValues(alpha: 0.18)
                    : accent.withValues(alpha: palette.isDark ? 0.16 : 0.10))
                : (isOnlineMode
                    ? Colors.white.withValues(alpha: 0.07)
                    : palette.surfaceInset),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (isOnlineMode
                      ? Colors.white.withValues(alpha: 0.38)
                      : accent.withValues(alpha: 0.45))
                  : (isOnlineMode
                      ? Colors.white.withValues(alpha: 0.10)
                      : palette.border.withValues(alpha: 0.70)),
              width: isSelected ? 1.0 : 0.6,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? (isOnlineMode ? Colors.white : accent)
                      : (isOnlineMode
                          ? Colors.white.withValues(alpha: 0.38)
                          : palette.textMuted),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _label(status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? (isOnlineMode ? Colors.white : palette.textPrimary)
                      : (isOnlineMode
                          ? Colors.white.withValues(alpha: 0.65)
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
      case HelperAvailabilityState.offline:
        return 'Offline';
      case HelperAvailabilityState.busy:
        return 'Busy';
    }
  }

  Color _accent(HelperAvailabilityState s, AppColors p) {
    switch (s) {
      case HelperAvailabilityState.availableNow:
        return const Color(0xFF22C55E);
      case HelperAvailabilityState.scheduledOnly:
        return const Color(0xFFFFB020);
      case HelperAvailabilityState.busy:
        return p.danger;
      case HelperAvailabilityState.offline:
        return p.textMuted;
    }
  }
}
