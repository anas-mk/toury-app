import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';


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
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1120),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('Upcoming Trips',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: BlocBuilder<UpcomingBookingsCubit, UpcomingBookingsState>(
          builder: (context, state) {
            if (state is UpcomingBookingsLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }
            if (state is UpcomingBookingsError) {
              return _buildError(state.message);
            }
            if (state is UpcomingBookingsLoaded) {
              if (state.bookings.isEmpty) return _buildEmpty();
              return RefreshIndicator(
                onRefresh: () async => _cubit.load(),
                color: const Color(0xFF6C63FF),
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
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.wifi_off_rounded, color: Color(0xFFFF6B6B), size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Failed to load trips',
                style: TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg,
                style: const TextStyle(color: Colors.white38),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => _cubit.load(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            const Color(0xFF6C63FF).withOpacity(0.15),
                        child: Text(
                          booking.travelerName.isNotEmpty
                              ? booking.travelerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(booking.travelerName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            Text(_fmtDate(booking.startTime),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C896).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF00C896)
                                  .withOpacity(0.3)),
                        ),
                        child: Text(
                          '\$${booking.payout.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Color(0xFF00C896),
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Loc(
                      icon: Icons.location_on_rounded,
                      label: 'From',
                      value: booking.pickupLocation,
                      color: const Color(0xFF00C896)),
                  const SizedBox(height: 8),
                  _Loc(
                      icon: Icons.flag_rounded,
                      label: 'To',
                      value: booking.destinationLocation,
                      color: const Color(0xFFFF6B6B)),
                ],
              ),
            ),
            if (isStartable)
              Container(
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white12))),
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
  late final StartTripCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<StartTripCubit>();
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
      child: BlocListener<StartTripCubit, StartTripState>(
        listener: (context, state) {
          if (state is StartTripSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip started!'),
                backgroundColor: Color(0xFF00C896),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.push('/helper/active-booking', extra: widget.bookingId);
          } else if (state is StartTripError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFFF6B6B),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: BlocBuilder<StartTripCubit, StartTripState>(
          builder: (context, state) {
            final loading = state is StartTripLoading;
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
