import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_entity.dart';
import '../cubit/booking_cubit.dart';
import 'my_bookings_page.dart';

class BookingConfirmationPage extends StatelessWidget {
  final HelperEntity helper;

  const BookingConfirmationPage({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirm Booking')),
        body: BlocConsumer<BookingCubit, BookingState>(
          listener: (context, state) {
            if (state is BookingSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Successful!')));
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MyBookingsPage()),
                (route) => route.isFirst,
              );
            } else if (state is BookingError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected Helper', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: helper.profileImageUrl != null ? NetworkImage(helper.profileImageUrl!) : null,
                        child: helper.profileImageUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(helper.name),
                      subtitle: Text('\$${helper.pricePerHour}/hr'),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is BookingLoading
                          ? null
                          : () => context.read<BookingCubit>().createScheduledBooking(),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      child: state is BookingLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Confirm & Pay'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
