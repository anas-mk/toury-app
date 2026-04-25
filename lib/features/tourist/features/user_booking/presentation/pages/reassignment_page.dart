import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/alternatives_cubit.dart';
import '../widgets/helper_search_item.dart';

class ReassignmentPage extends StatelessWidget {
  final String bookingId;
  final BookingDetailEntity booking;

  const ReassignmentPage({
    super.key,
    required this.bookingId,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AlternativesCubit>()..getAlternatives(bookingId),
      child: Scaffold(
        appBar: const BasicAppBar(
          title: 'Find Another Helper',
          showBackButton: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Helper unavailable',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                          ),
                          Text(
                            'The helper was unable to accept your request. Choose another helper below.',
                            style: TextStyle(fontSize: 13, color: Colors.red[900]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Available Alternatives',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: BlocBuilder<AlternativesCubit, AlternativesState>(
                  builder: (context, state) {
                    if (state is AlternativesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is AlternativesError) {
                      return Center(child: Text('Error: ${state.message}'));
                    } else if (state is AlternativesLoaded) {
                      if (state.helpers.isEmpty) {
                        return const Center(child: Text('No other helpers available at the moment.'));
                      }
                      return ListView.separated(
                        itemCount: state.helpers.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 15),
                        itemBuilder: (context, index) {
                          final helper = state.helpers[index];
                          return HelperSearchItem(
                            helper: helper,
                            onTap: () {
                              // Logic to reassign to this helper
                              // For now, go back to confirm
                              context.push('/booking-confirm', extra: {
                                'helper': helper,
                                'isInstant': booking.type == BookingType.instant,
                                'searchParams': _getParamsFromBooking(booking),
                              });
                            },
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Cancel Booking',
                color: Colors.grey[200],
                textStyle: const TextStyle(color: Colors.black),
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  dynamic _getParamsFromBooking(BookingDetailEntity booking) {
    // Helper to recreate search params from booking entity
    return null; // Implementation depends on details
  }
}
