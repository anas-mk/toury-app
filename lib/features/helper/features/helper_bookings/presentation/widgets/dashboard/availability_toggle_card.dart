import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final isOnline = currentStatus == HelperAvailabilityState.availableNow;
    
    return BlocBuilder<HelperAvailabilityCubit, HelperAvailabilityStatus>(
      builder: (context, availState) {
        final isUpdating = availState is AvailabilityUpdating;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOnline
                  ? [const Color(0xFF00C896), const Color(0xFF007A5E)]
                  : [const Color(0xFF1E2340), const Color(0xFF141829)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isOnline
                    ? const Color(0xFF00C896).withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
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
                          isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isOnline ? 'Ready for requests' : 'Toggle to start working',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUpdating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  else
                    Switch.adaptive(
                      value: isOnline,
                      onChanged: (val) {
                        onStatusChanged(val ? HelperAvailabilityState.availableNow : HelperAvailabilityState.offline);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white24,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12, height: 1),
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
            color: isOnline ? Colors.white : Colors.white.withOpacity(0.3),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white10,
          ),
        ),
        child: Text(
          _label(status),
          style: TextStyle(
            color: isSelected 
                ? (isOnline ? const Color(0xFF007A5E) : const Color(0xFF141829)) 
                : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _label(HelperAvailabilityState s) {
    switch (s) {
      case HelperAvailabilityState.availableNow:  return '🟢 Online';
      case HelperAvailabilityState.scheduledOnly: return '📅 Scheduled Only';
      case HelperAvailabilityState.busy:          return '🔴 Busy';
      case HelperAvailabilityState.offline:       return '⚫ Offline';
    }
  }
}
