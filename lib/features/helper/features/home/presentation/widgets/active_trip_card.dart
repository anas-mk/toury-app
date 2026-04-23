import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/router/app_router.dart';

import '../../../helper_bookings/domain/entities/helper_booking_entity.dart';

class ActiveTripCard extends StatelessWidget {
  final HelperBookingEntity? activeTrip;
  final VoidCallback? onEndTrip;
  final bool isActionLoading;

  const ActiveTripCard({
    super.key,
    this.activeTrip,
    this.onEndTrip,
    this.isActionLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activeTrip == null) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey),
              SizedBox(width: 12),
              Text('No active trip at the moment', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ACTIVE TRIP',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Ongoing',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              activeTrip!.touristName,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Destination: ${activeTrip!.destination}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => context.push(AppRouter.helperChat.replaceFirst(':bookingId', activeTrip!.id)),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isActionLoading ? null : onEndTrip,
                    child: isActionLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('End Trip', style: TextStyle(fontWeight: FontWeight.bold)),
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
