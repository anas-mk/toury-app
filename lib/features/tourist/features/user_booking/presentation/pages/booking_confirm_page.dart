import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../../domain/entities/search_params.dart';
import '../cubits/instant_booking_cubit.dart';
import '../cubits/scheduled_booking_cubit.dart';

class BookingConfirmPage extends StatefulWidget {
  final HelperBookingEntity helper;
  final dynamic searchParams;
  final bool isInstant;

  const BookingConfirmPage({
    super.key,
    required this.helper,
    required this.searchParams,
    this.isInstant = false,
  });

  @override
  State<BookingConfirmPage> createState() => _BookingConfirmPageState();
}

class _BookingConfirmPageState extends State<BookingConfirmPage> {
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<ScheduledBookingCubit>()),
        BlocProvider(create: (context) => sl<InstantBookingCubit>()),
      ],
      child: Scaffold(
        appBar: const BasicAppBar(
          title: 'Confirm Booking',
          showBackButton: true,
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<ScheduledBookingCubit, ScheduledBookingState>(
              listener: (context, state) {
                if (state is ScheduledBookingSuccess) {
                  context.go('/booking-details/${state.booking.id}', extra: {'booking': state.booking});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking created successfully!')),
                  );
                } else if (state is ScheduledBookingError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
            BlocListener<InstantBookingCubit, InstantBookingState>(
              listener: (context, state) {
                if (state is InstantBookingWaitingResponse) {
                  context.go('/waiting-helper/${state.booking.id}', extra: {'booking': state.booking});
                } else if (state is InstantBookingError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
          ],
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelperSummary(),
                const SizedBox(height: 20),
                _buildTripSummary(),
                const SizedBox(height: 20),
                const Text('Add Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _notesController,
                  hintText: 'Any special requests or instructions...',
                  maxLines: 4,
                ),
                const SizedBox(height: 30),
                _buildPriceBreakdown(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          ),
          child: BlocBuilder<ScheduledBookingCubit, ScheduledBookingState>(
            builder: (context, scheduledState) {
              return BlocBuilder<InstantBookingCubit, InstantBookingState>(
                builder: (context, instantState) {
                  final isLoading = scheduledState is ScheduledBookingLoading || instantState is InstantBookingLoading;
                  return CustomButton(
                    text: 'Confirm & Book',
                    isLoading: isLoading,
                    onPressed: () => _confirmBooking(context),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHelperSummary() {
    return CustomCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(widget.helper.profileImageUrl ?? ''),
        ),
        title: Text(widget.helper.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${widget.helper.rating} ★ • ${widget.helper.tripsCount} trips'),
      ),
    );
  }

  Widget _buildTripSummary() {
    if (widget.isInstant) {
      final params = widget.searchParams as InstantSearchParams;
      return CustomCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _buildSummaryRow(Icons.my_location, 'Pickup', params.pickupLocationName),
            const Divider(),
            _buildSummaryRow(Icons.timer, 'Duration', '${params.durationInMinutes} Minutes'),
          ],
        ),
      );
    } else {
      final params = widget.searchParams as ScheduledSearchParams;
      return CustomCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _buildSummaryRow(Icons.location_on, 'Destination', params.destinationCity),
            const Divider(),
            _buildSummaryRow(Icons.calendar_today, 'Date', '${params.requestedDate.day}/${params.requestedDate.month}/${params.requestedDate.year}'),
            const Divider(),
            _buildSummaryRow(Icons.access_time, 'Start Time', params.startTime),
            const Divider(),
            _buildSummaryRow(Icons.timer, 'Duration', '${params.durationInMinutes} Minutes'),
          ],
        ),
      );
    }
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Price Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        _buildPriceRow('Service Fee', '\$50.00'),
        _buildPriceRow('Duration Fee', '\$20.00'),
        if (widget.helper.car != null) _buildPriceRow('Car Surcharge', '\$15.00'),
        const Divider(),
        _buildPriceRow('Total', '\$85.00', isTotal: true),
      ],
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14)),
          Text(amount, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 14, color: isTotal ? Colors.blue : Colors.black)),
        ],
      ),
    );
  }

  void _confirmBooking(BuildContext context) {
    final Map<String, dynamic> data = {
      'helperId': widget.helper.id,
      'notes': _notesController.text,
    };

    if (widget.isInstant) {
      final params = widget.searchParams as InstantSearchParams;
      data.addAll(params.toJson());
      context.read<InstantBookingCubit>().createInstantBooking(data);
    } else {
      final params = widget.searchParams as ScheduledSearchParams;
      data.addAll(params.toJson());
      context.read<ScheduledBookingCubit>().createBooking(data);
    }
  }
}
