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
import '../cubits/cancel_booking_cubit.dart';

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
  final TextEditingController _cancelReasonController = TextEditingController();

  @override
  void dispose() {
    _cancelReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<BookingStatusCubit>()..refreshActiveBooking(widget.bookingId),
        ),
        BlocProvider(create: (_) => sl<CancelBookingCubit>()),
      ],
      child: BlocListener<CancelBookingCubit, CancelBookingState>(
        listener: (context, state) {
          if (state is CancelBookingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking cancelled successfully.')),
            );
            context.go(AppRouter.home);
          } else if (state is CancelBookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColor.errorColor),
            );
          }
        },
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
                if (state is BookingStatusError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColor.errorColor),
                        const SizedBox(height: AppTheme.spaceMD),
                        Text(state.message),
                        const SizedBox(height: AppTheme.spaceMD),
                        CustomButton(
                          text: 'Retry',
                          onPressed: () => context.read<BookingStatusCubit>().refreshActiveBooking(widget.bookingId),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: Text('Booking not found'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBanner(booking),
                    const SizedBox(height: AppTheme.spaceXL),

                    _buildHelperInfo(theme, context, booking),
                    const SizedBox(height: AppTheme.spaceXL),

                    _buildTripSummary(theme, booking),
                    const SizedBox(height: AppTheme.spaceXL),

                    _buildActionButtons(context, booking),
                    const SizedBox(height: AppTheme.space2XL),

                    if (booking.canCancel)
                      _buildCancelOption(context, booking),
                  ],
                ),
              );
            },
          ),
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
            _formatStatus(booking.status),
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  String _formatStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingHelperResponse: return 'Pending Helper Response';
      case BookingStatus.acceptedByHelper: return 'Accepted by Helper';
      case BookingStatus.confirmedAwaitingPayment: return 'Awaiting Payment';
      case BookingStatus.confirmedPaid: return 'Confirmed & Paid';
      case BookingStatus.upcoming: return 'Upcoming';
      case BookingStatus.inProgress: return 'In Progress';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.declinedByHelper: return 'Declined by Helper';
      case BookingStatus.expiredNoResponse: return 'No Response — Expired';
      case BookingStatus.reassignmentInProgress: return 'Finding New Helper';
      case BookingStatus.waitingForUserAction: return 'Action Required';
      case BookingStatus.cancelledByUser: return 'Cancelled by You';
      case BookingStatus.cancelledByHelper: return 'Cancelled by Helper';
      case BookingStatus.cancelledBySystem: return 'Cancelled by System';
    }
  }

  Widget _buildHelperInfo(ThemeData theme, BuildContext context, BookingDetailEntity booking) {
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
              if (booking.helper?.rating != null)
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${booking.helper!.rating}', style: theme.textTheme.bodySmall),
                    Text(' • ${booking.helper!.completedTrips} trips', style: theme.textTheme.bodySmall),
                  ],
                ),
            ],
          ),
        ),
        // Chat button only shown when chat is enabled by backend
        if (booking.chatEnabled)
          IconButton(
            onPressed: () => context.pushNamed(
              'user-chat',
              pathParameters: {'id': booking.id},
            ),
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
            DateFormat('MMM dd, yyyy').format(booking.requestedDate) +
                (booking.startTime != null ? ' at ${booking.startTime}' : ''),
          ),
          const Divider(height: AppTheme.spaceLG),
          _buildInfoRow(
            Icons.payments_rounded,
            'Price',
            '${(booking.finalPrice ?? booking.estimatedPrice ?? 0).toStringAsFixed(2)} ${booking.currency ?? "EGP"}',
          ),
          if (booking.paymentStatus != null) ...[
            const Divider(height: AppTheme.spaceLG),
            _buildInfoRow(Icons.receipt_long_rounded, 'Payment', booking.paymentStatus!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColor.lightTextSecondary),
        const SizedBox(width: AppTheme.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColor.lightTextSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingDetailEntity booking) {
    final canTrack = [
      BookingStatus.inProgress,
      BookingStatus.acceptedByHelper,
      BookingStatus.confirmedPaid,
    ].contains(booking.status);

    return Column(
      children: [
        if (canTrack)
          CustomButton(
            text: 'Track Helper',
            icon: Icons.map_rounded,
            onPressed: () => context.pushNamed(
              'user-tracking',
              pathParameters: {'id': booking.id},
            ),
          ),
        if (booking.status == BookingStatus.completed) ...[
          const SizedBox(height: AppTheme.spaceMD),
          CustomButton(
            text: 'Rate Helper',
            variant: ButtonVariant.secondary,
            onPressed: () => context.pushNamed('rate-booking', pathParameters: {'bookingId': booking.id}),
          ),
        ],
        if ([
          BookingStatus.declinedByHelper,
          BookingStatus.expiredNoResponse,
          BookingStatus.reassignmentInProgress,
        ].contains(booking.status)) ...[
          const SizedBox(height: AppTheme.spaceMD),
          CustomButton(
            text: 'View Alternatives',
            variant: ButtonVariant.secondary,
            onPressed: () => context.pushNamed(
              'reassignment',
              pathParameters: {'id': booking.id},
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCancelOption(BuildContext context, BookingDetailEntity booking) {
    return BlocBuilder<CancelBookingCubit, CancelBookingState>(
      builder: (context, state) {
        return Center(
          child: TextButton(
            onPressed: state is CancelBookingLoading ? null : () => _showCancelDialog(context, booking.id),
            child: state is CancelBookingLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.errorColor),
                  )
                : const Text('Cancel Booking', style: TextStyle(color: AppColor.errorColor)),
          ),
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    _cancelReasonController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for cancellation (required):'),
            const SizedBox(height: AppTheme.spaceMD),
            TextField(
              controller: _cancelReasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Plans changed...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Keep Booking')),
          TextButton(
            onPressed: () {
              final reason = _cancelReasonController.text.trim();
              if (reason.length < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason (min 5 characters).')),
                );
                return;
              }
              Navigator.pop(dialogContext);
              context.read<CancelBookingCubit>().cancel(bookingId, reason);
            },
            child: const Text('Confirm Cancel', style: TextStyle(color: AppColor.errorColor)),
          ),
        ],
      ),
    );
  }
}
