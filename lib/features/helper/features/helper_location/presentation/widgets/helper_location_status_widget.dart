import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../cubit/helper_location_cubit.dart';
import '../cubit/location_status_cubits.dart';
import '../../data/services/helper_location_signalr_service.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';

class HelperLocationStatusWidget extends StatelessWidget {
  const HelperLocationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<LocationStatusCubit, LocationStatusState>(
      builder: (context, statusState) {
        return BlocBuilder<HelperLocationCubit, HelperLocationState>(
          builder: (context, locState) {
            bool isTracking = locState is HelperLocationTracking;
            bool isEligible = false;
            int secondsSinceUpdate = 0;
            String availability = 'Offline';

            if (statusState is LocationStatusLoaded) {
              isEligible = statusState.status.isLocationFresh && statusState.status.canReceiveInstantRequests;
              secondsSinceUpdate = statusState.status.secondsSinceLastUpdate;
              availability = statusState.status.availabilityState;
            }

            final Color statusColor = isEligible 
                ? AppColor.accentColor 
                : (availability == 'Offline' ? theme.colorScheme.onSurface.withOpacity(0.3) : AppColor.warningColor);

            return GestureDetector(
              onTap: () => context.push('/helper/location'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMD),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border: Border.all(color: statusColor.withOpacity(0.15), width: 1.5),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          statusColor.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        _StatusIcon(color: statusColor, isEligible: isEligible),
                        const SizedBox(width: AppTheme.spaceMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isTracking ? 'TRACKING ACTIVE' : 'SYSTEM OFFLINE',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _LivePulse(color: statusColor),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isTracking 
                                    ? 'Last sync: $secondsSinceUpdate s ago • $availability' 
                                    : 'Tap to initialize tracking engine',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _EligibilityBadge(isEligible: isEligible, availability: availability),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final Color color;
  final bool isEligible;
  const _StatusIcon({required this.color, required this.isEligible});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Center(
        child: Icon(
          isEligible ? Icons.radar_rounded : Icons.location_off_rounded,
          color: color,
          size: 22,
        ),
      ),
    );
  }
}

class _LivePulse extends StatefulWidget {
  final Color color;
  const _LivePulse({required this.color});

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.6 * _controller.value),
                blurRadius: 6 * _controller.value,
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EligibilityBadge extends StatelessWidget {
  final bool isEligible;
  final String availability;
  const _EligibilityBadge({required this.isEligible, required this.availability});

  @override
  Widget build(BuildContext context) {
    final color = isEligible ? AppColor.accentColor : AppColor.warningColor;
    final label = isEligible ? 'ELIGIBLE' : (availability == 'Offline' ? 'INACTIVE' : 'STALE');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
