import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../../../helper_ratings/presentation/widgets/booking_rating_sheet.dart';
import '../../../helper_chat/presentation/pages/helper_chat_page.dart';

class HelperBookingDetailsPage extends StatefulWidget {
  final String bookingId;
  const HelperBookingDetailsPage({super.key, required this.bookingId});

  @override
  State<HelperBookingDetailsPage> createState() => _HelperBookingDetailsPageState();
}

class _HelperBookingDetailsPageState extends State<HelperBookingDetailsPage> {
  late final HelperBookingDetailsCubit _detailsCubit;
  late final StartTripCubit _startCubit;
  late final EndTripCubit _endCubit;

  @override
  void initState() {
    super.initState();
    _detailsCubit = sl<HelperBookingDetailsCubit>();
    _startCubit   = sl<StartTripCubit>();
    _endCubit     = sl<EndTripCubit>();
    _detailsCubit.load(widget.bookingId);
  }

  @override
  void dispose() {
    _detailsCubit.close();
    _startCubit.close();
    _endCubit.close();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _detailsCubit),
        BlocProvider.value(value: _startCubit),
        BlocProvider.value(value: _endCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<StartTripCubit, StartTripState>(
            listener: (context, state) {
              if (state is StartTripSuccess) {
                _showSnack(context, 'Trip started!');
                _detailsCubit.load(widget.bookingId);
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
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D1120),
            foregroundColor: Colors.white,
            title: const Text('Booking Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            elevation: 0,
          ),
          body: BlocBuilder<HelperBookingDetailsCubit, HelperBookingDetailsState>(
            builder: (context, state) {
              if (state is HelperBookingDetailsLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
              }
              if (state is HelperBookingDetailsLoaded) {
                return _buildContent(context, state.booking);
              }
              if (state is HelperBookingDetailsError) {
                return _buildError(context, state.message);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HelperBooking booking) {
    final isActive = booking.status == 'inProgress' || booking.status == 'started';
    final isConfirmed = booking.status == 'confirmed' || booking.status == 'accepted';
    final isCompleted = booking.status == 'completed';

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            _StatusBanner(status: booking.status),
            const SizedBox(height: 14),
            _TravelerSection(booking: booking),
            const SizedBox(height: 12),
            _RouteInfoCard(booking: booking),
            const SizedBox(height: 12),
            _PaymentCard(booking: booking),
            const SizedBox(height: 12),
            _Timeline(booking: booking),
            const SizedBox(height: 8),
          ],
        ),
        // Sticky bottom
        if (isConfirmed || isActive || isCompleted)
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    _StickyButton(
                      label: 'Open Trip View',
                      icon: Icons.navigation_rounded,
                      color: const Color(0xFF6C63FF),
                      onTap: () => context.push(
                        '/helper/active-booking',
                        extra: booking.id,
                      ),
                      outline: true,
                    ),
                  if (isActive) const SizedBox(height: 10),
                  if (isConfirmed)
                    BlocBuilder<StartTripCubit, StartTripState>(
                      builder: (context, state) => _StickyButton(
                        label: state is StartTripLoading
                            ? 'Starting...'
                            : 'Start Trip',
                        icon: Icons.play_arrow_rounded,
                        color: const Color(0xFF00C896),
                        onTap: state is StartTripLoading
                            ? null
                            : () => context
                                .read<StartTripCubit>()
                                .start(booking.id),
                      ),
                    ),
                  if (isActive)
                    BlocBuilder<EndTripCubit, EndTripState>(
                      builder: (context, state) => _StickyButton(
                        label: state is EndTripLoading
                            ? 'Ending...'
                            : 'End Trip',
                        icon: Icons.stop_circle_rounded,
                        color: const Color(0xFFFF6B6B),
                        onTap: state is EndTripLoading
                            ? null
                            : () => _confirmEnd(context, booking.id),
                      ),
                    ),
                  if (isCompleted)
                    _StickyButton(
                      label: 'Rate Traveler',
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => BookingRatingSheet(
                          bookingId: booking.id,
                          travelerName: booking.travelerName,
                          travelerAvatar: '', // Add if available in entity
                        ),
                      ),
                    ),
                  if (isConfirmed || isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _StickyButton(
                        label: 'Open Chat',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFF6C63FF),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HelperChatPage(bookingId: booking.id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 48),
            const SizedBox(height: 16),
            Text(msg, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => _detailsCubit.load(widget.bookingId),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmEnd(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3C),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

  void _showEarningsDialog(BuildContext context, double earnings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1F3C),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF00C896), size: 60),
              const SizedBox(height: 16),
              const Text('Trip Completed! 🎉',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('\$${earnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 36,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
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
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-Widgets ────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _info(status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }

  (Color, String, IconData) _info(String s) {
    switch (s.toLowerCase()) {
      case 'pending':   return (const Color(0xFFFFAB40), 'Pending Confirmation', Icons.hourglass_empty_rounded);
      case 'confirmed':
      case 'accepted':  return (const Color(0xFF6C63FF), 'Confirmed', Icons.check_circle_outline_rounded);
      case 'inprogress':
      case 'started':   return (const Color(0xFF00C896), 'In Progress', Icons.navigation_rounded);
      case 'completed': return (Colors.white54, 'Completed', Icons.done_all_rounded);
      case 'cancelled': return (const Color(0xFFFF6B6B), 'Cancelled', Icons.cancel_outlined);
      default:          return (Colors.white38, s, Icons.info_outline_rounded);
    }
  }
}

class _TravelerSection extends StatelessWidget {
  final HelperBooking booking;
  const _TravelerSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
            child: Text(
              booking.travelerName.isNotEmpty
                  ? booking.travelerName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.travelerName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                if (booking.language != null)
                  Text('🌐 ${booking.language}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteInfoCard extends StatelessWidget {
  final HelperBooking booking;
  const _RouteInfoCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Route',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 14),
          _RowItem(
              label: 'Pickup',
              value: booking.pickupLocation,
              color: const Color(0xFF00C896)),
          const SizedBox(height: 10),
          _RowItem(
              label: 'Destination',
              value: booking.destinationLocation,
              color: const Color(0xFFFF6B6B)),
          const SizedBox(height: 10),
          _RowItem(
              label: 'Start',
              value: _fmt(booking.startTime),
              color: const Color(0xFF6C63FF)),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _RowItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RowItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final HelperBooking booking;
  const _PaymentCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2A1A), Color(0xFF1A1F3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFF00C896).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00C896).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_rounded,
                color: Color(0xFF00C896), size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Payout',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text('\$${booking.payout.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final HelperBooking booking;
  const _Timeline({required this.booking});

  @override
  Widget build(BuildContext context) {
    final completed = booking.status == 'completed';
    final started = completed ||
        booking.status == 'inProgress' ||
        booking.status == 'started';
    final confirmed = started ||
        booking.status == 'confirmed' ||
        booking.status == 'accepted';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1F3C),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timeline',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(height: 14),
          _TItem(label: 'Booking Created', done: true, isLast: false),
          _TItem(label: 'Confirmed', done: confirmed, isLast: false),
          _TItem(label: 'Trip Started', done: started, isLast: false),
          _TItem(label: 'Completed', done: completed, isLast: true),
        ],
      ),
    );
  }
}

class _TItem extends StatelessWidget {
  final String label;
  final bool done, isLast;
  const _TItem({required this.label, required this.done, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: done ? const Color(0xFF00C896) : Colors.white12,
                shape: BoxShape.circle,
                border: Border.all(
                    color: done
                        ? const Color(0xFF00C896)
                        : Colors.white24,
                    width: 1.5),
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 9)
                  : null,
            ),
            if (!isLast)
              Container(
                  width: 2,
                  height: 28,
                  color: done
                      ? const Color(0xFF00C896).withOpacity(0.3)
                      : Colors.white12),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: done ? Colors.white : Colors.white38,
                      fontWeight:
                          done ? FontWeight.w500 : FontWeight.normal,
                      fontSize: 13)),
              SizedBox(height: isLast ? 0 : 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _StickyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool outline;
  const _StickyButton(
      {required this.label,
      required this.icon,
      required this.color,
      this.onTap,
      this.outline = false});

  @override
  Widget build(BuildContext context) {
    if (outline) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          icon: Icon(icon, color: color, size: 18),
          label: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
