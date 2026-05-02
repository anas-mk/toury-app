import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../cubit/trip_action_cubit.dart';


class UpcomingBookingsPage extends StatefulWidget {
  const UpcomingBookingsPage({super.key});

  @override
  State<UpcomingBookingsPage> createState() => _UpcomingBookingsPageState();
}

class _UpcomingBookingsPageState extends State<UpcomingBookingsPage> {
  late final UpcomingBookingsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<UpcomingBookingsCubit>();
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        appBar: AppBar(
          backgroundColor: BrandTokens.surfaceWhite,
          foregroundColor: BrandTokens.textPrimary,
          elevation: 0,
          title: Text('Upcoming Trips',
              style: BrandTypography.title()),
        ),
        body: BlocBuilder<UpcomingBookingsCubit, UpcomingBookingsState>(
          builder: (context, state) {
            if (state is UpcomingBookingsLoading) {
              return const Center(
                  child: CircularProgressIndicator.adaptive());
            }
            if (state is UpcomingBookingsError) {
              return _buildError(state.message);
            }
            if (state is UpcomingBookingsLoaded) {
              if (state.bookings.isEmpty) return _buildEmpty();
              return RefreshIndicator.adaptive(
                onRefresh: () async => _cubit.load(),
                color: BrandTokens.primaryBlue,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: state.bookings.length,
                  itemBuilder: (context, i) =>
                      _UpcomingCard(booking: state.bookings[i]),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, color: Colors.white24, size: 64),
          SizedBox(height: 16),
          Text('No upcoming trips',
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Text('Accepted bookings will appear here',
              style: TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BrandTokens.dangerRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.wifi_off_rounded, color: BrandTokens.dangerRed, size: 44),
            ),
            const SizedBox(height: 20),
            Text('Failed to load trips',
                style: BrandTypography.title()),
            const SizedBox(height: 8),
            Text(msg,
                style: BrandTypography.caption(),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => _cubit.load(),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandTokens.primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final HelperBooking booking;
  const _UpcomingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final isStartable =
        booking.status == 'confirmed' || booking.status == 'accepted';

    return GestureDetector(
      onTap: () => context.push('/helper/booking-details/${booking.id}'),
      child: CustomCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: BrandTokens.primaryBlue.withValues(alpha: 0.1),
                        child: Text(
                          booking.travelerName.isNotEmpty
                              ? booking.travelerName[0].toUpperCase()
                              : '?',
                          style: BrandTypography.body(
                              color: BrandTokens.primaryBlue,
                              weight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(booking.travelerName,
                                style: BrandTypography.body(weight: FontWeight.bold)),
                            Text(_fmtDate(booking.startTime),
                                style: BrandTypography.caption()),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: BrandTokens.successGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '\$${booking.payout.toStringAsFixed(0)}',
                          style: BrandTypography.caption(
                              color: BrandTokens.successGreen,
                              weight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Loc(
                      icon: Icons.location_on_rounded,
                      label: 'From',
                      value: booking.pickupLocation,
                      color: BrandTokens.successGreen),
                  const SizedBox(height: 8),
                  _Loc(
                      icon: Icons.flag_rounded,
                      label: 'To',
                      value: booking.destinationLocation,
                      color: BrandTokens.dangerRed),
                ],
              ),
            ),
            if (isStartable)
              Container(
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: BrandTokens.borderSoft.withValues(alpha: 0.5)))),
                child: _InlineStartButton(bookingId: booking.id),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}  ·  '
        '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _Loc extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _Loc(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _InlineStartButton extends StatefulWidget {
  final String bookingId;
  const _InlineStartButton({required this.bookingId});

  @override
  State<_InlineStartButton> createState() => _InlineStartButtonState();
}

class _InlineStartButtonState extends State<_InlineStartButton> {
  late final TripActionCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<TripActionCubit>();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<TripActionCubit, TripActionState>(
        listener: (context, state) {
          if (state is TripActionSuccess && state.actionType == 'start') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip started!'),
                backgroundColor: Color(0xFF00C896),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.push('/helper/active-booking', extra: widget.bookingId);
          } else if (state is TripActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFFF6B6B),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<TripActionCubit, TripActionState>(
          builder: (context, state) {
            final loading = state is TripActionInProgress && state.actionType == 'start';
            return TextButton.icon(
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF), strokeWidth: 2))
                  : const Icon(Icons.play_arrow_rounded,
                      color: Color(0xFF6C63FF), size: 18),
              label: Text(
                loading ? 'Starting...' : '▶  Start Trip',
                style: const TextStyle(
                    color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
              ),
              onPressed:
                  loading ? null : () => _cubit.start(widget.bookingId),
            );
          },
        ),
      ),
    );
  }
}
