import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_card.dart';

class BookingHomePage extends StatelessWidget {
  const BookingHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BasicAppBar(
        title: 'Book a Rafiq',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How would you like to travel?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose your preferred booking method',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            _buildBookingOption(
              context,
              title: 'Instant Ride',
              description: 'Get a nearby helper right now. Like Uber, but with a local guide.',
              icon: Icons.bolt,
              color: Colors.amber,
              onTap: () => context.push('/instant-search'),
            ),
            const SizedBox(height: 20),
            _buildBookingOption(
              context,
              title: 'Scheduled Booking',
              description: 'Plan your trip in advance. Choose your helper, date, and time.',
              icon: Icons.calendar_today,
              color: Colors.blue,
              onTap: () => context.push('/scheduled-search'),
            ),
            const SizedBox(height: 40),
            const Text(
              'Recent Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            CustomCard(
              onTap: () => context.push('/my-bookings'),
              child: const ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  child: Icon(Icons.history, color: Colors.white),
                ),
                title: Text('View Booking History'),
                subtitle: Text('Manage your past and upcoming trips'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
