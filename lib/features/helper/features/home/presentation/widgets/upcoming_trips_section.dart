import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../helper_bookings/domain/entities/helper_booking_entity.dart';

class UpcomingTripsSection extends StatelessWidget {
  final List<HelperBookingEntity> upcoming;
  final Function(String) onStart;
  final VoidCallback onViewAll;
  final String? actionLoadingId;

  const UpcomingTripsSection({
    super.key,
    required this.upcoming,
    required this.onStart,
    required this.onViewAll,
    this.actionLoadingId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayUpcoming = upcoming.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Trips',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
          ],
        ),
        if (upcoming.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No upcoming trips', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayUpcoming.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final booking = displayUpcoming[index];
                final isLoading = actionLoadingId == booking.id;

                return Container(
                  width: 200,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM dd, HH:mm').format(booking.date),
                        style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.destination,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        booking.touristName,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            side: BorderSide(color: booking.canStartTrip ? theme.primaryColor : Colors.grey.shade300),
                          ),
                          onPressed: (booking.canStartTrip && !isLoading) ? () => onStart(booking.id) : null,
                          child: isLoading
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(
                                  'Start Trip',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: booking.canStartTrip ? theme.primaryColor : Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
