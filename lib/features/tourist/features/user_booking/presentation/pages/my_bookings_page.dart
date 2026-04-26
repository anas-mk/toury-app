import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/my_bookings_cubit.dart';
import '../cubits/my_bookings_state.dart';
import '../../../../../../core/di/injection_container.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return BlocProvider(
      create: (_) => sl<MyBookingsCubit>()..getBookings(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('trips')),
        ),
        body: BlocBuilder<MyBookingsCubit, MyBookingsState>(
          builder: (context, state) {
            if (state is MyBookingsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MyBookingsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColor.errorColor),
                    const SizedBox(height: AppTheme.spaceMD),
                    Text(state.message),
                    const SizedBox(height: AppTheme.spaceMD),
                    ElevatedButton(
                      onPressed: () => context.read<MyBookingsCubit>().refreshBookings(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is MyBookingsLoaded) {
              if (state.bookings.isEmpty) {
                return _buildEmptyState(context, loc);
              }
              return RefreshIndicator(
                onRefresh: () => context.read<MyBookingsCubit>().refreshBookings(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spaceLG),
                  itemCount: state.bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceMD),
                  itemBuilder: (context, index) {
                    return _buildBookingItem(context, state.bookings[index]);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBookingItem(BuildContext context, BookingDetailEntity booking) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      // All booking types navigate to unified BookingDetailsPage
      onTap: () => context.pushNamed(
        'booking-details',
        pathParameters: {'id': booking.id},
        extra: {'booking': booking},
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(color: AppColor.lightBorder),
        ),
        child: Row(
          children: [
            _buildStatusIcon(booking.status),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Trip to ${booking.destinationCity}',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildTypeBadge(booking.type),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.helper?.name ?? "Helper"} • ${(booking.finalPrice ?? booking.estimatedPrice ?? 0).toStringAsFixed(0)} ${booking.currency ?? "EGP"}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM dd, yyyy').format(booking.requestedDate),
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColor.lightTextSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColor.lightTextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BookingType type) {
    final isScheduled = type == BookingType.scheduled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isScheduled ? AppColor.primaryColor : AppColor.accentColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isScheduled ? 'Scheduled' : 'Instant',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isScheduled ? AppColor.primaryColor : AppColor.accentColor,
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BookingStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case BookingStatus.completed:
        color = AppColor.accentColor;
        icon = Icons.check_circle_rounded;
        break;
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
        color = AppColor.errorColor;
        icon = Icons.cancel_rounded;
        break;
      case BookingStatus.inProgress:
        color = AppColor.secondaryColor;
        icon = Icons.directions_walk_rounded;
        break;
      case BookingStatus.confirmedPaid:
        color = Colors.green;
        icon = Icons.verified_rounded;
        break;
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
        color = AppColor.warningColor;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = AppColor.warningColor;
        icon = Icons.pending_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_rounded, size: 64, color: AppColor.lightBorder),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            loc.translate('no_bookings_yet'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Your trips will appear here once you book.'),
          const SizedBox(height: AppTheme.spaceLG),
          ElevatedButton.icon(
            onPressed: () => context.go('/booking-home'),
            icon: const Icon(Icons.add),
            label: const Text('Book a Trip'),
          ),
        ],
      ),
    );
  }
}
