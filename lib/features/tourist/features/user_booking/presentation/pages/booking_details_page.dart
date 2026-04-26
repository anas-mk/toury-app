import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/booking_status_cubit.dart';
import '../cubits/booking_status_state.dart';
import '../cubits/booking_cubit.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;
  final BookingDetailEntity? initialBooking;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
    this.initialBooking,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => sl<BookingStatusCubit>()..refreshActiveBooking(widget.bookingId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {},
            ),
          ],
        ),
        body: BlocBuilder<BookingStatusCubit, BookingStatusState>(
          builder: (context, state) {
            if (state is BookingStatusLoading && widget.initialBooking == null) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final booking = (state is BookingStatusActive) 
                ? state.booking 
                : widget.initialBooking;

            if (booking == null) {
              return const Center(child: Text('Booking not found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(booking),
                  const SizedBox(height: AppTheme.spaceXL),
                  
                  _buildHelperInfo(theme, booking),
                  const SizedBox(height: AppTheme.spaceXL),
                  
                  _buildTripSummary(theme, booking),
                  const SizedBox(height: AppTheme.spaceXL),
                  
                  _buildActionButtons(context, booking),
                  const SizedBox(height: AppTheme.space2XL),
                  
                  if (booking.status != BookingStatus.completed && booking.status != BookingStatus.cancelledByUser && booking.status != BookingStatus.cancelledByHelper && booking.status != BookingStatus.cancelledBySystem)
                    _buildCancelOption(context, booking),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBanner(BookingDetailEntity booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        color: AppColor.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.shadowMedium(context),
      ),
      child: Column(
        children: [
          Text(
            'STATUS',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            booking.status.name.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildHelperInfo(ThemeData theme, BookingDetailEntity booking) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          child: AppNetworkImage(
            imageUrl: booking.helper?.profileImageUrl ?? '',
            width: 60,
            height: 60,
          ),
        ),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.helper?.name ?? 'Helper', style: theme.textTheme.titleLarge),
              Text('Your professional local helper', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.pushNamed('user-chat', pathParameters: {'id': booking.id}),
          icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColor.primaryColor),
          style: IconButton.styleFrom(backgroundColor: AppColor.lightSurface),
        ),
      ],
    );
  }

  Widget _buildTripSummary(ThemeData theme, BookingDetailEntity booking) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLG),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.lightBorder),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.location_on_rounded, 'Destination', booking.destinationCity),
          const Divider(height: AppTheme.spaceLG),
          _buildInfoRow(
            Icons.calendar_today_rounded, 
            'Date & Time', 
            DateFormat('MMM dd, yyyy - jm').format(booking.requestedDate)
          ),
          const Divider(height: AppTheme.spaceLG),
          _buildInfoRow(Icons.payments_rounded, 'Total Paid', '${booking.finalPrice ?? booking.estimatedPrice ?? 0} ${booking.currency ?? "USD"}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColor.lightTextSecondary),
        const SizedBox(width: AppTheme.spaceMD),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColor.lightTextSecondary, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingDetailEntity booking) {
    final bool canTrack = [BookingStatus.inProgress, BookingStatus.acceptedByHelper, BookingStatus.confirmedPaid].contains(booking.status);
    
    return Column(
      children: [
        if (canTrack)
          CustomButton(
            text: 'Track Helper',
            icon: Icons.map_rounded,
            onPressed: () => context.pushNamed('user-tracking', pathParameters: {'id': booking.id}),
          ),
        const SizedBox(height: AppTheme.spaceMD),
        if (booking.status == BookingStatus.completed)
          CustomButton(
            text: 'Rate Helper',
            variant: ButtonVariant.secondary,
            onPressed: () => context.pushNamed('helper-reviews', pathParameters: {'id': booking.id}),
          ),
      ],
    );
  }

  Widget _buildCancelOption(BuildContext context, BookingDetailEntity booking) {
    return Center(
      child: TextButton(
        onPressed: () => _showCancelDialog(context, booking.id),
        child: const Text('Cancel Booking', style: TextStyle(color: AppColor.errorColor)),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this trip? A cancellation fee may apply.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No, Keep It')),
          TextButton(
            onPressed: () {
              // Should use BookingCubit to cancel
              Navigator.pop(context);
              context.go(AppRouter.home);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColor.errorColor)),
          ),
        ],
      ),
    );
  }
}
