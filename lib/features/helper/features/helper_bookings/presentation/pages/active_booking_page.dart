import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../../../helper_chat/presentation/pages/helper_chat_page.dart';
import '../../../../../../core/theme/app_color.dart';

class ActiveBookingPage extends StatefulWidget {
  final String bookingId;
  const ActiveBookingPage({super.key, required this.bookingId});

  @override
  State<ActiveBookingPage> createState() => _ActiveBookingPageState();
}

class _ActiveBookingPageState extends State<ActiveBookingPage> {
  late final ActiveBookingCubit _activeCubit;
  late final StartTripCubit _startCubit;
  late final EndTripCubit _endCubit;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _activeCubit = sl<ActiveBookingCubit>();
    _startCubit  = sl<StartTripCubit>();
    _endCubit    = sl<EndTripCubit>();
    _activeCubit.load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5),
        (_) => _activeCubit.load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _activeCubit.close();
    _startCubit.close();
    _endCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _activeCubit),
        BlocProvider.value(value: _startCubit),
        BlocProvider.value(value: _endCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<StartTripCubit, StartTripState>(
            listener: (context, state) {
              if (state is StartTripSuccess) {
                _showSnack(context, '🚀 Trip started!');
                _activeCubit.load();
              } else if (state is StartTripError) {
                _showSnack(context, state.message, isError: true);
              }
            },
          ),
          BlocListener<EndTripCubit, EndTripState>(
            listener: (context, state) {
              if (state is EndTripSuccess) {
                _showEarningsDialog(context, state.earnings);
              } else if (state is EndTripError) {
                _showSnack(context, state.message, isError: true);
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          body: BlocBuilder<ActiveBookingCubit, ActiveBookingState>(
            builder: (context, state) {
              if (state is ActiveBookingLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
              }
              if (state is ActiveBookingLoaded && state.booking != null) {
                return _buildContent(context, state.booking!);
              }
              return _buildNoTrip(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HelperBooking booking) {
    final isStarted = booking.status == 'inProgress' || booking.status == 'started';
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: const Color(0xFF1A1F3C),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: _MapPlaceholder(
                  booking: booking,
                  isStarted: isStarted,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _RouteCard(booking: booking),
                  const SizedBox(height: 12),
                  _TripStatsRow(booking: booking),
                  const SizedBox(height: 12),
                  _ElapsedTimer(startTime: booking.startTime, isStarted: isStarted),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.info_outline_rounded,
                          color: Colors.white38, size: 16),
                      label: const Text('Full Booking Details',
                          style: TextStyle(color: Colors.white38, fontSize: 13)),
                      onPressed: () =>
                          context.push('/helper-booking-details/${booking.id}'),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        // Sticky CTA
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFF0A0E1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
            child: isStarted
                ? _EndTripButton(booking: booking)
                : _StartTripButton(booking: booking),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'track_live',
                onPressed: () => context.push(
                  '/helper-tracking/${booking.id}?pickupLat=${booking.pickupLat}&pickupLng=${booking.pickupLng}&destLat=${booking.destinationLat}&destLng=${booking.destinationLng}',
                ),
                backgroundColor: AppColor.primaryColor,
                icon: const Icon(Icons.map_outlined, color: Colors.white),
                label: const Text('Track Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'chat_traveler',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HelperChatPage(bookingId: booking.id),
                  ),
                ),
                backgroundColor: const Color(0xFF6C63FF),
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                label: const Text('Chat Traveler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoTrip(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF00C896), size: 60),
          ),
          const SizedBox(height: 24),
          const Text('No Active Trip',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("You don't have an active booking right now",
              style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Back to Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEarningsDialog(BuildContext context, double earnings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1F3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                    color: Color(0xFF00C896), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Trip Completed! 🎉',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('You earned',
                  style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 4),
              Text('\$${earnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 42,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Back to Dashboard',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? const Color(0xFFFF6B6B) : const Color(0xFF00C896),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}

// ── Map Placeholder ───────────────────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  final HelperBooking booking;
  final bool isStarted;
  const _MapPlaceholder({required this.booking, required this.isStarted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF2A2F5C), Color(0xFF0A0E1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Center(
              child: Icon(Icons.navigation_rounded,
                  color: Colors.white12, size: 100)),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFF0A0E1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isStarted
                    ? const Color(0xFF00C896)
                    : const Color(0xFFFFAB40),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isStarted ? '🟢  IN PROGRESS' : '🟡  CONFIRMED',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.travelerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.flag_rounded,
                      color: Colors.white60, size: 14),
                  const SizedBox(width: 4),
                  Text(booking.destinationLocation,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 13)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Route Card ────────────────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final HelperBooking booking;
  const _RouteCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _RItem(
              icon: Icons.radio_button_checked_rounded,
              label: 'Pickup',
              value: booking.pickupLocation,
              color: const Color(0xFF00C896)),
          Container(
              width: 2,
              height: 20,
              margin: const EdgeInsets.only(left: 11),
              color: Colors.white12),
          _RItem(
              icon: Icons.location_on_rounded,
              label: 'Drop-off',
              value: booking.destinationLocation,
              color: const Color(0xFFFF6B6B)),
        ],
      ),
    );
  }
}

class _RItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _RItem(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripStatsRow extends StatelessWidget {
  final HelperBooking booking;
  const _TripStatsRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
            label: 'Payout',
            value: '\$${booking.payout.toStringAsFixed(0)}',
            color: const Color(0xFF00C896)),
        const SizedBox(width: 10),
        _Chip(
            label: 'Language',
            value: booking.language ?? 'Any',
            color: const Color(0xFF6C63FF)),
        const SizedBox(width: 10),
        _Chip(
            label: 'Type',
            value: booking.isInstant ? 'Instant' : 'Scheduled',
            color: const Color(0xFFFFAB40)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ElapsedTimer extends StatefulWidget {
  final DateTime startTime;
  final bool isStarted;
  const _ElapsedTimer({required this.startTime, required this.isStarted});

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = widget.isStarted
        ? DateTime.now().difference(widget.startTime)
        : Duration.zero;
    if (widget.isStarted) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() =>
              _elapsed = DateTime.now().difference(widget.startTime));
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.isStarted) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isStarted) return const SizedBox.shrink();
    final h = _elapsed.inHours;
    final m = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_rounded,
              color: Color(0xFF6C63FF), size: 20),
          const SizedBox(width: 10),
          Text(
            h > 0 ? '$h:$m:$s elapsed' : '$m:$s elapsed',
            style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ── CTA Buttons ───────────────────────────────────────────────────────────────

class _StartTripButton extends StatelessWidget {
  final HelperBooking booking;
  const _StartTripButton({required this.booking});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartTripCubit, StartTripState>(
      builder: (context, state) => SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: Text(
            state is StartTripLoading ? 'Starting...' : 'Start Trip',
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          onPressed: state is StartTripLoading
              ? null
              : () => context.read<StartTripCubit>().start(booking.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C896),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
    );
  }
}

class _EndTripButton extends StatelessWidget {
  final HelperBooking booking;
  const _EndTripButton({required this.booking});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EndTripCubit, EndTripState>(
      builder: (context, state) => SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.stop_circle_rounded, size: 22),
          label: Text(
            state is EndTripLoading ? 'Ending Trip...' : 'End Trip',
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          onPressed: state is EndTripLoading
              ? null
              : () => _confirmEnd(context, booking.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
    );
  }

  void _confirmEnd(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('End Trip?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Mark this trip as completed?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<EndTripCubit>().end(bookingId);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );
  }
}
