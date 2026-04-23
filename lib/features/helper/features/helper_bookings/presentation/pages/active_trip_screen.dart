import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/helper_bookings_cubit.dart';
import '../cubit/helper_bookings_state.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HelperBookingsCubit>().fetchActive();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Trip')),
      body: BlocBuilder<HelperBookingsCubit, HelperBookingsState>(
        builder: (context, state) {
          if (state.isLoading && state.active == null) return const Center(child: CircularProgressIndicator());
          if (state.errorMessage != null) return Center(child: Text(state.errorMessage!));
          
          final booking = state.active;
          if (booking == null) return const Center(child: Text('No active trip at the moment'));
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Currently with: ${booking.touristName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Destination: ${booking.destination}'),
                Text('Started at: ${DateFormat('HH:mm').format(booking.date)}'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: state.actionLoadingId != null ? null : () => context.read<HelperBookingsCubit>().endTrip(booking.id),
                    child: state.actionLoadingId == booking.id 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('End Trip'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
