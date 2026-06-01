import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../../../core/services/sos/sos_service.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_status.dart';
import '../../cubits/scheduled/scheduled_booking_detail_cubit.dart';
import '../../widgets/scheduled/countdown_chip.dart';
import 'cancel_booking_sheet.dart';
import 'rate_helper_sheet.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF000668);
const _kBlue = Color(0xFF4851C4);
const _kAmber = Color(0xFFFE9331);
const _kSurface = Color(0xFFFBF8FF);
const _kCard = Color(0xFFFFFFFF);
const _kMuted = Color(0xFF767683);
const _kContainerLow = Color(0xFFF4F2FF);
const _kOutlineVariant = Color(0xFFC6C5D3);
const _kOnSurface = Color(0xFF1A1B25);
const _kOnSurfaceVariant = Color(0xFF464651);
const _kSuccess = Color(0xFF1DB97A);
const _kDanger = Color(0xFFE53935);

const _kGradient = LinearGradient(
  colors: [_kNavy, _kBlue],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

const _kCardShadow = [
  BoxShadow(color: Color(0x121B237E), blurRadius: 28, offset: Offset(0, 10)),
];

// ── Entry point ───────────────────────────────────────────────────────────────

class ScheduledBookingDetailScreen extends StatelessWidget {
  final String bookingId;
  const ScheduledBookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScheduledBookingDetailCubit>(
      create: (_) => sl<ScheduledBookingDetailCubit>()..load(bookingId),
      child: _DetailBody(bookingId: bookingId),
    );
  }
}

// ── Detail body (stateful — SOS subscriptions) ────────────────────────────────

class _DetailBody extends StatefulWidget {
  final String bookingId;
  const _DetailBody({required this.bookingId});

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  StreamSubscription<dynamic>? _sosTriggeredSub;
  StreamSubscription<dynamic>? _sosResolvedSub;

  @override
  void initState() {
    super.initState();
    final hub = sl<BookingTrackingHubService>();
    _sosTriggeredSub = hub.sosTriggeredStream.listen((e) {
      if (!mounted || e.bookingId != widget.bookingId) return;
      context.read<ScheduledBookingDetailCubit>().onSosTriggered();
    });
    _sosResolvedSub = hub.sosResolvedStream.listen((e) {
      if (!mounted || e.bookingId != widget.bookingId) return;
      context.read<ScheduledBookingDetailCubit>().onSosResolved();
    });
  }

  @override
  void dispose() {
    _sosTriggeredSub?.cancel();
    _sosResolvedSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() =>
      context.read<ScheduledBookingDetailCubit>().refresh();

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kSurface,
      body: BlocBuilder<ScheduledBookingDetailCubit, ScheduledBookingDetailState>(
        builder: (context, state) {
          if (state is ScheduledBookingDetailLoading ||
              state is ScheduledBookingDetailInitial) {
            return _SkeletonView(topPad: topPad);
          }
          if (state is ScheduledBookingDetailError) {
            return _ErrorView(
              topPad: topPad,
              message: state.message,
              onRetry: () => context
                  .read<ScheduledBookingDetailCubit>()
                  .load(widget.bookingId),
            );
          }
          if (state is! ScheduledBookingDetailLoaded) {
            return const SizedBox.shrink();
          }

          final booking = state.booking;

          return Stack(
            children: [
              // ── Scrollable content ─────────────────────────────────────
              RefreshIndicator(
                color: _kNavy,
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(height: topPad + 72),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        120 + bottomPad,
                      ),
                      sliver: SliverList.list(
                        children: [
                          // SOS banner
                          if (state.sosActive) ...[
                            _SosBanner(bookingId: booking.bookingId),
                            const SizedBox(height: 14),
                          ],

                          // Status banner
                          _StatusBanner(booking: booking),
                          const SizedBox(height: 16),

                          // Helper card
                          if (booking.helper != null) ...[
                            _HelperCard(
                              booking: booking,
                              unreadCount: state.unreadChatCount,
                              onChatRead: () => context
                                  .read<ScheduledBookingDetailCubit>()
                                  .markChatRead(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Trip details
                          _TripDetailsCard(booking: booking),
                          const SizedBox(height: 16),

                          // Price
                          _PriceCard(booking: booking),

                          // Timeline
                          if (booking.statusHistory.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _TripTimeline(booking: booking),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Fixed header ───────────────────────────────────────────
              _Header(
                topPad: topPad,
                bookingId: booking.bookingId,
              ),

              // ── Sticky bottom CTA ──────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StickyBottom(
                  booking: booking,
                  bottomPad: bottomPad,
                  onRefresh: _refresh,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Fixed header ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  final String bookingId;
  const _Header({required this.topPad, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final shortId =
        bookingId.length > 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId.toUpperCase();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 12),
        decoration: BoxDecoration(
          color: _kSurface.withValues(alpha: 0.92),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0E1B237E),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.pop();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _kCard,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0E1B237E),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _kOnSurface,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Booking',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kOnSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '#$shortId',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Refresh button
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _kCard,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.share_outlined,
                  color: _kOnSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status banner (7 states) ──────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final BookingDetail booking;
  const _StatusBanner({required this.booking});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(booking);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: cfg.gradient,
        color: cfg.gradient == null ? cfg.solidBg : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (cfg.gradient?.colors.first ?? cfg.solidBg!)
                .withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    cfg.icon,
                    color: cfg.onColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cfg.title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cfg.onColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (cfg.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        cfg.subtitle!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: cfg.onColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (cfg.deadline != null)
                CountdownChip(
                  deadline: cfg.deadline!,
                  label: cfg.deadlineLabel ?? '',
                  expiredLabel: "Time's up",
                  dense: true,
                ),
            ],
          ),
          if (cfg.indeterminate) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _BannerCfg _config(BookingDetail d) {
    final helperName = d.helper?.fullName ?? d.currentAssignment?.helperName;
    final firstName =
        helperName != null && helperName.isNotEmpty ? helperName.split(' ').first : null;

    switch (d.status) {
      case BookingStatus.pendingHelperResponse:
        return _BannerCfg(
          title: firstName != null
              ? 'Waiting for $firstName to respond'
              : 'Waiting for a helper to respond',
          subtitle: "We'll notify you the moment they accept.",
          icon: Icons.access_time_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFFB923C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          onColor: Colors.white,
          deadline: d.responseDeadline,
          deadlineLabel: 'Replies in',
        );
      case BookingStatus.reassignmentInProgress:
        return _BannerCfg(
          title: 'Finding another guide for you…',
          subtitle: 'The previous helper declined. Searching now.',
          icon: Icons.swap_horiz_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFFB923C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          onColor: Colors.white,
          indeterminate: true,
        );
      case BookingStatus.waitingForUserAction:
        return _BannerCfg(
          title: 'Action needed — no match found',
          subtitle: 'Pick an alternative guide or cancel your booking.',
          icon: Icons.priority_high_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFFB923C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          onColor: Colors.white,
        );
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
        return _BannerCfg(
          title: firstName != null
              ? '$firstName couldn\'t take this trip'
              : 'Helper couldn\'t take this trip',
          subtitle: 'Choose a different guide to keep your plans on track.',
          icon: Icons.sync_alt_rounded,
          solidBg: const Color(0xFFFFF3E0),
          onColor: const Color(0xFFE65100),
        );
      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmedAwaitingPayment:
        return _BannerCfg(
          title: firstName != null
              ? '$firstName accepted! Deposit due'
              : 'Guide accepted! Deposit due',
          subtitle: 'Secure your booking with a small deposit.',
          icon: Icons.payments_rounded,
          gradient: _kGradient,
          onColor: Colors.white,
        );
      case BookingStatus.confirmedPaid:
      case BookingStatus.upcoming:
        final tripStart = _composeTripStart(d);
        return _BannerCfg(
          title: firstName != null
              ? 'All set! $firstName is your guide'
              : 'Booking confirmed & paid',
          subtitle: 'Your adventure begins soon. Chat anytime.',
          icon: Icons.check_circle_rounded,
          solidBg: const Color(0xFFE8F5E9),
          onColor: const Color(0xFF2E7D32),
          deadline: tripStart,
          deadlineLabel: 'Starts in',
        );
      case BookingStatus.inProgress:
        return _BannerCfg(
          title: 'Your adventure is underway! 🚩',
          subtitle: firstName != null
              ? 'Currently exploring with $firstName.'
              : 'Your trip is in progress.',
          icon: Icons.explore_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF1DB97A), Color(0xFF059669)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          onColor: Colors.white,
        );
      case BookingStatus.completed:
        return _BannerCfg(
          title: 'What a journey! 🎉',
          subtitle: 'Trip completed. Rate your experience below.',
          icon: Icons.emoji_events_rounded,
          solidBg: const Color(0xFFE8F5E9),
          onColor: const Color(0xFF2E7D32),
        );
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
        return _BannerCfg(
          title: 'Booking Cancelled',
          subtitle: d.cancellationReason ?? 'This booking has been cancelled.',
          icon: Icons.cancel_rounded,
          solidBg: const Color(0xFFF5F5F5),
          onColor: _kMuted,
        );
      case BookingStatus.unknown:
        return _BannerCfg(
          title: 'Booking',
          subtitle: 'Status: ${d.rawStatus}',
          icon: Icons.help_outline_rounded,
          solidBg: _kContainerLow,
          onColor: _kOnSurfaceVariant,
        );
    }
  }
}

class _BannerCfg {
  final String title;
  final String? subtitle;
  final IconData icon;
  final LinearGradient? gradient;
  final Color? solidBg;
  final Color onColor;
  final DateTime? deadline;
  final String? deadlineLabel;
  final bool indeterminate;
  const _BannerCfg({
    required this.title,
    this.subtitle,
    required this.icon,
    this.gradient,
    this.solidBg,
    required this.onColor,
    this.deadline,
    this.deadlineLabel,
    this.indeterminate = false,
  });
}

// ── SOS active banner ─────────────────────────────────────────────────────────

class _SosBanner extends StatelessWidget {
  final String bookingId;
  const _SosBanner({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kDanger, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.report_rounded,
              color: _kDanger,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SOS Active — Support Notified',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kDanger,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Our support team is on the way. You can call your guide or contact support.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: _kDanger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper card ───────────────────────────────────────────────────────────────

class _HelperCard extends StatelessWidget {
  final BookingDetail booking;
  final int unreadCount;
  final VoidCallback onChatRead;

  const _HelperCard({
    required this.booking,
    required this.unreadCount,
    required this.onChatRead,
  });

  Future<void> _call(BuildContext context) async {
    final phone = booking.helper?.phoneNumber?.trim() ?? '';
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone number not available'),
          backgroundColor: _kNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _chat(BuildContext context) {
    HapticFeedback.selectionClick();
    onChatRead();
    context.push(
      AppRouter.userChat.replaceFirst(':id', booking.bookingId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = booking.helper!;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _kCardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x141B237E),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: h.profileImageUrl != null
                      ? AppNetworkImage(
                          imageUrl: h.profileImageUrl,
                          width: 64,
                          height: 64,
                          borderRadius: 32,
                        )
                      : Container(
                          color: _kContainerLow,
                          alignment: Alignment.center,
                          child: Text(
                            h.fullName.isNotEmpty
                                ? h.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: _kNavy,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: _kAmber,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          h.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kNavy,
                          ),
                        ),
                        Text(
                          '  ·  ${h.completedTrips} trips',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: _kMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action pills
          Row(
            children: [
              if (booking.chatEnabled)
                Expanded(
                  child: _ActionPill(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: unreadCount > 0 ? 'Chat ($unreadCount)' : 'Chat',
                    color: _kBlue,
                    bg: _kContainerLow,
                    onTap: () => _chat(context),
                  ),
                ),
              if (booking.chatEnabled) const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  color: const Color(0xFF2E7D32),
                  bg: const Color(0xFFE8F5E9),
                  onTap: () => _call(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trip details card (collapsible) ──────────────────────────────────────────

class _TripDetailsCard extends StatefulWidget {
  final BookingDetail booking;
  const _TripDetailsCard({required this.booking});

  @override
  State<_TripDetailsCard> createState() => _TripDetailsCardState();
}

class _TripDetailsCardState extends State<_TripDetailsCard> {
  bool _expanded = true;

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _durationLabel(int mins) {
    if (mins == 480) return 'Full Day';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _kContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      size: 18,
                      color: _kBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Trip Details',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kOnSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      children: [
                        // Divider
                        Container(
                          height: 1,
                          color: _kOutlineVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 14),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.2,
                          children: [
                            if (b.requestedDate != null)
                              _InfoTile(
                                icon: Icons.calendar_today_outlined,
                                label: 'Date',
                                value: _fmtDate(b.requestedDate!),
                              ),
                            if (b.startTime != null)
                              _InfoTile(
                                icon: Icons.access_time_rounded,
                                label: 'Start Time',
                                value: b.startTime!.substring(0, 5),
                              ),
                            _InfoTile(
                              icon: Icons.hourglass_bottom_rounded,
                              label: 'Duration',
                              value: _durationLabel(b.durationInMinutes),
                            ),
                            _InfoTile(
                              icon: Icons.people_alt_outlined,
                              label: 'Travelers',
                              value: '${b.travelersCount} pax',
                            ),
                            if (b.destinationCity != null)
                              _InfoTile(
                                icon: Icons.location_city_rounded,
                                label: 'City',
                                value: b.destinationCity!,
                              ),
                            if (b.requestedLanguage != null)
                              _InfoTile(
                                icon: Icons.translate_rounded,
                                label: 'Language',
                                value: b.requestedLanguage!,
                              ),
                            if (b.meetingPointType != null)
                              _InfoTile(
                                icon: Icons.meeting_room_outlined,
                                label: 'Meeting',
                                value: b.meetingPointType!,
                              ),
                            if (b.pickupLocationName.isNotEmpty)
                              _InfoTile(
                                icon: Icons.my_location_rounded,
                                label: 'Pickup',
                                value: b.pickupLocationName,
                              ),
                          ],
                        ),
                        if (b.notes != null && b.notes!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _kContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.notes_rounded,
                                  size: 15,
                                  color: _kBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    b.notes!,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: _kOnSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kOutlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: _kMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: _kMuted,
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kOnSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price card ────────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final BookingDetail booking;
  const _PriceCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final price = b.finalPrice ?? b.estimatedPrice;
    final isEstimate = b.finalPrice == null;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _kCardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: _kAmber,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Price',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kOnSurface,
                ),
              ),
              const Spacer(),
              if (b.depositPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Deposit Paid',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 1,
            color: _kOutlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 14),
          if (b.depositAmount != null)
            _PriceRow(
              label: 'Deposit',
              value: 'EGP ${b.depositAmount!.toStringAsFixed(0)}',
              done: b.depositPaid,
            ),
          if (b.remainingAmount != null && b.remainingAmount! > 0) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: 'Remaining',
              value: 'EGP ${b.remainingAmount!.toStringAsFixed(0)}',
              done: b.remainingPaid,
            ),
          ],
          if (price != null) ...[
            const SizedBox(height: 10),
            Container(
              height: 1,
              color: _kOutlineVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEstimate ? 'TOTAL ESTIMATED' : 'TOTAL',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: _kOnSurface,
                  ),
                ),
                Text(
                  'EGP ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _kNavy,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool done;
  const _PriceRow({
    required this.label,
    required this.value,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            color: _kMuted,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kOnSurface,
              ),
            ),
            if (done) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: _kSuccess,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Trip timeline ─────────────────────────────────────────────────────────────

class _TripTimeline extends StatelessWidget {
  final BookingDetail booking;
  const _TripTimeline({required this.booking});

  static const _steps = [
    (BookingStatus.pendingHelperResponse, 'Requested', Icons.send_rounded),
    (BookingStatus.acceptedByHelper, 'Accepted', Icons.handshake_outlined),
    (BookingStatus.confirmedPaid, 'Confirmed', Icons.payments_rounded),
    (BookingStatus.inProgress, 'In Progress', Icons.explore_rounded),
    (BookingStatus.completed, 'Completed', Icons.emoji_events_rounded),
  ];

  int _statusLevel(BookingStatus s) {
    switch (s) {
      case BookingStatus.pendingHelperResponse:
      case BookingStatus.reassignmentInProgress:
      case BookingStatus.waitingForUserAction:
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
        return 0;
      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmedAwaitingPayment:
        return 1;
      case BookingStatus.confirmedPaid:
      case BookingStatus.upcoming:
        return 2;
      case BookingStatus.inProgress:
        return 3;
      case BookingStatus.completed:
        return 4;
      default:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _statusLevel(booking.status);
    final isCancelled = booking.status == BookingStatus.cancelledByUser ||
        booking.status == BookingStatus.cancelledByHelper ||
        booking.status == BookingStatus.cancelledBySystem;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _kCardShadow,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  size: 18,
                  color: _kBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Trip Progress',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kOnSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isCancelled)
            _CancelledTimeline(booking: booking)
          else
            Column(
              children: List.generate(_steps.length, (i) {
                final step = _steps[i];
                final done = i <= level;
                final active = i == level;
                final isLast = i == _steps.length - 1;

                DateTime? timestamp;
                switch (step.$1) {
                  case BookingStatus.pendingHelperResponse:
                    timestamp = booking.createdAt;
                    break;
                  case BookingStatus.acceptedByHelper:
                    timestamp = booking.acceptedAt;
                    break;
                  case BookingStatus.confirmedPaid:
                    timestamp = booking.confirmedAt;
                    break;
                  case BookingStatus.inProgress:
                    timestamp = booking.startedAt;
                    break;
                  case BookingStatus.completed:
                    timestamp = booking.completedAt;
                    break;
                  default:
                    break;
                }

                return _TimelineStep(
                  icon: step.$3,
                  label: step.$2,
                  timestamp: timestamp,
                  done: done,
                  active: active,
                  isLast: isLast,
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? timestamp;
  final bool done;
  final bool active;
  final bool isLast;

  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.timestamp,
    required this.done,
    required this.active,
    required this.isLast,
  });

  String _fmtTs(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h % 12 == 0 ? 12 : h % 12;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}  $displayH:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            // Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: active || done ? _kGradient : null,
                color: active || done ? null : _kContainerLow,
                shape: BoxShape.circle,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: _kNavy.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  done ? Icons.check_rounded : icon,
                  size: 14,
                  color: (active || done) ? Colors.white : _kMuted,
                ),
              ),
            ),
            // Connecting line
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                margin: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  gradient: done ? _kGradient : null,
                  color: done ? null : _kOutlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight:
                        active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? _kNavy : (done ? _kOnSurface : _kMuted),
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _fmtTs(timestamp!.toLocal()),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: _kMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CancelledTimeline extends StatelessWidget {
  final BookingDetail booking;
  const _CancelledTimeline({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.cancel_rounded, size: 16, color: _kDanger),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cancelled',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kDanger,
                ),
              ),
              if (booking.cancellationReason != null) ...[
                const SizedBox(height: 3),
                Text(
                  booking.cancellationReason!,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: _kMuted,
                  ),
                ),
              ],
              if (booking.cancelledAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  _fmtTs(booking.cancelledAt!),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    color: _kMuted,
                  ),
                ),
              ],
              if (booking.depositForfeited)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'Deposit forfeited',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kDanger,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtTs(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day} ${d.year}';
  }
}

// ── Sticky bottom CTA bar ─────────────────────────────────────────────────────

class _StickyBottom extends StatelessWidget {
  final BookingDetail booking;
  final double bottomPad;
  final Future<void> Function() onRefresh;

  const _StickyBottom({
    required this.booking,
    required this.bottomPad,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _buildActions(context);
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPad),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141B237E),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: actions
            .asMap()
            .entries
            .expand((e) => [
                  if (e.key > 0) const SizedBox(width: 10),
                  Expanded(child: e.value),
                ])
            .toList(),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final id = booking.bookingId;

    // Dismiss SOS helper
    Future<void> showSos() async {
      HapticFeedback.heavyImpact();
      final result = await sl<SosService>().trigger(
        bookingId: id,
        reason: 'user-trip-sos',
      );
      if (!context.mounted) return;
      final msg = result.success ? 'SOS active — help is on the way.' : (result.message ?? 'SOS failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: result.success ? _kSuccess : _kDanger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      if (result.success && context.mounted) {
        context.read<ScheduledBookingDetailCubit>().onSosTriggered();
      }
    }

    Future<void> showCancel() async {
      final penalty = _cancellationPenalty(booking);
      final result = await showModalBottomSheet<CancelResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CancelBookingSheet(
          bookingId: id,
          contextHint: penalty.contextHint,
          refundHint: penalty.refundHint,
          forfeitsDeposit: penalty.forfeitsDeposit,
        ),
      );
      if (result != null && context.mounted) {
        unawaited(onRefresh());
      }
    }

    switch (booking.status) {
      case BookingStatus.pendingHelperResponse:
        return [
          _GhostBtn(
            label: 'Cancel Request',
            danger: true,
            onTap: () => showCancel(),
          ),
        ];
      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmedAwaitingPayment:
        return [
          _GhostBtn(label: 'Cancel', danger: true, onTap: () => showCancel()),
          _GradientBtn(
            label: 'Pay Deposit',
            onTap: () => context.push(
              AppRouter.paymentMethod.replaceFirst(':bookingId', id),
            ),
          ),
        ];
      case BookingStatus.confirmedPaid:
      case BookingStatus.upcoming:
        return [
          if (booking.canCancel)
            _GhostBtn(
              label: 'Cancel',
              danger: true,
              onTap: () => showCancel(),
            ),
          if (booking.chatEnabled)
            _GradientBtn(
              label: 'Message Guide',
              onTap: () => context.push(
                AppRouter.userChat.replaceFirst(':id', id),
              ),
            ),
        ];
      case BookingStatus.inProgress:
        return [
          _GhostBtn(
            label: '🚨 SOS',
            danger: true,
            onTap: showSos,
          ),
          _GradientBtn(
            label: 'Track Live 📍',
            onTap: () => context.push(
              AppRouter.userTracking.replaceFirst(':id', id),
            ),
          ),
        ];
      case BookingStatus.completed:
        return [
          _GradientBtn(
            label: 'Rate Your Guide ⭐',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => RateHelperSheet(bookingId: id),
            ),
          ),
        ];
      case BookingStatus.reassignmentInProgress:
      case BookingStatus.waitingForUserAction:
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
        return [
          _GradientBtn(
            label: 'See Alternatives →',
            onTap: () => context.push(
              AppRouter.scheduledAlternatives.replaceFirst(':id', id),
            ),
          ),
        ];
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
        return [
          _GradientBtn(
            label: 'Book a New Trip',
            onTap: () => context.go(AppRouter.scheduledSearch),
          ),
        ];
      case BookingStatus.unknown:
        return [];
    }
  }
}

class _GradientBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: _kGradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: _kNavy.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  final String label;
  final bool danger;
  final VoidCallback onTap;
  const _GhostBtn({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _kDanger : _kNavy;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _CancellationPenalty {
  final String? contextHint;
  final String? refundHint;
  final bool forfeitsDeposit;
  const _CancellationPenalty({
    this.contextHint,
    this.refundHint,
    this.forfeitsDeposit = false,
  });
}

_CancellationPenalty _cancellationPenalty(BookingDetail d) {
  if (!d.depositPaid) {
    return const _CancellationPenalty(
      contextHint: 'No charge — cancelling now is free.',
    );
  }
  final tripStart = _composeTripStart(d);
  final dep = d.depositAmount?.toStringAsFixed(0);
  final now = DateTime.now();
  if (tripStart != null && tripStart.difference(now).inHours > 24) {
    return _CancellationPenalty(
      refundHint: dep == null
          ? 'Your deposit will be refunded within 24h.'
          : 'Your $dep EGP deposit will be refunded within 24h.',
    );
  }
  return _CancellationPenalty(
    refundHint: dep == null
        ? '⚠️ Cancelling now will forfeit your deposit.'
        : '⚠️ Cancelling now will forfeit your $dep EGP deposit.',
    forfeitsDeposit: true,
  );
}

DateTime? _composeTripStart(BookingDetail d) {
  if (d.requestedDate == null || d.startTime == null) return null;
  final parts = d.startTime!.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  final base = d.requestedDate!.toLocal();
  return DateTime(base.year, base.month, base.day, h, m);
}

// ── Skeleton & Error ──────────────────────────────────────────────────────────

class _SkeletonView extends StatefulWidget {
  final double topPad;
  const _SkeletonView({required this.topPad});

  @override
  State<_SkeletonView> createState() => _SkeletonViewState();
}

class _SkeletonViewState extends State<_SkeletonView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final shimmer = Color.lerp(
          const Color(0xFFE8E6F0),
          const Color(0xFFF5F3FF),
          _ctrl.value,
        )!;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, widget.topPad + 80, 20, 0),
          child: Column(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final double topPad;
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({
    required this.topPad,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: _kDanger,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                color: _kMuted,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: _kGradient,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
