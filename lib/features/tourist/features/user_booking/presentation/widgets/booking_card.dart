import 'package:flutter/material.dart';
import '../../domain/entities/booking_entity.dart';

class BookingCard extends StatelessWidget {
  final BookingEntity booking;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        title: Text('Booking #${booking.id.substring(0, 8)}...'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${booking.type}'),
            if (booking.scheduledDate != null)
              Text('Date: ${booking.scheduledDate.toString().split(' ')[0]}'),
          ],
        ),
        trailing: Chip(
          label: Text(booking.status),
          backgroundColor: _getStatusColor(booking.status),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.blue.shade100;
    }
  }
}
