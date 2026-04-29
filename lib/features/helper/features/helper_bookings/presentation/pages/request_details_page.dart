import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';

class RequestDetailsPage extends StatefulWidget {
  final String bookingId;
  const RequestDetailsPage({super.key, required this.bookingId});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  late final RequestDetailsCubit _detailsCubit;
  late final AcceptBookingCubit _acceptCubit;
  late final DeclineBookingCubit _declineCubit;

  @override
  void initState() {
    super.initState();
    _detailsCubit = sl<RequestDetailsCubit>();
    _acceptCubit  = sl<AcceptBookingCubit>();
    _declineCubit = sl<DeclineBookingCubit>();
    _detailsCubit.load(widget.bookingId);
  }

  @override
  void dispose() {
    _detailsCubit.close();
    _acceptCubit.close();
    _declineCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _detailsCubit),
        BlocProvider.value(value: _acceptCubit),
        BlocProvider.value(value: _declineCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AcceptBookingCubit, AcceptBookingState>(
            listener: (context, state) {
              if (state is AcceptBookingSuccess) {
                _showSnack(context, '✓ Request accepted!');
                context.go('/helper/booking-details/${state.booking.id}');
              } else if (state is AcceptBookingError) {
                _showSnack(context, state.message, isError: true);
              }
            },
          ),
          BlocListener<DeclineBookingCubit, DeclineBookingState>(
            listener: (context, state) {
              if (state is DeclineBookingSuccess) {
                context.pop();
                _showSnack(context, 'Request declined');
              } else if (state is DeclineBookingError) {
                _showSnack(context, state.message, isError: true);
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: BrandTokens.bgSoft,
          body: BlocBuilder<RequestDetailsCubit, RequestDetailsState>(
            builder: (context, state) {
              if (state is RequestDetailsLoading) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              }
              if (state is RequestDetailsLoaded) {
                return _buildContent(context, state.booking);
              }
              if (state is RequestDetailsError) {
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
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildSliverAppBar(booking),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  _CountdownBar(deadline: booking.responseDeadline),
                  const SizedBox(height: 16),
                  _TravelerCard(booking: booking),
                  const SizedBox(height: 12),
                  _TripInfoCard(booking: booking),
                  if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _NotesCard(notes: booking.notes!),
                  ],
                ]),
              ),
            ),
          ],
        ),
        // Sticky Bottom CTA
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BrandTokens.bgSoft.withValues(alpha: 0), BrandTokens.bgSoft],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Row(
              children: [
                Expanded(
                  child: BlocBuilder<AcceptBookingCubit, AcceptBookingState>(
                    builder: (context, state) {
                      final loading = state is AcceptBookingLoading;
                      return SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () => context
                                  .read<AcceptBookingCubit>()
                                  .accept(booking.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandTokens.successGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator.adaptive(
                                      backgroundColor: Colors.white))
                              : Text('✓  Accept',
                                  style: BrandTypography.body(weight: FontWeight.bold, color: Colors.white)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                BlocBuilder<DeclineBookingCubit, DeclineBookingState>(
                  builder: (context, state) {
                    final loading = state is DeclineBookingLoading;
                    return SizedBox(
                      height: 54,
                      width: 120,
                      child: OutlinedButton(
                        onPressed: loading
                            ? null
                            : () => _showDecline(context, booking.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BrandTokens.dangerRed,
                          side: const BorderSide(color: BrandTokens.dangerRed),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator.adaptive())
                            : Text('Decline',
                                style: BrandTypography.body(weight: FontWeight.bold, color: BrandTokens.dangerRed)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(HelperBooking booking) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: const Color(0xFF1A1F3C),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A2F5C), Color(0xFF1A1F3C), Color(0xFF0A0E1A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              const Center(child: Icon(Icons.map_rounded, color: Colors.white12, size: 80)),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, BrandTokens.bgSoft],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RoutePoint(
                              label: 'Pickup',
                              value: booking.pickupLocation,
                              color: const Color(0xFF00C896)),
                          const SizedBox(height: 10),
                          _RoutePoint(
                              label: 'Drop-off',
                              value: booking.destinationLocation,
                              color: const Color(0xFFFF6B6B)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: BrandTokens.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: BrandTokens.successGreen.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '\$${booking.payout.toStringAsFixed(0)}',
                            style: BrandTypography.headline(color: BrandTokens.successGreen),
                          ),
                          Text('payout',
                              style: BrandTypography.overline(color: BrandTokens.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: BrandTokens.dangerRed, size: 48),
          const SizedBox(height: 16),
          Text(msg, style: BrandTypography.body()),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _detailsCubit.load(widget.bookingId),
            style: ElevatedButton.styleFrom(backgroundColor: BrandTokens.primaryBlue),
            child: Text('Retry', style: BrandTypography.body(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDecline(BuildContext context, String bookingId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F3C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => BlocProvider.value(
        value: context.read<DeclineBookingCubit>(),
        child: _DeclineReasonSheet(bookingId: bookingId),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? BrandTokens.dangerRed : BrandTokens.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}

// ── Countdown Bar ────────────────────────────────────────────────────────────

class _CountdownBar extends StatefulWidget {
  final DateTime deadline;
  const _CountdownBar({required this.deadline});

  @override
  State<_CountdownBar> createState() => _CountdownBarState();
}

class _CountdownBarState extends State<_CountdownBar> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.deadline.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _remaining = widget.deadline.difference(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining.isNegative;
    final urgent = !expired && _remaining.inSeconds < 60;
    final c = expired
        ? BrandTokens.textMuted
        : urgent
            ? BrandTokens.dangerRed
            : BrandTokens.primaryBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: c, size: 18),
          const SizedBox(width: 10),
          Text(
            expired
                ? 'Response time expired'
                : 'Respond within: ${_fmt(_remaining)}',
            style: BrandTypography.body(color: c, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Sub-Cards ─────────────────────────────────────────────────────────────────

class _TravelerCard extends StatelessWidget {
  final HelperBooking booking;
  const _TravelerCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: BrandTokens.primaryBlue.withValues(alpha: 0.1),
            child: Text(
              booking.travelerName.isNotEmpty
                  ? booking.travelerName[0].toUpperCase()
                  : '?',
              style: BrandTypography.headline(color: BrandTokens.primaryBlue),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.travelerName,
                    style: BrandTypography.body(weight: FontWeight.bold)),
                if (booking.language != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('🌐 ${booking.language}',
                        style: BrandTypography.caption()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripInfoCard extends StatelessWidget {
  final HelperBooking booking;
  const _TripInfoCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trip Details',
              style: BrandTypography.body(weight: FontWeight.bold)),
          const SizedBox(height: 14),
          _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Start Time',
              value: _fmtDate(booking.startTime)),
          const SizedBox(height: 10),
          _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'Pickup',
              value: booking.pickupLocation),
          const SizedBox(height: 10),
          _InfoRow(
              icon: Icons.flag_rounded,
              label: 'Destination',
              value: booking.destinationLocation),
          const SizedBox(height: 10),
          _InfoRow(
              icon: Icons.payments_rounded,
              label: 'Payout',
              value: '\$${booking.payout.toStringAsFixed(2)}',
              highlight: true),
          const SizedBox(height: 10),
          _InfoRow(
              icon: booking.isInstant
                  ? Icons.flash_on_rounded
                  : Icons.schedule_rounded,
              label: 'Type',
              value: booking.isInstant ? 'Instant Booking' : 'Scheduled'),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool highlight;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: BrandTokens.textMuted, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: BrandTypography.overline()),
              const SizedBox(height: 2),
              Text(value,
                  style: BrandTypography.body(
                      color: highlight
                          ? BrandTokens.successGreen
                          : BrandTokens.textPrimary,
                      weight: highlight ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.accentAmberSoft,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: BrandTokens.accentAmberBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_rounded,
              color: BrandTokens.accentAmberText, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Traveler Notes',
                    style: BrandTypography.body(
                        color: BrandTokens.accentAmberText, weight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(notes,
                    style: BrandTypography.caption(color: BrandTokens.accentAmberText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final String label, value;
  final Color color;
  const _RoutePoint(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: BrandTypography.overline(color: color)),
              Text(value,
                  style: BrandTypography.body(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeclineReasonSheet extends StatefulWidget {
  final String bookingId;
  const _DeclineReasonSheet({required this.bookingId});

  @override
  State<_DeclineReasonSheet> createState() => _DeclineReasonSheetState();
}

class _DeclineReasonSheetState extends State<_DeclineReasonSheet> {
  String? _selected;
  static const _reasons = [
    'Too far away',
    'Already booked',
    'Not available right now',
    'Emergency situation',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeclineBookingCubit, DeclineBookingState>(
      listener: (context, state) {
        if (state is DeclineBookingSuccess) Navigator.pop(context);
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Reason for Declining',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._reasons.map((r) => InkWell(
                    onTap: () => setState(() => _selected = r),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _selected == r
                            ? BrandTokens.dangerRed.withValues(alpha: 0.08)
                            : BrandTokens.borderSoft.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _selected == r
                                ? BrandTokens.dangerRed.withValues(alpha: 0.4)
                                : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selected == r
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _selected == r
                                ? BrandTokens.dangerRed
                                : BrandTokens.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(r,
                              style: BrandTypography.body(
                                  color: _selected == r
                                      ? BrandTokens.textPrimary
                                      : BrandTokens.textSecondary,
                                  weight: _selected == r ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
              BlocBuilder<DeclineBookingCubit, DeclineBookingState>(
                builder: (context, state) {
                  final loading = state is DeclineBookingLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () => context
                              .read<DeclineBookingCubit>()
                              .decline(widget.bookingId, reason: _selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandTokens.dangerRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator.adaptive(
                                  backgroundColor: Colors.white))
                          : Text('Confirm Decline',
                              style: BrandTypography.body(weight: FontWeight.bold, color: Colors.white)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
