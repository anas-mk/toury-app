import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/helper_bookings_cubit.dart';
import '../cubit/helper_bookings_state.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HelperBookingsCubit>().fetchRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Requests')),
      body: BlocBuilder<HelperBookingsCubit, HelperBookingsState>(
        builder: (context, state) {
          if (state.isLoading && state.requests.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.errorMessage != null) return Center(child: Text(state.errorMessage!));
          
          if (state.requests.isEmpty) return const Center(child: Text('No requests found'));
          return ListView.builder(
            itemCount: state.requests.length,
            itemBuilder: (context, index) {
              final booking = state.requests[index];
              final isItemLoading = state.actionLoadingId == booking.id;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: booking.touristImage != null ? NetworkImage(booking.touristImage!) : null,
                    child: booking.touristImage == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(booking.touristName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('To: ${booking.destination}'),
                      Text(DateFormat('MMM dd, yyyy - HH:mm').format(booking.date)),
                      Text('Price: \$${booking.price.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: isItemLoading ? null : () => context.read<HelperBookingsCubit>().acceptBooking(booking.id),
                    child: isItemLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Accept'),
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
