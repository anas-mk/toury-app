import 'package:flutter/material.dart';
import '../../../helper_bookings/domain/entities/helper_booking_entity.dart';

class RequestsPreviewSection extends StatelessWidget {
  final List<HelperBookingEntity> requests;
  final Function(String) onAccept;
  final VoidCallback onViewAll;
  final String? actionLoadingId;

  const RequestsPreviewSection({
    super.key,
    required this.requests,
    required this.onAccept,
    required this.onViewAll,
    this.actionLoadingId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayRequests = requests.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Booking Requests (${requests.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
          ],
        ),
        if (requests.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No new requests', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayRequests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = displayRequests[index];
              final isLoading = actionLoadingId == booking.id;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: booking.touristImage != null ? NetworkImage(booking.touristImage!) : null,
                      child: booking.touristImage == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.touristName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'To: ${booking.destination}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isLoading ? null : () => onAccept(booking.id),
                      child: isLoading
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Accept', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
