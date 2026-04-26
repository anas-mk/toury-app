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
            if (isInstant) {
              context.goNamed(
                'waiting-helper',
                pathParameters: {'id': state.booking.id},
                extra: {'booking': state.booking},
              );
            } else {
              context.goNamed(
                'payment-method',
                pathParameters: {'bookingId': state.booking.id},
              );
            }
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
                      text: isInstant ? 'Request Now' : 'Proceed to Payment',
                      isLoading: state is BookingLoading,
                      onPressed: () => _onConfirm(context),
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

  void _onConfirm(BuildContext context) {
    if (isInstant) {
      final params = searchParams as InstantSearchParams;
      context.read<BookingCubit>().createInstant(
        params: params,
        helperId: helper.id,
      );
    } else {
      final params = searchParams as ScheduledSearchParams;
      context.read<BookingCubit>().createScheduled(
        helperId: helper.id,
        params: params,
      );
    }
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
          if (helper.hourlyRate != null)
            Text('${helper.hourlyRate!.toStringAsFixed(0)} EGP/hr'),
        ],
      ),
    );
  }

  Widget _buildTripDetails(ThemeData theme) {
    String city = '';
    String time = '';
    int duration = 0;

    if (isInstant) {
      final params = searchParams as InstantSearchParams;
      city = params.pickupLocationName;
      time = 'Starting Now';
      duration = params.durationInMinutes;
    } else {
      final params = searchParams as ScheduledSearchParams;
      city = params.destinationCity;
      time = '${DateFormat('MMM dd, yyyy').format(params.requestedDate)} at ${params.startTime}';
      duration = params.durationInMinutes;
    }

    final durationText = duration >= 60
        ? '${duration ~/ 60}h ${duration % 60 > 0 ? "${duration % 60}m" : ""}'.trim()
        : '${duration}m';

    return Column(
      children: [
        _buildDetailRow(Icons.location_on_rounded, 'City / Pickup', city),
        const SizedBox(height: AppTheme.spaceSM),
        _buildDetailRow(Icons.access_time_rounded, 'Time', time),
        const SizedBox(height: AppTheme.spaceSM),
        _buildDetailRow(Icons.hourglass_bottom_rounded, 'Duration', durationText),
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
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildPaymentSummary(ThemeData theme) {
    // Prefer the API-calculated estimated price; fall back to computing from hourly rate
    final estimatedPrice = helper.estimatedPrice;
    final hourlyRate = helper.hourlyRate ?? 0;
    final duration = isInstant
        ? (searchParams as InstantSearchParams).durationInMinutes
        : (searchParams as ScheduledSearchParams).durationInMinutes;
    final computedTotal = hourlyRate * (duration / 60);
    final displayTotal = estimatedPrice ?? computedTotal;

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
              Text(estimatedPrice != null ? 'Estimated Price' : 'Approx. Price'),
              Text('${displayTotal.toStringAsFixed(2)} EGP'),
            ],
          ),
          const Divider(height: AppTheme.spaceLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${displayTotal.toStringAsFixed(2)} EGP',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColor.accentColor),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSM),
          const Text(
            '* Final price confirmed after helper acceptance.',
            style: TextStyle(fontSize: 11, color: AppColor.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}
