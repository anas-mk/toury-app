import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';

class IncomingRequestsPage extends StatefulWidget {
  const IncomingRequestsPage({super.key});

  @override
  State<IncomingRequestsPage> createState() => _IncomingRequestsPageState();
}

class _IncomingRequestsPageState extends State<IncomingRequestsPage>
    with SingleTickerProviderStateMixin {
  late final IncomingRequestsCubit _cubit;
  late TabController _tabController;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _cubit = sl<IncomingRequestsCubit>();
    _tabController = TabController(length: 2, vsync: this);
    _cubit.load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _cubit.load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
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
          title: const Text('Incoming Requests',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            BlocBuilder<IncomingRequestsCubit, IncomingRequestsState>(
              buildWhen: (p, c) => c is IncomingRequestsLoaded,
              builder: (context, state) {
                if (state is! IncomingRequestsLoaded) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFAB40).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFAB40).withOpacity(0.3)),
                  ),
                  child: Text(
                    '${state.requests.length}',
                    style: const TextStyle(
                        color: Color(0xFFFFAB40), fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF6C63FF),
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: '⚡  Instant'),
              Tab(text: '📅  Scheduled'),
            ],
          ),
        ),
        body: BlocBuilder<IncomingRequestsCubit, IncomingRequestsState>(
          builder: (context, state) {
            if (state is IncomingRequestsLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
            }
            if (state is IncomingRequestsError) {
              return _buildError(context, state.message);
            }
            if (state is IncomingRequestsLoaded) {
              final instant = state.requests.where((r) => r.isInstant).toList();
              final scheduled = state.requests.where((r) => !r.isInstant).toList();
              return RefreshIndicator(
                onRefresh: () async => _cubit.load(),
                color: const Color(0xFF6C63FF),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _RequestList(requests: instant, onRefresh: () => _cubit.load()),
                    _RequestList(requests: scheduled, onRefresh: () => _cubit.load()),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg) {
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
              child: const Icon(Icons.wifi_off_rounded, color: Color(0xFFFF6B6B), size: 44),
            ),
            const SizedBox(height: 20),
            const Text('Failed to load requests',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => _cubit.load(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<HelperBooking> requests;
  final VoidCallback onRefresh;
  const _RequestList({required this.requests, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3C),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_rounded, color: Colors.white24, size: 52),
            ),
            const SizedBox(height: 20),
            const Text('No requests right now',
                style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('New requests will appear here automatically',
                style: TextStyle(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: requests.length,
      itemBuilder: (context, i) => _RequestCard(booking: requests[i], onDeclined: onRefresh),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final HelperBooking booking;
  final VoidCallback onDeclined;
  const _RequestCard({required this.booking, required this.onDeclined});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.booking.responseDeadline.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _remaining = widget.booking.responseDeadline.difference(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = !_remaining.isNegative && _remaining.inSeconds < 60;
    final isExpired = _remaining.isNegative;
    final accentColor =
        isUrgent ? const Color(0xFFFF6B6B) : const Color(0xFF6C63FF);

    return GestureDetector(
      onTap: () => context.push('/helper/request-details/${widget.booking.id}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUrgent
                ? [const Color(0xFF2E1212), const Color(0xFF1A1F3C)]
                : [const Color(0xFF1A1F3C), const Color(0xFF141829)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: accentColor.withValues(alpha: isUrgent ? 0.5 : 0.15)),
          boxShadow: [
            BoxShadow(
              color: isUrgent
                  ? const Color(0xFFFF6B6B).withOpacity(0.15)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  _Avatar(name: widget.booking.travelerName),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.booking.travelerName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(widget.booking.pickupLocation,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (isUrgent && !isExpired)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('URGENT',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Destination + payout
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.flag_rounded, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(widget.booking.destinationLocation,
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C896).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF00C896).withOpacity(0.3)),
                    ),
                    child: Text(
                      '\$${widget.booking.payout.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Color(0xFF00C896),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Timer
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      color: isUrgent ? const Color(0xFFFF6B6B) : Colors.white24,
                      size: 14),
                  const SizedBox(width: 4),
                  Text(
                    isExpired ? 'Expired' : _fmtDuration(_remaining),
                    style: TextStyle(
                      color: isExpired
                          ? Colors.white24
                          : (isUrgent
                              ? const Color(0xFFFF6B6B)
                              : Colors.white38),
                      fontSize: 12,
                      fontWeight:
                          isUrgent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (!isExpired) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ActionBtn(
                        label: 'Accept',
                        color: const Color(0xFF00C896),
                        onTap: () => context
                            .push('/helper/request-details/${widget.booking.id}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Decline',
                        color: const Color(0xFFFF6B6B),
                        outline: true,
                        onTap: () => _showDecline(context),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m remaining';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s remaining';
  }

  void _showDecline(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F3C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => BlocProvider(
        create: (_) => sl<DeclineBookingCubit>(),
        child: _DeclineSheet(
          bookingId: widget.booking.id,
          onSuccess: widget.onDeclined,
        ),
      ),
    );
  }
}

// ── Decline Bottom Sheet ─────────────────────────────────────────────────────

class _DeclineSheet extends StatefulWidget {
  final String bookingId;
  final VoidCallback onSuccess;
  const _DeclineSheet({required this.bookingId, required this.onSuccess});

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
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
        if (state is DeclineBookingSuccess) {
          Navigator.pop(context);
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request declined'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is DeclineBookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFFF6B6B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              const Text('Decline Request',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Select a reason (optional)',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 16),
              ..._reasons.map((r) => InkWell(
                    onTap: () => setState(() => _selected = r),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selected == r
                            ? const Color(0xFFFF6B6B).withOpacity(0.1)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selected == r
                              ? const Color(0xFFFF6B6B).withOpacity(0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selected == r
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _selected == r
                                ? const Color(0xFFFF6B6B)
                                : Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(r,
                              style: TextStyle(
                                  color: _selected == r
                                      ? Colors.white
                                      : Colors.white60)),
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
                        backgroundColor: const Color(0xFFFF6B6B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Confirm Decline',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
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

// ── Shared Micro-Widgets ─────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.18),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Color(0xFF6C63FF),
            fontWeight: FontWeight.bold,
            fontSize: 17),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outline;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.color,
      required this.onTap,
      this.outline = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : color,
          border: outline ? Border.all(color: color) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: outline ? color : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    );
  }
}
