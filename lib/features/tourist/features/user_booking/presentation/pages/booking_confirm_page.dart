import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../../domain/entities/search_params.dart';
import '../cubits/booking_cubit.dart';
import '../cubits/booking_state.dart';

class BookingConfirmPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => sl<BookingCubit>(),
      child: BlocListener<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingCreated) {
            // Instant flow has been moved to InstantBookingCubit and
            // its dedicated screens — this page only handles Scheduled
            // bookings now. Route straight to payment.
            context.goNamed(
              'payment-method',
              pathParameters: {'bookingId': state.booking.id},
            );
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColor.errorColor),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Confirm Booking'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(theme, 'Helper Info'),
                const SizedBox(height: AppTheme.spaceMD),
                _buildHelperSummary(theme),
                const SizedBox(height: AppTheme.spaceXL),
                
                _buildSectionTitle(theme, 'Trip Details'),
                const SizedBox(height: AppTheme.spaceMD),
                _buildTripDetails(theme),
                const SizedBox(height: AppTheme.spaceXL),
                
                _buildSectionTitle(theme, 'Payment Summary'),
                const SizedBox(height: AppTheme.spaceMD),
                _buildPaymentSummary(theme),
                
                const Spacer(),
                
                BlocBuilder<BookingCubit, BookingState>(
                  builder: (context, state) {
                    return CustomButton(
                      text: 'Proceed to Payment',
                      isLoading: state is BookingLoading,
                      onPressed: () {
                        final params = searchParams as ScheduledSearchParams;
                        context.read<BookingCubit>().createScheduled(
                              helperId: helper.id,
                              destinationCity: params.destinationCity,
                              requestedDate: params.requestedDate,
                              startTime: params.startTime,
                              durationInMinutes: params.durationInMinutes,
                            );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spaceXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColor.primaryColor),
    );
  }

  Widget _buildHelperSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppColor.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppColor.lightBorder),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColor.lightBorder,
            child: Icon(Icons.person, color: AppColor.primaryColor),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Text(helper.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${helper.hourlyRate ?? 0} USD/hr'),
        ],
      ),
    );
  }

  Widget _buildTripDetails(ThemeData theme) {
    String city = '';
    String time = '';
    if (isInstant) {
      city = (searchParams as InstantSearchParams).pickupLocationName;
      time = 'Starting Now';
    } else {
      final params = searchParams as ScheduledSearchParams;
      city = params.destinationCity;
      time = '${DateFormat('MMM dd').format(params.requestedDate)} at ${params.startTime}';
    }

    return Column(
      children: [
        _buildDetailRow(Icons.location_on_rounded, 'City', city),
        const SizedBox(height: AppTheme.spaceSM),
        _buildDetailRow(Icons.access_time_rounded, 'Time', time),
        const SizedBox(height: AppTheme.spaceSM),
        _buildDetailRow(Icons.hourglass_bottom_rounded, 'Duration', '4 Hours'),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColor.lightTextSecondary),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(color: AppColor.lightTextSecondary)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPaymentSummary(ThemeData theme) {
    final hourlyRate = helper.hourlyRate ?? 0;
    final total = hourlyRate * 4;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: AppColor.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hourly Rate x 4'),
              Text('${hourlyRate * 4} USD'),
            ],
          ),
          const Divider(height: AppTheme.spaceLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '$total USD',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColor.accentColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
