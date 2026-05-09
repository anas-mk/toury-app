import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/realtime/app_realtime_cubit.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/utils/number_format.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/booking_status.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../scheduled/cancel_booking_sheet.dart';

/// Step 7 — "Looking for your helper" (Pass #6 — 2026 editorial redesign).
///
/// Cinematic radar UI matching the new RAFIQ design:
///   • Subtle tonal gradient background (primary-fixed → surface).
///   • "LIVE SEARCH" pill with a pulsing red dot.
///   • Big editorial display headline.
///   • Concentric tonal rings (3 layers) + central avatar plate.
///   • Floating amber timer pill anchored to the radar bottom.
///   • 3-stage progression bar (Searching → Waiting → Confirm) with
///     an animated active line that grows as the booking advances.
///   • Minimalist "CANCEL SEARCH" text link (instead of a heavy
///     outlined danger button).
///
/// Behaviour:
///   • System back / on-screen back routes the user to the tourist
///     home (`AppRouter.home`) instead of the previous screen — a
///     pending instant booking should never bounce back into the
///     "Find a Helper" wizard.
///   • Cancel uses the editorial [CancelBookingSheet] (same widget
///     the Scheduled flow uses), wired to
///     [InstantBookingCubit.cancelBooking] so the API contract stays
///     consistent.
///   • Routing on state change is unchanged: accepted → confirmed,
///     declined → alternatives, cancelled → home.
class WaitingForHelperPage extends StatefulWidget {
  final InstantBookingCubit cubit;
  final String bookingId;
  final HelperSearchResult? helper;

  const WaitingForHelperPage({
    super.key,
    required this.cubit,
    required this.bookingId,
    this.helper,
  });

  @override
  State<WaitingForHelperPage> createState() => _WaitingForHelperPageState();
}

class _WaitingForHelperPageState extends State<WaitingForHelperPage> {
  Timer? _ticker;
  StreamSubscription<InstantBookingState>? _stateSub;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    if (state is InstantBookingCreated) {
      widget.cubit.startWatchingExisting(widget.bookingId);
    } else if (state is InstantBookingWaiting) {
      // Already watching; nothing to do.
    } else {
      widget.cubit.startWatchingExisting(widget.bookingId);
    }
    // Listen to cubit transitions so we update the countdown the
    // instant the booking is hydrated (i.e. the moment we navigate
    // here from the home banner) rather than waiting up to 1 s for
    // the next periodic tick — which is the difference between "a
    // timer appears" vs. "no timer at all" on first paint.
    _stateSub = widget.cubit.stream.listen((_) => _recomputeRemaining());
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    // Run once immediately so we don't show 00:00 for a full second
    // when the cubit already has a hydrated booking on initState
    // (very common when the user lands here via deep-link).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recomputeRemaining();
    });
  }

  /// Default window the helper has to respond before the assignment
  /// expires. Used as a last-resort fallback when the backend payload
  /// includes neither `responseDeadline` nor a `currentAssignment`
  /// with `expiresAt`/`sentAt` so the timer still ticks down and the
  /// user gets a sense of progress instead of staring at a frozen
  /// radar with no countdown.
  static const Duration _defaultResponseWindow = Duration(minutes: 5);

  /// Computes the live countdown deadline from a booking detail.
  ///
  /// Backend payloads come from two different endpoints (the create
  /// `POST` response vs. the get-detail `GET` used on hydrate from
  /// the home banner) and they don't all expose the same fields. We
  /// try every reasonable signal in order:
  ///
  ///   1. `booking.responseDeadline` — top-level, set by `POST`.
  ///   2. `currentAssignment.expiresAt` — per-attempt deadline,
  ///      always present on `GET` while the helper still has the
  ///      request.
  ///   3. `currentAssignment.sentAt` + 5 min — derived from when the
  ///      attempt was dispatched.
  ///   4. `booking.createdAt` + 5 min — last resort for very old or
  ///      partially-populated payloads.
  static DateTime? _resolveDeadline(BookingDetail booking) {
    if (booking.responseDeadline != null) {
      return booking.responseDeadline;
    }
    final assignment = booking.currentAssignment;
    if (assignment?.expiresAt != null) {
      return assignment!.expiresAt;
    }
    if (assignment?.sentAt != null) {
      return assignment!.sentAt!.add(_defaultResponseWindow);
    }
    if (booking.createdAt != null) {
      return booking.createdAt!.add(_defaultResponseWindow);
    }
    return null;
  }

  void _onTick(Timer _) => _recomputeRemaining();

  /// Pulls the freshest deadline off the cubit, runs the fallback
  /// chain, and pushes the new countdown into state. Called from the
  /// 1 s ticker, from the cubit's state stream, and once on first
  /// frame so the timer is correct from the very first paint.
  void _recomputeRemaining() {
    if (!mounted) return;
    final state = widget.cubit.state;
    BookingDetail? booking;
    if (state is InstantBookingWaiting) {
      booking = state.booking;
    } else if (state is InstantBookingCreated) {
      booking = state.booking;
    }
    if (booking == null) {
      if (_remaining != Duration.zero) {
        setState(() => _remaining = Duration.zero);
      }
      return;
    }

    final deadline = _resolveDeadline(booking);
    if (deadline == null) {
      if (_remaining != Duration.zero) {
        setState(() => _remaining = Duration.zero);
      }
      return;
    }
    final diff = deadline.toUtc().difference(DateTime.now().toUtc());
    final next = diff.isNegative ? Duration.zero : diff;
    if (next != _remaining) {
      setState(() => _remaining = next);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  /// Routes back to the tourist home after a successful cancel or
  /// when the user presses system back. Using `go` (not `pop`) so
  /// the navigation stack is rebuilt cleanly — leaving the user at
  /// home with no "in-flight booking" screens still on the stack.
  ///
  /// Also nudges the home-level cubits to re-fetch so the active
  /// banner / recents list reflect any change (newly created booking
  /// the user is just leaving the radar of, or a fresh cancel).
  void _goHome() {
    if (!mounted) return;
    sl<AppRealtimeCubit>().notifyBookingCreated(widget.bookingId);
    context.go(AppRouter.home);
  }

  Future<void> _onCancel(BuildContext ctx) async {
    HapticFeedback.selectionClick();
    // We deliberately avoid `SoftBottomSheet.show` here because that
    // widget renders the brand-wide wavy top edge (BlobClipper). On
    // a confirmation sheet that style competes with the Cancel
    // intent and feels noisy. A clean rounded modal — same drag
    // handle but a flat top — reads better and matches the
    // editorial design system in the rest of this flow.
    final result = await showModalBottomSheet<CancelResult>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CleanSheetWrapper(
        child: CancelBookingSheet(
          bookingId: widget.bookingId,
          contextHint:
              'Your helper hasn\u2019t responded yet, so you can cancel '
              'with no penalty.',
        ),
      ),
    );
    // The [CancelBookingSheet] uses its own [CancelBookingCubit] and
    // returns a [CancelResult] when the API confirms. We mirror that
    // outcome into the InstantBookingCubit so any other listener
    // (e.g. the helpers list) sees a consistent terminal state.
    if (result == null || !mounted) return;
    unawaited(
      widget.cubit.cancelBooking(widget.bookingId, result.reason),
    );
    _goHome();
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  /// Stage `0` = Searching, `1` = Waiting, `2` = Confirm.
  /// Used to drive the active line + circle styles in the timeline.
  int _stageFromState(InstantBookingState state, BookingDetail? booking) {
    if (state is InstantBookingAccepted) return 2;
    if (booking != null) {
      switch (booking.status) {
        case BookingStatus.acceptedByHelper:
        case BookingStatus.confirmedAwaitingPayment:
        case BookingStatus.confirmedPaid:
        case BookingStatus.upcoming:
        case BookingStatus.inProgress:
          return 2;
        case BookingStatus.pendingHelperResponse:
          // Once a helper is actually assigned (we got a name), bump
          // forward to "Waiting" so the user feels progress instead
          // of staring at the same "Searching" stage forever.
          if (booking.currentAssignment?.helperName != null ||
              widget.helper != null) {
            return 1;
          }
          return 0;
        default:
          return 0;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocConsumer<InstantBookingCubit, InstantBookingState>(
        listener: _onState,
        builder: (context, state) {
          final booking = _bookingFrom(state);
          final helperName =
              booking?.currentAssignment?.helperName ?? widget.helper?.fullName;
          final helperAvatar = widget.helper?.profileImageUrl ??
              booking?.helper?.profileImageUrl;
          final attempt = booking?.assignmentAttemptCount ?? 0;
          final stage = _stageFromState(state, booking);

          return PopScope(
            // System back / gesture back → go home cleanly. Returning
            // `false` here makes Flutter NOT pop the route automatically
            // because we handle navigation ourselves in `onPopInvoked`.
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              _goHome();
            },
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
              child: Scaffold(
                backgroundColor: const Color(0xFFFBF8FF),
                body: Stack(
                  children: [
                    const Positioned.fill(child: _AmbientGradient()),
                    SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Adaptive layout: every fixed-height piece
                          // shrinks on short screens so the whole page
                          // fits in one viewport (no scroll, the
                          // cancel link is always one finger-tap away).
                          final h = constraints.maxHeight;
                          final small = h < 760;
                          final tiny = h < 660;
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              tiny ? 8 : (small ? 12 : 20),
                              24,
                              tiny ? 12 : 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                    height: tiny ? 0 : (small ? 4 : 8)),
                                const _LiveSearchBadge(),
                                SizedBox(
                                    height:
                                        tiny ? 14 : (small ? 20 : 28)),
                                _Heading(
                                  title: helperName == null
                                      ? 'Looking for your helper'
                                      : 'Waiting for $helperName',
                                  subtitle: helperName == null
                                      ? 'Matching you with the nearest expert\u2026'
                                      : 'Your request is live and we\u2019re '
                                          'tracking responses in realtime.',
                                  compact: small,
                                ),
                                // Flexible space — the radar floats in
                                // the centre between the heading and
                                // the stage card, so on tall screens
                                // the layout stays balanced and on
                                // short screens we hand any extra
                                // pixels to the radar without wasting
                                // them on top/bottom margins.
                                Expanded(
                                  child: Center(
                                    child: _Radar(
                                      avatarUrl: helperAvatar,
                                      remaining: _remaining,
                                      formatRemaining: _formatRemaining,
                                      compact: small,
                                      tiny: tiny,
                                    ),
                                  ),
                                ),
                                _StageCard(stage: stage, compact: small),
                                if (attempt > 1) ...[
                                  const SizedBox(height: 12),
                                  _AttemptBadge(attempt: attempt),
                                ],
                                SizedBox(
                                    height:
                                        tiny ? 14 : (small ? 18 : 22)),
                                _CancelLink(
                                  onTap: () => _onCancel(context),
                                ),
                                SizedBox(height: tiny ? 0 : 4),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  BookingDetail? _bookingFrom(InstantBookingState s) {
    if (s is InstantBookingWaiting) return s.booking;
    if (s is InstantBookingCreated) return s.booking;
    if (s is InstantBookingAccepted) return s.booking;
    if (s is InstantBookingDeclined) return s.booking;
    return null;
  }

  void _onState(BuildContext context, InstantBookingState state) {
    if (state is InstantBookingAccepted) {
      context.go(
        AppRouter.instantConfirmed.replaceFirst(':id', state.booking.bookingId),
        extra: {'cubit': widget.cubit, 'helper': widget.helper},
      );
    } else if (state is InstantBookingDeclined) {
      context.pushReplacement(
        AppRouter.instantAlternatives.replaceFirst(
          ':id',
          state.booking.bookingId,
        ),
        extra: {
          'cubit': widget.cubit,
          'booking': state.booking,
          'alternatives': state.alternatives,
        },
      );
    } else if (state is InstantBookingCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request cancelled: ${state.reason}')),
      );
      _goHome();
    } else if (state is InstantBookingError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColor.errorColor,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient gradient — subtle blue → cream tonal layering behind everything.
// ─────────────────────────────────────────────────────────────────────────────

class _AmbientGradient extends StatelessWidget {
  const _AmbientGradient();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE0E0FF).withValues(alpha: 0.45),
              const Color(0xFFFBF8FF),
              const Color(0xFFFBF8FF),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "LIVE SEARCH" badge with pulsing red dot.
// ─────────────────────────────────────────────────────────────────────────────

class _LiveSearchBadge extends StatefulWidget {
  const _LiveSearchBadge();

  @override
  State<_LiveSearchBadge> createState() => _LiveSearchBadgeState();
}

class _LiveSearchBadgeState extends State<_LiveSearchBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: const Color(0xFFC6C5D4).withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final t = _ctrl.value;
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFBA1A1A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBA1A1A).withValues(
                        alpha: 0.45 * (1 - t),
                      ),
                      blurRadius: 6 + 6 * t,
                      spreadRadius: 1 + 2 * t,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Text(
            'LIVE SEARCH',
            style: BrandTokens.heading(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: BrandTokens.textPrimary,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Heading + subtitle.
// ─────────────────────────────────────────────────────────────────────────────

class _Heading extends StatelessWidget {
  final String title;
  final String subtitle;

  /// `true` on small phones — shrinks the type and tightens spacing
  /// so the heading + radar still fit above the fold without
  /// overflowing.
  final bool compact;
  const _Heading({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: BrandTokens.heading(
            fontSize: compact ? 28 : 36,
            fontWeight: FontWeight.w800,
            color: BrandTokens.primaryBlue,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF464652),
            fontSize: compact ? 14 : 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cinematic radar (3 concentric rings + animated pulse + central avatar +
// floating amber timer pill).
// ─────────────────────────────────────────────────────────────────────────────

class _Radar extends StatefulWidget {
  final String? avatarUrl;
  final Duration remaining;
  final String Function(Duration) formatRemaining;

  /// `true` on small phones — uses a smaller outer ring (240 instead
  /// of 288) so the radar plus the floating timer pill still fit
  /// next to the heading and stage card without overflowing.
  final bool compact;

  /// `true` on very short phones (<660 px) — radar shrinks further so
  /// the cancel link still fits above the system bar.
  final bool tiny;

  const _Radar({
    required this.avatarUrl,
    required this.remaining,
    required this.formatRemaining,
    this.compact = false,
    this.tiny = false,
  });

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The parent `Expanded → Center` hands us the available
        // square. We pick the smaller of the two axes minus a buffer
        // for the timer pill, then clamp into a sensible range so
        // the radar never gets absurdly tiny or oversized.
        final ideal = widget.tiny
            ? 220.0
            : (widget.compact ? 256.0 : 288.0);
        final maxByHeight = (constraints.maxHeight - 24).clamp(180.0, ideal);
        final maxByWidth = constraints.maxWidth.clamp(180.0, ideal);
        final outer =
            (maxByHeight < maxByWidth ? maxByHeight : maxByWidth).toDouble();
        final mid = outer * (240 / 288);
        final inner = outer * (192 / 288);
        final avatarSize = outer * (96 / 288);
        final pulseStart = outer * (120 / 288);
        final pulseGrow = outer * (160 / 288);

        return SizedBox(
          width: outer,
          // 24 px buffer beneath the ring so the floating amber timer
          // pill (positioned at `bottom: -16`) is never clipped.
          height: outer + 24,
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: outer,
                height: outer,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    _ConcentricRing(
                      size: outer,
                      color: BrandTokens.primaryBlue.withValues(alpha: 0.05),
                    ),
                    _ConcentricRing(
                      size: mid,
                      color: BrandTokens.primaryBlue.withValues(alpha: 0.10),
                    ),
                    _ConcentricRing(
                      size: inner,
                      color: BrandTokens.primaryBlue.withValues(alpha: 0.18),
                      fill: BrandTokens.primaryBlue.withValues(alpha: 0.05),
                    ),
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final t1 = _pulseCtrl.value;
                        final t2 = (_pulseCtrl.value + 0.5) % 1.0;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            _PulseDot(
                              progress: t1,
                              startSize: pulseStart,
                              maxAdd: pulseGrow,
                            ),
                            _PulseDot(
                              progress: t2,
                              startSize: pulseStart,
                              maxAdd: pulseGrow,
                            ),
                          ],
                        );
                      },
                    ),
                    _AvatarPlate(
                      avatarUrl: widget.avatarUrl,
                      size: avatarSize,
                    ),
                    if (widget.remaining > Duration.zero)
                      Positioned(
                        bottom: -16,
                        child: _TimerPill(
                          text: widget.formatRemaining(widget.remaining),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConcentricRing extends StatelessWidget {
  final double size;
  final Color color;
  final Color? fill;
  const _ConcentricRing({
    required this.size,
    required this.color,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: color, width: 1),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  /// 0..1 — how far along the pulse animation we are.
  final double progress;
  final double startSize;
  final double maxAdd;
  const _PulseDot({
    required this.progress,
    this.startSize = 120,
    this.maxAdd = 160,
  });

  @override
  Widget build(BuildContext context) {
    final size = startSize + maxAdd * progress;
    final opacity = (1 - progress).clamp(0.0, 1.0) * 0.35;
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: BrandTokens.primaryBlue.withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _AvatarPlate extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  const _AvatarPlate({required this.avatarUrl, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final innerSize = size - 8;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: BrandTokens.primaryBlue.withValues(alpha: 0.16),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl == null || avatarUrl!.isEmpty
            ? Center(
                child: Icon(
                  Icons.person_rounded,
                  color: BrandTokens.primaryBlue,
                  size: size * 0.42,
                ),
              )
            : AppNetworkImage(
                imageUrl: avatarUrl,
                width: innerSize,
                height: innerSize,
                borderRadius: innerSize / 2,
              ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final String text;
  const _TimerPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFE9331),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFE9331).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          // `Directionality.ltr` ensures the timer always reads left-to-
          // right (`12:34`) even in RTL locales — flipping it would
          // turn `01:45` into a confusing reverse string.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              context.localizeDigits(text),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3-Stage progression card (Searching → Waiting → Confirm).
//
// The active connecting line "fills up" between stages as the booking
// advances. Stage 0 = 0%, stage 1 = 50%, stage 2 = 100%.
// ─────────────────────────────────────────────────────────────────────────────

class _StageCard extends StatelessWidget {
  /// `0` Searching, `1` Waiting, `2` Confirm.
  final int stage;
  final bool compact;
  const _StageCard({required this.stage, this.compact = false});

  double get _progress => switch (stage) {
        2 => 1.0,
        1 => 0.5,
        _ => 0.0,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        compact ? 14 : 20,
        24,
        compact ? 14 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4E1EA).withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: BrandTokens.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -10,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Padding inside the card is 24 left + 24 right. The line
          // should run from the centre of the first circle to the
          // centre of the last circle — i.e. `circleRadius` from each
          // edge of the available width.
          final circleSize = compact ? 36.0 : 40.0;
          final circleRadius = circleSize / 2;
          final totalWidth = constraints.maxWidth;
          final lineWidth = totalWidth - circleSize;
          return SizedBox(
            height: compact ? 70 : 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Base line (gray).
                Positioned(
                  left: circleRadius,
                  right: circleRadius,
                  top: circleRadius - 1,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4E1EA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Animated active progress line (primary blue).
                Positioned(
                  left: circleRadius,
                  top: circleRadius - 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 480),
                    curve: Curves.easeOutCubic,
                    height: 2,
                    width: lineWidth * _progress,
                    decoration: BoxDecoration(
                      color: BrandTokens.primaryBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Three stage circles + labels, equally spaced.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StageDot(
                      icon: Icons.search_rounded,
                      label: 'Searching',
                      active: stage >= 0,
                      filled: stage >= 0,
                      size: circleSize,
                    ),
                    _StageDot(
                      icon: Icons.hourglass_empty_rounded,
                      label: 'Waiting',
                      active: stage >= 1,
                      filled: stage >= 1,
                      size: circleSize,
                    ),
                    _StageDot(
                      icon: Icons.check_rounded,
                      label: 'Confirm',
                      active: stage >= 2,
                      filled: stage >= 2,
                      size: circleSize,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool filled;
  final double size;
  const _StageDot({
    required this.icon,
    required this.label,
    required this.active,
    required this.filled,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final accent = BrandTokens.primaryBlue;
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: filled ? accent : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: filled ? accent : const Color(0xFFE4E1EA),
                width: 2,
              ),
              boxShadow: filled
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: filled
                  ? Colors.white
                  : (active ? accent : const Color(0xFF767683)),
              size: size * 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? accent : const Color(0xFF767683),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attempt badge (shown when assignmentAttemptCount > 1).
// ─────────────────────────────────────────────────────────────────────────────

class _AttemptBadge extends StatelessWidget {
  final int attempt;
  const _AttemptBadge({required this.attempt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: BrandTokens.warningAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: BrandTokens.warningAmber.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.refresh_rounded,
            size: 14,
            color: BrandTokens.warningAmber,
          ),
          const SizedBox(width: 6),
          Text(
            'Attempt ${context.localizeNumber(attempt)}',
            style: const TextStyle(
              color: BrandTokens.warningAmber,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Minimalist text-only "CANCEL SEARCH" link with hover-style underline.
// ─────────────────────────────────────────────────────────────────────────────

class _CancelLink extends StatefulWidget {
  final VoidCallback onTap;
  const _CancelLink({required this.onTap});

  @override
  State<_CancelLink> createState() => _CancelLinkState();
}

class _CancelLinkState extends State<_CancelLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? const Color(0xFFBA1A1A) : const Color(0xFF464652);
    return GestureDetector(
      onTapDown: (_) => setState(() => _hover = true),
      onTapCancel: () => setState(() => _hover = false),
      onTapUp: (_) => setState(() => _hover = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _hover ? const Color(0xFFBA1A1A) : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
          child: const Text('CANCEL SEARCH'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clean rounded modal sheet wrapper — replacement for the brand-wide
// `SoftBottomSheet` whose blob clipper looks too playful on a Cancel
// confirmation. Top corners are rounded 28 px, drag handle sits at the
// top, content slots in below.
// ─────────────────────────────────────────────────────────────────────────────

class _CleanSheetWrapper extends StatelessWidget {
  final Widget child;
  const _CleanSheetWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A1B237E),
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle.
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 12),
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6C5D4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
