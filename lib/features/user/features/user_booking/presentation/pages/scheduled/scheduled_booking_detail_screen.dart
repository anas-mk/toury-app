import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../../../core/services/sos/sos_service.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/theme/brand_typography.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_status.dart';
import '../../cubits/scheduled/scheduled_booking_detail_cubit.dart';
import '../../widgets/scheduled/countdown_chip.dart';
import '../../widgets/scheduled/status_timeline.dart';
import 'cancel_booking_sheet.dart';
import 'rate_helper_sheet.dart';

/// Phase 5 — the spine of the Scheduled Trip flow.
///
/// One screen, many states. Layout adapts based on `booking.status` and
/// the user's next available action. See [_PrimaryCta] and [_StatusBanner]
/// for the per-status branching.
class ScheduledBookingDetailScreen extends StatelessWidget {
  final String bookingId;
  const ScheduledBookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScheduledBookingDetailCubit>(
      create: (_) => sl<ScheduledBookingDetailCubit>()..load(bookingId),
      child: _DetailView(bookingId: bookingId),
    );
  }
}

class _DetailView extends StatefulWidget {
  final String bookingId;
  const _DetailView({required this.bookingId});

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  StreamSubscription<dynamic>? _sosTriggeredSub;
  StreamSubscription<dynamic>? _sosResolvedSub;

  @override
  void initState() {
    super.initState();
    // Fix 11: SOS events aren't on the realtime BUS yet, so subscribe
    // directly to the hub for this specific booking. We keep the
    // subscription alive only while this screen is mounted.
    final hub = sl<BookingTrackingHubService>();
    _sosTriggeredSub = hub.sosTriggeredStream.listen((e) {
      if (!mounted) return;
      // The event payload exposes a `bookingId` field (camelCase from
      // signalr_netcore). Filter strictly to avoid showing SOS for an
      // unrelated booking on a multi-booking account.
      if (e.bookingId != widget.bookingId) return;
      context.read<ScheduledBookingDetailCubit>().onSosTriggered();
    });
    _sosResolvedSub = hub.sosResolvedStream.listen((e) {
      if (!mounted) return;
      if (e.bookingId != widget.bookingId) return;
      context.read<ScheduledBookingDetailCubit>().onSosResolved();
    });
  }

  @override
  void dispose() {
    _sosTriggeredSub?.cancel();
    _sosResolvedSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<ScheduledBookingDetailCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      bottomCta: BlocBuilder<ScheduledBookingDetailCubit,
          ScheduledBookingDetailState>(
        builder: (context, state) {
          if (state is ScheduledBookingDetailLoaded) {
            return _PrimaryCta(detail: state.booking);
          }
          return const SizedBox.shrink();
        },
      ),
      body: BlocBuilder<ScheduledBookingDetailCubit,
          ScheduledBookingDetailState>(
        builder: (context, state) {
          if (state is ScheduledBookingDetailLoading ||
              state is ScheduledBookingDetailInitial) {
            return const _Loading();
          }
          if (state is ScheduledBookingDetailError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<ScheduledBookingDetailCubit>()
                  .load(widget.bookingId),
            );
          }
          if (state is ScheduledBookingDetailLoaded) {
            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _refresh,
                  color: BrandTokens.primaryBlue,
                  child: _LoadedView(state: state),
                ),
                if (state.booking.status == BookingStatus.inProgress)
                  Positioned(
                    right: 16,
                    bottom: 12,
                    child: _SosFloatingButton(bookingId: state.booking.bookingId),
                  ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final ScheduledBookingDetailLoaded state;
  const _LoadedView({required this.state});

  BookingDetail get detail => state.booking;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: BrandTokens.bgSoft,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: BrandTokens.textPrimary),
          title: Text(
            'Scheduled trip',
            style: BrandTypography.title(weight: FontWeight.w700),
          ),
          actions: [
            if (detail.canCancel)
              IconButton(
                tooltip: 'Cancel booking',
                onPressed: () => _confirmCancel(context, detail),
                icon: const Icon(
                  Icons.close_rounded,
                  color: BrandTokens.dangerRed,
                ),
              ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          sliver: SliverList.list(
            children: [
              if (state.sosActive) ...[
                _SosBanner(bookingId: detail.bookingId),
                const SizedBox(height: 12),
              ],
              _StatusBanner(detail: detail),
              const SizedBox(height: 16),
              if (detail.helper != null)
                _HelperCard(detail: detail, unreadCount: state.unreadChatCount),
              if (detail.helper != null) const SizedBox(height: 16),
              _TripCard(detail: detail),
              const SizedBox(height: 16),
              _PriceCard(detail: detail),
              if (detail.statusHistory.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Trip progress',
                  style: BrandTypography.body(weight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                StatusTimeline(
                  status: detail.status,
                  createdAt: detail.createdAt,
                  acceptedAt: detail.acceptedAt,
                  confirmedAt: detail.confirmedAt,
                  startedAt: detail.startedAt,
                  completedAt: detail.completedAt,
                  cancelledAt: detail.cancelledAt,
                  cancellationReason: detail.cancellationReason,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    BookingDetail d,
  ) async {
    // Fix 9: pass the real penalty hint based on deposit + free-window
    // calculations, not free-form copy.
    final penalty = _cancellationPenalty(d);
    final result = await SoftBottomSheet.show<CancelResult>(
      context: context,
      child: CancelBookingSheet(
        bookingId: d.bookingId,
        contextHint: penalty.contextHint,
        refundHint: penalty.refundHint,
        forfeitsDeposit: penalty.forfeitsDeposit,
      ),
    );
    if (result != null && context.mounted) {
      unawaited(
        context.read<ScheduledBookingDetailCubit>().refresh(),
      );
    }
  }
}

/// Computes the honest cancellation-penalty copy (Fix 9) from the booking
/// detail. The free-cancellation window is "more than 24h before the trip
/// start", which matches the conservative wording in the prompt; the
/// backend remains the source of truth for whether the deposit is
/// actually forfeited (we surface `depositForfeited` in the price card
/// after the cancel call returns).
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
  // depositPaid is true → check the free window.
  final tripStart = _composeTripStart(d);
  final now = DateTime.now();
  final dep = d.depositAmount?.toStringAsFixed(0);
  if (tripStart == null) {
    // We can't tell — be conservative and flag it as forfeitable.
    return _CancellationPenalty(
      refundHint: dep == null
          ? 'Cancelling may forfeit your deposit per the cancellation policy.'
          : 'Cancelling now may forfeit your $dep EGP deposit per the '
              'cancellation policy.',
      forfeitsDeposit: true,
    );
  }
  final hoursUntilStart = tripStart.difference(now).inMinutes / 60.0;
  if (hoursUntilStart > 24) {
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

class _StatusBanner extends StatelessWidget {
  final BookingDetail detail;
  const _StatusBanner({required this.detail});

  @override
  Widget build(BuildContext context) {
    final visuals = _bannerVisuals(detail);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: visuals.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: visuals.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: visuals.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(visuals.icon, color: visuals.fg, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      visuals.title,
                      style: BrandTypography.title(
                        weight: FontWeight.w700,
                        color: visuals.fg,
                      ),
                    ),
                    if (visuals.indeterminate)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: SizedBox(
                          height: 3,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              BrandTokens.accentAmberText,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (visuals.deadline != null)
                CountdownChip(
                  deadline: visuals.deadline!,
                  label: visuals.deadlineLabel ?? 'In',
                  expiredLabel: 'Time\u2019s up',
                  dense: true,
                ),
            ],
          ),
          if (visuals.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              visuals.subtitle!,
              style: BrandTypography.caption(color: visuals.fg),
            ),
          ],
        ],
      ),
    );
  }

  /// Granular per-status banner copy/visuals (Fix 10).
  _BannerVisuals _bannerVisuals(BookingDetail d) {
    final helperName = d.currentAssignment?.helperName ?? d.helper?.fullName;

    switch (d.status) {
      case BookingStatus.pendingHelperResponse:
        return _BannerVisuals(
          title: helperName != null && helperName.isNotEmpty
              ? 'Waiting for $helperName to respond'
              : 'Waiting for the helper to respond',
          subtitle:
              'We\u2019ll notify you the moment they accept or decline.',
          icon: Icons.sensors_rounded,
          fg: BrandTokens.accentAmberText,
          bg: BrandTokens.accentAmberSoft,
          iconBg: const Color(0xFFFDE68A),
          border: BrandTokens.accentAmberBorder,
          deadline: d.responseDeadline,
          deadlineLabel: 'Replies in',
        );
      case BookingStatus.reassignmentInProgress:
        return _BannerVisuals(
          title: 'Finding another helper for you\u2026',
          subtitle:
              'The previous helper couldn\u2019t take this trip. We\u2019re '
              'reaching out to others.',
          icon: Icons.travel_explore_rounded,
          fg: BrandTokens.accentAmberText,
          bg: BrandTokens.accentAmberSoft,
          iconBg: const Color(0xFFFDE68A),
          border: BrandTokens.accentAmberBorder,
          // Indeterminate spinner instead of a fake countdown — the
          // wait time is intentionally not advertised.
          indeterminate: true,
        );
      case BookingStatus.waitingForUserAction:
        return _BannerVisuals(
          title: 'No automatic match found',
          subtitle: 'Pick another helper from the alternatives or cancel.',
          icon: Icons.priority_high_rounded,
          fg: BrandTokens.accentAmberText,
          bg: BrandTokens.accentAmberSoft,
          iconBg: const Color(0xFFFDE68A),
          border: BrandTokens.accentAmberBorder,
        );
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
        return _BannerVisuals(
          title: helperName != null && helperName.isNotEmpty
              ? '$helperName couldn\u2019t take this trip'
              : 'Helper couldn\u2019t take this trip',
          subtitle: 'Pick a different helper to keep your plans on track.',
          icon: Icons.sync_alt_rounded,
          fg: BrandTokens.accentAmberText,
          bg: BrandTokens.accentAmberSoft,
          iconBg: const Color(0xFFFDE68A),
          border: BrandTokens.accentAmberBorder,
        );
      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmedAwaitingPayment:
        return _BannerVisuals(
          title: 'Helper accepted \u2014 deposit due',
          subtitle:
              'Pay your deposit to lock the booking. The remainder is paid '
              'after the trip.',
          icon: Icons.payments_rounded,
          fg: BrandTokens.primaryBlue,
          bg: BrandTokens.borderTinted,
          iconBg: Colors.white,
          border: BrandTokens.borderTinted,
        );
      case BookingStatus.confirmedPaid:
      case BookingStatus.upcoming:
        final tripStart = _composeTripStart(d);
        return _BannerVisuals(
          title: 'Booked and paid',
          subtitle: 'You\u2019re all set. Chat with your helper anytime.',
          icon: Icons.check_circle_rounded,
          fg: BrandTokens.successGreen,
          bg: BrandTokens.successGreenSoft,
          iconBg: Colors.white,
          border: BrandTokens.successGreenSoft,
          deadline: tripStart,
          deadlineLabel: 'Starts in',
        );
      case BookingStatus.inProgress:
        return _BannerVisuals(
          title: 'Trip in progress',
          subtitle: 'Open live tracking to follow your helper.',
          icon: Icons.directions_walk_rounded,
          fg: BrandTokens.successGreen,
          bg: BrandTokens.successGreenSoft,
          iconBg: Colors.white,
          border: BrandTokens.successGreen,
        );
      case BookingStatus.completed:
        return _BannerVisuals(
          title: 'Trip completed',
          subtitle: 'Thanks for using RAFIQ. Don\u2019t forget to rate '
              'your helper.',
          icon: Icons.flag_rounded,
          fg: BrandTokens.primaryBlue,
          bg: BrandTokens.borderTinted,
          iconBg: Colors.white,
          border: BrandTokens.borderTinted,
        );
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
        return _BannerVisuals(
          title: 'Cancelled',
          subtitle: d.cancellationReason ??
              'This booking was cancelled and won\u2019t be charged.',
          icon: Icons.cancel_rounded,
          fg: BrandTokens.dangerRed,
          bg: BrandTokens.dangerRedSoft,
          iconBg: Colors.white,
          border: BrandTokens.dangerRedSoft,
        );
      case BookingStatus.unknown:
        return _BannerVisuals(
          title: 'Booking',
          subtitle: 'Status: ${d.rawStatus}',
          icon: Icons.help_outline_rounded,
          fg: BrandTokens.textSecondary,
          bg: BrandTokens.bgSoft,
          iconBg: Colors.white,
          border: BrandTokens.borderSoft,
        );
    }
  }
}

class _BannerVisuals {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color fg;
  final Color bg;
  final Color iconBg;
  final Color border;
  final DateTime? deadline;
  final String? deadlineLabel;
  final bool indeterminate;

  const _BannerVisuals({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.fg,
    required this.bg,
    required this.iconBg,
    required this.border,
    this.deadline,
    this.deadlineLabel,
    this.indeterminate = false,
  });
}

class _SosBanner extends StatelessWidget {
  final String bookingId;
  const _SosBanner({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandTokens.dangerRedSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrandTokens.dangerRed, width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.report_rounded,
              color: BrandTokens.dangerRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Helper triggered SOS — admin notified',
                  style: BrandTypography.body(
                    weight: FontWeight.w800,
                    color: BrandTokens.dangerRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Our support team is on the way. You can call your '
                  'helper or contact support directly.',
                  style: BrandTypography.caption(
                    color: BrandTokens.dangerRed,
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

class _SosFloatingButton extends StatelessWidget {
  final String bookingId;
  const _SosFloatingButton({required this.bookingId});

  Future<void> _onPressed(BuildContext context) async {
    HapticFeedback.heavyImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Trigger SOS?'),
        content: const Text(
          'This will alert support and your emergency contacts. Use this '
          'only in a real emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BrandTokens.dangerRed,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Trigger SOS'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final result = await sl<SosService>().trigger(
      bookingId: bookingId,
      reason: 'user-trip-sos',
    );
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'SOS active — help is on the way.'
              : (result.message ?? 'SOS request failed.'),
        ),
        backgroundColor: result.success
            ? BrandTokens.successGreen
            : BrandTokens.dangerRed,
      ),
    );
    if (result.success) {
      // Reflect SOS state immediately — the SignalR `SosTriggered` will
      // also flow in shortly and is idempotent.
      context.read<ScheduledBookingDetailCubit>().onSosTriggered();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 56,
        child: Material(
          color: BrandTokens.dangerRed,
          shape: const StadiumBorder(),
          elevation: 8,
          shadowColor: BrandTokens.dangerRed.withValues(alpha: 0.45),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => _onPressed(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.report_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'SOS',
                    style: BrandTypography.body(
                      weight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelperCard extends StatelessWidget {
  final BookingDetail detail;
  final int unreadCount;
  const _HelperCard({required this.detail, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final h = detail.helper!;
    final initial =
        h.fullName.isEmpty ? '?' : h.fullName.substring(0, 1).toUpperCase();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Row(
        children: [
          ClipOval(
            child: h.profileImageUrl == null || h.profileImageUrl!.isEmpty
                ? Container(
                    width: 56,
                    height: 56,
                    color: BrandTokens.borderTinted,
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: BrandTypography.title(
                        weight: FontWeight.w700,
                        color: BrandTokens.primaryBlue,
                      ),
                    ),
                  )
                : Image.network(
                    h.profileImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: BrandTokens.borderTinted,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_rounded,
                        color: BrandTokens.primaryBlue,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.fullName,
                  style: BrandTypography.title(weight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      h.rating.toStringAsFixed(1),
                      style: BrandTypography.caption(
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('\u2022', style: BrandTypography.caption()),
                    const SizedBox(width: 6),
                    Text(
                      '${h.completedTrips} trips',
                      style: BrandTypography.caption(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (detail.chatEnabled)
            // Chat IconButton with unread badge (Fix 11). The badge is
            // local state from the cubit — it never refetches the
            // detail; the chat detail screen pulls messages from REST
            // when opened.
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Chat with helper',
                  onPressed: () => _openChat(context, detail.bookingId),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: BrandTokens.borderTinted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: BrandTokens.primaryBlue,
                      size: 18,
                    ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: BrandTokens.dangerRed,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 1.4),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: BrandTypography.caption(
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, String bookingId) {
    HapticFeedback.lightImpact();
    // Reset local unread badge — the chat screen will read from REST.
    context.read<ScheduledBookingDetailCubit>().markChatRead();
    context.pushNamed(
      'user-chat',
      pathParameters: {'bookingId': bookingId},
    );
  }
}

class _TripCard extends StatelessWidget {
  final BookingDetail detail;
  const _TripCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final whenLabel = _composeWhen(detail);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip',
            style: BrandTypography.body(weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (whenLabel != null)
            _Row(
              icon: Icons.event_rounded,
              label: 'When',
              value: whenLabel,
            ),
          if (detail.destinationName != null &&
              detail.destinationName!.isNotEmpty)
            _Row(
              icon: Icons.flag_rounded,
              label: 'Destination',
              value: detail.destinationName!,
            ),
          if (detail.destinationCity != null &&
              detail.destinationCity!.isNotEmpty)
            _Row(
              icon: Icons.location_city_rounded,
              label: 'City',
              value: detail.destinationCity!,
            ),
          if (detail.pickupLocationName.isNotEmpty)
            _Row(
              icon: Icons.my_location_rounded,
              label: 'Pickup',
              value: detail.pickupLocationName,
            ),
          if (detail.meetingPointType != null)
            _Row(
              icon: Icons.place_rounded,
              label: 'Meeting point',
              value: detail.meetingPointType!,
            ),
          _Row(
            icon: Icons.hourglass_top_rounded,
            label: 'Duration',
            value: _fmtDuration(detail.durationInMinutes),
          ),
          if (detail.requestedLanguage != null)
            _Row(
              icon: Icons.translate_rounded,
              label: 'Language',
              value: detail.requestedLanguage!.toUpperCase(),
            ),
          _Row(
            icon: Icons.group_rounded,
            label: 'Travelers',
            value: detail.travelersCount.toString(),
          ),
          if (detail.requiresCar)
            const _Row(
              icon: Icons.directions_car_rounded,
              label: 'Car',
              value: 'Required',
            ),
          if (detail.notes != null && detail.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BrandTokens.bgSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: BrandTypography.caption(weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail.notes!,
                    style: BrandTypography.caption(
                      color: BrandTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String? _composeWhen(BookingDetail d) {
    if (d.requestedDate == null) return null;
    final base = d.requestedDate!.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${months[base.month - 1]} ${base.day}, ${base.year}';
    final t = (d.startTime ?? '').padRight(5);
    final timeStr = t.length >= 5 ? t.substring(0, 5) : '';
    return timeStr.isEmpty ? dateStr : '$dateStr at $timeStr';
  }

  static String _fmtDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h hour${h == 1 ? '' : 's'}';
    return '${h}h ${m}m';
  }
}

/// Payment phase card (Fix 15). Different layouts depending on the
/// booking status surface the deposit / remaining amounts honestly.
class _PriceCard extends StatelessWidget {
  final BookingDetail detail;
  const _PriceCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrandTokens.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment',
            style: BrandTypography.body(weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ..._buildRows(detail),
          if (detail.depositForfeited)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: _SmallNotice(
                text:
                    'Your deposit was forfeited per the cancellation policy. '
                    'No further charges.',
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRows(BookingDetail d) {
    final est = d.estimatedPrice;
    final fin = d.finalPrice;
    final dep = d.depositAmount;
    final rem = d.remainingAmount;

    String fmt(double v) => '${v.toStringAsFixed(0)} EGP';

    switch (d.status) {
      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmedAwaitingPayment:
        return [
          if (est != null)
            _PriceRow(
              label: 'Estimated total',
              value: fmt(est),
              emphasize: true,
            ),
          if (dep != null)
            _PriceRow(
              label: 'Deposit due now',
              value: fmt(dep),
              tone: _PriceTone.warning,
            ),
          if (rem != null)
            _PriceRow(
              label: 'Remaining (after trip)',
              value: fmt(rem),
              tone: _PriceTone.muted,
            ),
        ];

      case BookingStatus.confirmedPaid:
      case BookingStatus.upcoming:
        return [
          if (dep != null)
            _PriceRow(
              label: 'Deposit paid \u2713',
              value: fmt(dep),
              tone: _PriceTone.success,
            ),
          if (rem != null)
            _PriceRow(
              label: 'Remaining (after trip)',
              value: fmt(rem),
              tone: _PriceTone.muted,
            ),
          if (est != null && dep == null && rem == null)
            _PriceRow(
              label: 'Estimated total',
              value: fmt(est),
              emphasize: true,
            ),
        ];

      case BookingStatus.inProgress:
        return [
          if (est != null)
            _PriceRow(
              label: 'Estimated total',
              value: fmt(est),
              emphasize: true,
            ),
          if (dep != null && d.depositPaid)
            _PriceRow(
              label: 'Deposit paid \u2713',
              value: fmt(dep),
              tone: _PriceTone.success,
            ),
          if (rem != null)
            _PriceRow(
              label: 'Remaining (after trip)',
              value: fmt(rem),
              tone: _PriceTone.muted,
            ),
        ];

      case BookingStatus.completed:
        return [
          _PriceRow(
            label: 'Final total',
            value: fmt(fin ?? est ?? 0),
            emphasize: true,
          ),
          if (dep != null)
            _PriceRow(
              label: 'Deposit paid',
              value: fmt(dep),
              tone: _PriceTone.success,
            ),
          if (rem != null)
            _PriceRow(
              label: d.remainingPaid
                  ? 'Remaining paid \u2713'
                  : 'Remaining due (cash on completion)',
              value: fmt(rem),
              tone: d.remainingPaid
                  ? _PriceTone.success
                  : _PriceTone.warning,
            ),
        ];

      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
        return [
          if (est != null)
            _PriceRow(
              label: 'Estimated total',
              value: fmt(est),
            ),
          if (dep != null && d.depositPaid && !d.depositForfeited)
            _PriceRow(
              label: 'Deposit refunded',
              value: fmt(dep),
              tone: _PriceTone.success,
            ),
          if (dep != null && d.depositForfeited)
            _PriceRow(
              label: 'Deposit forfeited',
              value: fmt(dep),
              tone: _PriceTone.danger,
            ),
        ];

      case BookingStatus.pendingHelperResponse:
      case BookingStatus.reassignmentInProgress:
      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
      case BookingStatus.waitingForUserAction:
      case BookingStatus.unknown:
        return [
          if (est != null)
            _PriceRow(
              label: 'Estimated total',
              value: fmt(est),
              emphasize: true,
            ),
          if (dep != null)
            _PriceRow(
              label: 'Deposit (after acceptance)',
              value: fmt(dep),
              tone: _PriceTone.muted,
            ),
        ];
    }
  }
}

enum _PriceTone { neutral, warning, success, muted, danger }

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final _PriceTone tone;
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.tone = _PriceTone.neutral,
  });

  Color _valueColor() {
    switch (tone) {
      case _PriceTone.success:
        return BrandTokens.successGreen;
      case _PriceTone.warning:
        return BrandTokens.accentAmberText;
      case _PriceTone.danger:
        return BrandTokens.dangerRed;
      case _PriceTone.muted:
        return BrandTokens.textSecondary;
      case _PriceTone.neutral:
        return BrandTokens.textPrimary;
    }
  }

  Color _labelColor() {
    if (tone == _PriceTone.muted) return BrandTokens.textMuted;
    return BrandTokens.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: BrandTypography.caption(color: _labelColor())),
          const Spacer(),
          Text(
            value,
            style: emphasize
                ? BrandTypography.title(
                    weight: FontWeight.w700,
                    color: _valueColor(),
                  )
                : BrandTypography.body(
                    weight: FontWeight.w600,
                    color: _valueColor(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SmallNotice extends StatelessWidget {
  final String text;
  const _SmallNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BrandTokens.dangerRedSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: BrandTokens.dangerRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: BrandTypography.caption(color: BrandTokens.dangerRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: BrandTokens.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: BrandTypography.caption()),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: BrandTypography.body(weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final BookingDetail detail;
  const _PrimaryCta({required this.detail});

  @override
  Widget build(BuildContext context) {
    switch (detail.status) {
      case BookingStatus.pendingHelperResponse:
      case BookingStatus.reassignmentInProgress:
        return GhostButton(
          label: 'Cancel booking',
          icon: Icons.close_rounded,
          color: BrandTokens.dangerRed,
          onPressed: detail.canCancel
              ? () => _runCancel(context, detail)
              : null,
        );

      case BookingStatus.declinedByHelper:
      case BookingStatus.expiredNoResponse:
      case BookingStatus.waitingForUserAction:
        return Row(
          children: [
            Expanded(
              child: GhostButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                color: BrandTokens.dangerRed,
                onPressed: detail.canCancel
                    ? () => _runCancel(context, detail)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryGradientButton(
                label: 'Pick another helper',
                icon: Icons.swap_horiz_rounded,
                onPressed: () => context.push(
                  AppRouter.scheduledAlternatives
                      .replaceFirst(':id', detail.bookingId),
                ),
              ),
            ),
          ],
        );

      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmedAwaitingPayment:
        return PrimaryGradientButton(
          label: detail.depositAmount == null
              ? 'Pay deposit'
              : 'Pay ${detail.depositAmount!.toStringAsFixed(0)} EGP deposit',
          icon: Icons.payments_rounded,
          onPressed: () => context.pushNamed(
            'payment-method',
            pathParameters: {'bookingId': detail.bookingId},
          ),
        );

      case BookingStatus.confirmedPaid:
      case BookingStatus.upcoming:
        return Row(
          children: [
            if (detail.chatEnabled)
              Expanded(
                child: GhostButton(
                  label: 'Chat',
                  icon: Icons.chat_bubble_rounded,
                  onPressed: () {
                    context
                        .read<ScheduledBookingDetailCubit>()
                        .markChatRead();
                    context.pushNamed(
                      'user-chat',
                      pathParameters: {'bookingId': detail.bookingId},
                    );
                  },
                ),
              ),
            if (detail.canCancel) ...[
              if (detail.chatEnabled) const SizedBox(width: 12),
              Expanded(
                child: GhostButton(
                  label: 'Cancel',
                  icon: Icons.close_rounded,
                  color: BrandTokens.dangerRed,
                  onPressed: () => _runCancel(context, detail),
                ),
              ),
            ],
          ],
        );

      case BookingStatus.inProgress:
        return PrimaryGradientButton(
          label: 'Open live tracking',
          icon: Icons.gps_fixed_rounded,
          onPressed: () => context.push(
            AppRouter.tripLive.replaceFirst(':id', detail.bookingId),
          ),
        );

      case BookingStatus.completed:
        // Fix 8: pair the rating CTA with the invoice CTA. The rating
        // sheet itself is responsible for tracking that the user has
        // already submitted (it queries `GET /ratings/booking/{id}` on
        // open and shows the disabled state when present).
        return Row(
          children: [
            Expanded(
              child: PrimaryGradientButton(
                label: 'Rate your helper',
                icon: Icons.star_rounded,
                onPressed: () => _openRating(context, detail.bookingId),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GhostButton(
                label: 'View invoice',
                icon: Icons.receipt_long_rounded,
                onPressed: () => context.pushNamed(
                  'user-invoice-detail',
                  pathParameters: {'bookingId': detail.bookingId},
                ),
              ),
            ),
          ],
        );

      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByHelper:
      case BookingStatus.cancelledBySystem:
      case BookingStatus.unknown:
        return const SizedBox.shrink();
    }
  }

  Future<void> _runCancel(BuildContext context, BookingDetail d) async {
    final penalty = _cancellationPenalty(d);
    final result = await SoftBottomSheet.show<CancelResult>(
      context: context,
      child: CancelBookingSheet(
        bookingId: d.bookingId,
        contextHint: penalty.contextHint,
        refundHint: penalty.refundHint,
        forfeitsDeposit: penalty.forfeitsDeposit,
      ),
    );
    if (result != null && context.mounted) {
      unawaited(
        context.read<ScheduledBookingDetailCubit>().refresh(),
      );
    }
  }

  Future<void> _openRating(BuildContext context, String bookingId) async {
    HapticFeedback.lightImpact();
    await SoftBottomSheet.show(
      context: context,
      child: RateHelperSheet(bookingId: bookingId),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        SkeletonShimmer(child: SkeletonBlock(height: 100, radius: 20)),
        SizedBox(height: 16),
        SkeletonShimmer(child: SkeletonBlock(height: 80, radius: 20)),
        SizedBox(height: 16),
        SkeletonShimmer(child: SkeletonBlock(height: 200, radius: 20)),
        SizedBox(height: 16),
        SkeletonShimmer(child: SkeletonBlock(height: 140, radius: 20)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: BrandTokens.dangerRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Couldn\u2019t load booking',
              style: BrandTypography.title(weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: BrandTypography.caption(),
            ),
            const SizedBox(height: 16),
            GhostButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
