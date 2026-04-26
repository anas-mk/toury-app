import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../domain/entities/helper_booking_entities.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOnline = currentStatus == HelperAvailabilityState.availableNow;
    
    return BlocBuilder<HelperAvailabilityCubit, HelperAvailabilityStatus>(
      builder: (context, availState) {
        final isUpdating = availState is AvailabilityUpdating;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOnline
                  ? [AppColor.accentColor, AppColor.accentColor.withOpacity(0.8)]
                  : [
                      isDark ? AppColor.darkCardColor : Colors.white,
                      isDark ? AppColor.darkCardColor.withOpacity(0.8) : Colors.white.withOpacity(0.9)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: isOnline 
                  ? Colors.white.withOpacity(0.2) 
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            ),
            boxShadow: [
              BoxShadow(
                color: isOnline
                    ? AppColor.accentColor.withOpacity(0.25)
                    : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline ? 'Active & Online' : 'Currently Offline',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isOnline ? Colors.white : (isDark ? Colors.white : Colors.black),
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isOnline ? 'You are visible to travelers' : 'Tap the toggle to go online',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOnline 
                                ? Colors.white.withOpacity(0.8) 
                                : (isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpdating)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: isOnline ? Colors.white : theme.colorScheme.primary, 
                        strokeWidth: 2
                      ),
                    )
                  else
                    Switch.adaptive(
                      value: isOnline,
                      onChanged: (val) {
                        onStatusChanged(val ? HelperAvailabilityState.availableNow : HelperAvailabilityState.offline);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white24,
                      inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLG),
              Divider(
                color: isOnline ? Colors.white24 : (isDark ? Colors.white10 : Colors.black12), 
                height: 1
              ),
              const SizedBox(height: AppTheme.spaceMD),
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
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isOnline ? Colors.white : AppColor.warningColor.withOpacity(0.5),
            shape: BoxShape.circle,
            boxShadow: isOnline
                ? [BoxShadow(color: Colors.white.withOpacity(0.8), blurRadius: 10)]
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppTheme.spaceSM),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isOnline ? Colors.white : theme.colorScheme.primary) 
              : (isOnline ? Colors.white.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: isSelected ? Colors.transparent : (isOnline ? Colors.white10 : Colors.transparent),
          ),
        ),
        child: Text(
          _label(status),
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected 
                ? (isOnline ? AppColor.accentColor : (isDark ? Colors.black : Colors.white)) 
                : (isOnline ? Colors.white70 : (isDark ? AppColor.darkTextSecondary : AppColor.lightTextSecondary)),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _label(HelperAvailabilityState s) {
    switch (s) {
      case HelperAvailabilityState.availableNow:  return '🟢 Online';
      case HelperAvailabilityState.scheduledOnly: return '📅 Scheduled';
      case HelperAvailabilityState.busy:          return '🔴 Busy';
      case HelperAvailabilityState.offline:       return '⚫ Offline';
    }
  }
}
