import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../../../../../core/widgets/app_loading.dart';
import '../../../domain/entities/helper_availability_state.dart';
import '../../cubit/helper_bookings_cubits.dart';

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
    final isOnline = currentStatus == HelperAvailabilityState.availableNow;

    return BlocBuilder<HelperAvailabilityCubit, HelperAvailabilityStatus>(
      builder: (context, availState) {
        final isUpdating = availState is AvailabilityUpdating;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.all(AppSpacing.pageGutter),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOnline
                  ? [
                      BrandTokens.primaryBlue,
                      BrandTokens.primaryBlue.withValues(alpha: 0.8),
                    ]
                  : [BrandTokens.surfaceWhite, BrandTokens.surfaceWhite],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isOnline
                  ? Colors.white.withValues(alpha: 0.2)
                  : BrandTokens.borderSoft.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: isOnline
                    ? BrandTokens.primaryBlue.withValues(alpha: 0.25)
                    : BrandTokens.textSecondary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PulseIndicator(
                    isOnline: isOnline,
                    pulseAnimation: pulseAnimation,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline ? 'Active & Online' : 'Currently Offline',
                          style: BrandTypography.title(
                            color: isOnline
                                ? Colors.white
                                : BrandTokens.textPrimary,
                          ),
                        ),
                        Text(
                          isOnline
                              ? 'You are visible to travelers'
                              : 'Tap the toggle to go online',
                          style: BrandTypography.caption(
                            color: isOnline
                                ? Colors.white.withValues(alpha: 0.8)
                                : BrandTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpdating)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: AppSpinner(
                        size: 22,
                        strokeWidth: 2,
                        color: isOnline
                            ? Colors.white
                            : BrandTokens.primaryBlue,
                      ),
                    )
                  else
                    Switch.adaptive(
                      value: isOnline,
                      onChanged: (val) {
                        onStatusChanged(
                          val
                              ? HelperAvailabilityState.availableNow
                              : HelperAvailabilityState.offline,
                        );
                      },
                      activeTrackColor: Colors.white.withValues(alpha: 0.3),
                      inactiveTrackColor: BrandTokens.borderSoft,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(
                color: isOnline
                    ? Colors.white.withValues(alpha: 0.15)
                    : BrandTokens.borderSoft,
                height: 1,
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: HelperAvailabilityState.values.map((s) {
                    final selected = s == currentStatus;
                    return _StatusChip(
                      status: s,
                      isSelected: selected,
                      isOnline: isOnline,
                      onTap: isUpdating ? null : () => onStatusChanged(s),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PulseIndicator extends StatelessWidget {
  final bool isOnline;
  final Animation<double> pulseAnimation;

  const _PulseIndicator({required this.isOnline, required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (_, __) => Transform.scale(
        scale: isOnline ? pulseAnimation.value : 1.0,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOnline
                ? Colors.white
                : BrandTokens.textSecondary.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            boxShadow: isOnline
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final HelperAvailabilityState status;
  final bool isSelected;
  final bool isOnline;
  final VoidCallback? onTap;

  const _StatusChip({
    required this.status,
    required this.isSelected,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isOnline ? Colors.white : BrandTokens.primaryBlue)
              : (isOnline
                    ? Colors.white.withValues(alpha: 0.1)
                    : BrandTokens.borderSoft.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected
                    ? _dotColor(status)
                    : (isOnline
                          ? Colors.white.withValues(alpha: 0.5)
                          : BrandTokens.textMuted),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _label(status),
              style: BrandTypography.caption(
                color: isSelected
                    ? (isOnline ? BrandTokens.primaryBlue : Colors.white)
                    : (isOnline
                          ? Colors.white.withValues(alpha: 0.7)
                          : BrandTokens.textSecondary),
              ),
            ),
          ],
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

  Color _dotColor(HelperAvailabilityState s) {
    switch (s) {
      case HelperAvailabilityState.availableNow:
        return BrandTokens.successGreen;
      case HelperAvailabilityState.scheduledOnly:
        return BrandTokens.accentAmber;
      case HelperAvailabilityState.busy:
        return BrandTokens.dangerRed;
      case HelperAvailabilityState.offline:
        return BrandTokens.textMuted;
    }
  }
}
