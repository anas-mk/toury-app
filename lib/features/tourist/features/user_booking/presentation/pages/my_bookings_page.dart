import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/my_bookings_cubit.dart';
import '../cubits/my_bookings_state.dart';
import '../../../../../../core/di/injection_container.dart';
import 'scheduled_trip_details_page.dart';

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
            if (state is MyBookingsLoaded) {
              if (state.bookings.isEmpty) {
                return _buildEmptyState(loc);
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
            if (state is MyBookingsError) {
              return Center(child: Text(state.message));
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
      onTap: () {
        if (booking.type == BookingType.scheduled) {
          final trip = ScheduledTripEntity(
            helperId: booking.helper?.id ?? '',
            destinationCity: booking.destinationCity,
            requestedDate: booking.requestedDate,
            startTime: booking.startTime ?? '09:00',
            durationInMinutes: booking.durationInMinutes,
            requestedLanguage: 'English',
            requiresCar: false,
            travelersCount: 1,
            meetingPointType: 'Standard Pickup',
            pickupLocationName: booking.pickupLocationName ?? booking.destinationCity,
            pickupLatitude: booking.pickupLatitude ?? 0.0,
            pickupLongitude: booking.pickupLongitude ?? 0.0,
            notes: booking.notes,
          );
          context.pushNamed('scheduled-trip-details', extra: {'trip': trip});
        } else {
          context.pushNamed(
            'booking-details',
            pathParameters: {'id': booking.id},
            extra: {'booking': booking},
          );
        }
      },
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
                  Text(
                    'Trip to ${booking.destinationCity}',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${booking.helper?.name ?? "Helper"} • ${booking.finalPrice ?? booking.estimatedPrice ?? 0} ${booking.currency ?? "USD"}',
                    style: theme.textTheme.bodySmall,
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

  Widget _buildEmptyState(AppLocalizations loc) {
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
        ],
      ),
    );
  }
}
