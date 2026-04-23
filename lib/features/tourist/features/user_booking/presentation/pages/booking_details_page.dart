import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../cubit/booking_cubit.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import 'alternatives_page.dart';

class BookingDetailsPage extends StatelessWidget {
  final String bookingId;

  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingCubit>()..loadDetails(bookingId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: BlocConsumer<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingCancelled) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Cancelled')));
              Navigator.pop(context);
            }
          },
          builder: (context, state) {
            if (state is BookingLoading) {
              return const LoadingIndicator();
            } else if (state is BookingError) {
              return ErrorView(
                message: state.message,
                onRetry: () => context.read<BookingCubit>().loadDetails(bookingId),
              );
            } else if (state is BookingSuccess) {
              final booking = state.booking;
              final isCancellable = booking.status.toLowerCase() != 'cancelled' && booking.status.toLowerCase() != 'completed';

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _DetailRow('Booking ID', booking.id),
                            const Divider(),
                            _DetailRow('Status', booking.status.toUpperCase(), isHighlight: true),
                            const Divider(),
                            _DetailRow('Type', booking.type),
                            const Divider(),
                            if (booking.scheduledDate != null) ...[
                              _DetailRow('Date', booking.scheduledDate.toString().split(' ')[0]),
                              const Divider(),
                            ],
                            _DetailRow('Created At', booking.createdAt.toString().split(' ')[0]),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (booking.status.toLowerCase() == 'cancelled')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AlternativesPage(bookingId: booking.id)),
                            );
                          },
                          child: const Text('Find Alternatives'),
                        ),
                      ),
                    if (isCancellable)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _confirmCancel(context, booking.id),
                          child: const Text('Cancel Booking'),
                        ),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BookingCubit>().cancelBooking(id, 'User requested cancellation');
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isHighlight;

  const _DetailRow(this.title, this.value, {this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }
}
