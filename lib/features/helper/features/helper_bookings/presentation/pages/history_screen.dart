import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/helper_bookings_cubit.dart';
import '../cubit/helper_bookings_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HelperBookingsCubit>().fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip History')),
      body: BlocBuilder<HelperBookingsCubit, HelperBookingsState>(
        builder: (context, state) {
          if (state.isLoading && state.history.isEmpty) return const Center(child: CircularProgressIndicator());
          if (state.errorMessage != null) return Center(child: Text(state.errorMessage!));
          
          if (state.history.isEmpty) return const Center(child: Text('No history found'));
          return ListView.builder(
            itemCount: state.history.length,
            itemBuilder: (context, index) {
              final booking = state.history[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(booking.destination),
                  subtitle: Text('Tourist: ${booking.touristName}\nDate: ${DateFormat('MMM dd, yyyy').format(booking.date)}'),
                  trailing: Text('\$${booking.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
