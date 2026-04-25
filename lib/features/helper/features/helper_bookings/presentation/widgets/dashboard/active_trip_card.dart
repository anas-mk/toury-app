import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../domain/entities/helper_booking_entities.dart';

class ActiveTripCard extends StatelessWidget {
  final HelperBooking booking;

  const ActiveTripCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRouter.helperActiveBooking, extra: booking.id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3B38B5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🔴  ONGOING TRIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              booking.travelerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    booking.destinationLocation,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _TripAction(
                    label: 'Navigation',
                    icon: Icons.navigation_rounded,
                    onTap: () => context.push(AppRouter.helperActiveBooking, extra: booking.id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TripAction(
                    label: 'Chat',
                    icon: Icons.chat_bubble_rounded,
                    outline: true,
                    onTap: () => context.push(AppRouter.helperActiveBooking, extra: booking.id), // Simplified for now
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool outline;

  const _TripAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : Colors.white,
          border: outline ? Border.all(color: Colors.white30) : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: outline ? Colors.white : const Color(0xFF6C63FF),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: outline ? Colors.white : const Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
