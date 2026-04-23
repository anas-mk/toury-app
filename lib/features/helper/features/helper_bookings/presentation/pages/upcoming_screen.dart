import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/helper_bookings_cubit.dart';
import '../cubit/helper_bookings_state.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HelperBookingsCubit>().fetchUpcoming();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Bookings')),
      body: BlocBuilder<HelperBookingsCubit, HelperBookingsState>(
        builder: (context, state) {
          if (state.isLoading && state.upcoming.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.errorMessage != null) return Center(child: Text(state.errorMessage!));
          
          if (state.upcoming.isEmpty) return const Center(child: Text('No upcoming bookings'));
          return ListView.builder(
            itemCount: state.upcoming.length,
            itemBuilder: (context, index) {
              final booking = state.upcoming[index];
              final isItemLoading = state.actionLoadingId == booking.id;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('To: ${booking.destination}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tourist: ${booking.touristName}'),
                      Text(DateFormat('MMM dd, yyyy - HH:mm').format(booking.date)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: (booking.canStartTrip && !isItemLoading) 
                        ? () => context.read<HelperBookingsCubit>().startTrip(booking.id)
                        : null,
                    child: isItemLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Start'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
