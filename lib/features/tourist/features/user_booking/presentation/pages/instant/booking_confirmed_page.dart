import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/location/last_helper_location_store.dart';
import '../../../../../../../core/services/signalr/booking_hub_events.dart';
import '../../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/utils/number_format.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../user_chat/presentation/widgets/unread_chat_badge.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';

/// Step 9 — "Helper accepted" confirmation screen (Pass #6 — 2026
/// editorial redesign).
///
/// Cream surface, large success badge, helper mini card with online
/// status + call shortcut, a vertical Trip Summary timeline, and
/// two stacked rounded CTAs (Track Live / Open Chat).
///
/// Behaviour:
///   • Subscribes to `BookingTripStarted` so the moment the helper
///     starts the trip we push the live tracking screen.
///   • Hydrates the cubit on deep-link entry (home banner) so the
///     helper avatar / pickup / destination populate without the
///     screen flickering through an empty state.
///   • System / on-screen back goes to the tourist home cleanly.
class BookingConfirmedPage extends StatefulWidget {
  final InstantBookingCubit cubit;
  final String bookingId;
  final HelperSearchResult? helper;

  const BookingConfirmedPage({
    super.key,
    required this.cubit,
    required this.bookingId,
    this.helper,
  });

  @override
  State<BookingConfirmedPage> createState() => _BookingConfirmedPageState();
}

class _BookingConfirmedPageState extends State<BookingConfirmedPage> {
  late final BookingTrackingHubService _hub;
  StreamSubscription<BookingTripStartedEvent>? _tripStartedSub;
  StreamSubscription<HelperLocationUpdateEvent>? _helperLocationSub;

  /// Latest realtime helper location for this booking. Drives the
  /// "ETA · N min away" subtitle on the helper card so the page
  /// stops being a static "On the way · ETA soon" billboard.
  HelperLocationUpdateEvent? _latestLocation;

  @override
  void initState() {
    super.initState();
    _hub = sl<BookingTrackingHubService>();
    _tripStartedSub = _hub.bookingTripStartedStream
        .where((e) => e.bookingId == widget.bookingId)
        .listen(_onTripStarted);
    // Listen for live GPS so the "ETA · N min" subtitle on the
    // helper card actually reflects what the server pushes. Per the
    // backend confirmation (2026-05-09), broadcasts already start
    // the moment the helper accepts — we don't need to wait for
    // `BookingTripStarted` here.
    _helperLocationSub = _hub.helperLocationUpdateStream
        .where((e) => e.bookingId == widget.bookingId)
        .listen((event) {
      if (!mounted) return;
      setState(() => _latestLocation = event);
      // Mirror the live tick to the persistent cache so when the
      // user pops to live track the marker shows up on first paint
      // even if the realtime stream hasn't ticked since.
      LastHelperLocationStore.instance.save(LastHelperLocation(
        bookingId: widget.bookingId,
        latitude: event.latitude,
        longitude: event.longitude,
        heading: event.heading,
        speedKmh: event.speedKmh,
        etaToPickupMinutes: event.etaToPickupMinutes,
        etaToDestinationMinutes: event.etaToDestinationMinutes,
        phase: event.phase,
        capturedAt: event.capturedAt ?? DateTime.now().toUtc(),
      ));
    });
    // Hydrate the cubit when the user lands here via deep-link from
    // the home banner — no cubit history yet, so we kick a fetch.
    final state = widget.cubit.state;
    if (state is! InstantBookingAccepted &&
        state is! InstantBookingWaiting &&
        state is! InstantBookingDeclined) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.cubit.hydrateForTripDeepLink(widget.bookingId);
      });
    }
    // Replay the last cached location so the ETA chip has something
    // sensible to show on first paint, even before SignalR ticks.
    _hydrateFromCache();
  }

  /// Soft fallback: paint the freshest cached location while we
  /// wait for SignalR to push something newer. Best-effort — the
  /// live stream always wins once it kicks in.
  Future<void> _hydrateFromCache() async {
    final cached =
        await LastHelperLocationStore.instance.load(widget.bookingId);
    if (!mounted || cached == null || _latestLocation != null) return;
    // Synthesise a HelperLocationUpdateEvent shape from the stored
    // snapshot — only the fields the UI reads from `_statusText()`
    // matter (phase + etaTo*), so the rest can stay null.
    setState(() {
      _latestLocation = HelperLocationUpdateEvent(
        eventId: 'cache::${cached.bookingId}',
        bookingId: cached.bookingId,
        latitude: cached.latitude,
        longitude: cached.longitude,
        etaToPickupMinutes: cached.etaToPickupMinutes,
        etaToDestinationMinutes: cached.etaToDestinationMinutes,
        phase: cached.phase,
        capturedAt: cached.capturedAt,
      );
    });
  }

  @override
  void dispose() {
    _tripStartedSub?.cancel();
    _helperLocationSub?.cancel();
    super.dispose();
  }

  void _onTripStarted(BookingTripStartedEvent event) {
    if (!mounted) return;
    context.pushReplacement(
      AppRouter.instantTripTracking.replaceFirst(':id', widget.bookingId),
      extra: {'cubit': widget.cubit, 'helper': widget.helper},
    );
  }

  void _openChat() {
    HapticFeedback.selectionClick();
    context.push(AppRouter.userChat.replaceFirst(':id', widget.bookingId));
  }

  void _openTrackLive() {
    HapticFeedback.mediumImpact();
    context.push(
      AppRouter.instantTripTracking.replaceFirst(':id', widget.bookingId),
      extra: {'cubit': widget.cubit, 'helper': widget.helper},
    );
  }

  Future<void> _callHelper(String phone) async {
    HapticFeedback.selectionClick();
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  void _goHome() {
    if (!mounted) return;
    context.go(AppRouter.home);
  }

  /// Friendly status copy for the helper card — reflects the
  /// freshest realtime helper position when we have one.
  ///
  /// Kept deliberately short ("ETA 13 min" is < 12 characters) so the
  /// label always fits on a single line next to a 64 px avatar and a
  /// 44 px call button on average phone widths. Anything longer made
  /// the line truncate to "ETA 13 ..." which read like a bug.
  ///
  /// Backend semantics:
  ///   - `phase == "InProgress"` → trip is live, helper heading to
  ///     destination (we'll be on the live-track screen by then,
  ///     since `BookingTripStarted` pushes us there).
  ///   - any other phase + present `etaToPickupMinutes` → helper is
  ///     en route to the pickup point.
  ///   - no realtime sample yet → "Heading your way" placeholder.
  String _statusText() {
    final loc = _latestLocation;
    if (loc == null) return 'Heading your way';
    // Stale-data label — if the captured timestamp is older than
    // ~90 s we treat the line as a "last seen" indicator instead
    // of a fresh ETA (covers the GPS-disconnect case the user
    // explicitly asked for).
    final captured = loc.capturedAt;
    final ageSeconds = captured == null
        ? 0
        : DateTime.now().toUtc().difference(captured.toUtc()).inSeconds;
    final isStale = ageSeconds >= 90;
    final phase = loc.phase;
    final eta = phase == 'InProgress'
        ? loc.etaToDestinationMinutes
        : loc.etaToPickupMinutes;
    if (isStale) {
      final minutesAgo = (ageSeconds / 60).round();
      if (minutesAgo <= 0) return 'Last seen just now';
      return 'Last seen ${context.localizeNumber(minutesAgo)} min ago';
    }
    if (eta == null || eta < 0) return 'On the way';
    if (eta == 0) return 'Arriving now';
    return 'ETA ${context.localizeNumber(eta)} min';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<InstantBookingCubit, InstantBookingState>(
        builder: (context, state) {
          final booking = _bookingFrom(state);
          final summary = booking?.helper;
          final firstName = (summary?.fullName ?? widget.helper?.fullName ?? '')
              .split(' ')
              .first;
          final displayName = firstName.isEmpty ? 'Your helper' : firstName;
          final phone = summary?.phoneNumber;
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _goHome();
            },
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
              child: Scaffold(
                backgroundColor: const Color(0xFFFBF8FF),
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  24, 12, 24, 24),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 24),
                                  _SuccessHeader(name: displayName),
                                  const SizedBox(height: 28),
                                  _HelperCard(
                                    name: displayName,
                                    avatarUrl: summary?.profileImageUrl ??
                                        widget.helper?.profileImageUrl,
                                    statusText: _statusText(),
                                    canCall: (phone ?? '').isNotEmpty,
                                    onCall: () =>
                                        _callHelper(phone ?? ''),
                                  ),
                                  const SizedBox(height: 28),
                                  _TripSummary(booking: booking),
                                  const Spacer(),
                                  const SizedBox(height: 24),
                                  _PrimaryCta(
                                    icon: Icons.location_on_rounded,
                                    label: 'Track Live',
                                    onTap: _openTrackLive,
                                  ),
                                  const SizedBox(height: 12),
                                  // Wrap with the unread badge so a red
                                  // dot / counter sits on the chat icon
                                  // whenever the helper sends a message
                                  // we haven't read yet (replaces a real
                                  // notification until FCM badging ships).
                                  UnreadChatBadge(
                                    bookingId: widget.bookingId,
                                    offset: const Offset(-12, 6),
                                    child: _SecondaryCta(
                                      icon: Icons.chat_bubble_outline_rounded,
                                      label: 'Open Chat',
                                      onTap: _openChat,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  BookingDetail? _bookingFrom(InstantBookingState s) {
    if (s is InstantBookingAccepted) return s.booking;
    if (s is InstantBookingWaiting) return s.booking;
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Success header (animated check badge + headline + subtitle).
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessHeader extends StatefulWidget {
  final String name;
  const _SuccessHeader({required this.name});

  @override
  State<_SuccessHeader> createState() => _SuccessHeaderState();
}

class _SuccessHeaderState extends State<_SuccessHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = Curves.elasticOut.transform(_ctrl.value);
            return Transform.scale(
              scale: 0.5 + 0.5 * t,
              child: Opacity(
                opacity: _ctrl.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            BrandTokens.primaryBlue.withValues(alpha: 0.10),
                        blurRadius: 30,
                        spreadRadius: -8,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: BrandTokens.primaryBlue,
                    size: 40,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          '${widget.name} confirmed!',
          textAlign: TextAlign.center,
          style: BrandTokens.heading(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: BrandTokens.primaryBlue,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Your local expert is preparing for your journey. '
            'Get ready for an unforgettable experience.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF464652),
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper card (avatar + name + status pill + call button).
// ─────────────────────────────────────────────────────────────────────────────

class _HelperCard extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String statusText;
  final bool canCall;
  final VoidCallback onCall;

  const _HelperCard({
    required this.name,
    required this.avatarUrl,
    required this.statusText,
    required this.canCall,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4E1EA).withValues(alpha: 0.7),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: AppNetworkImage(
              imageUrl: avatarUrl,
              width: 64,
              height: 64,
              borderRadius: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTokens.heading(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BrandTokens.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Wrap so the dot + label can flow to a second line
                // gracefully if the localized ETA copy ever grows
                // beyond the available width — instead of being
                // truncated mid-word as "ETA 13 ...".
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const _StatusDot(),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Color(0xFF924C00),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _IconCircleButton(
            icon: Icons.call_rounded,
            background: const Color(0xFFEFECF5),
            iconColor: canCall ? BrandTokens.primaryBlue : const Color(0xFFC6C5D4),
            onTap: canCall ? onCall : null,
            tooltip: 'Call helper',
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot();

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
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
        final t = _ctrl.value;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFFE9331),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFE9331).withValues(alpha: 0.45 * (1 - t)),
                blurRadius: 4 + 4 * t,
                spreadRadius: 1 + t,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? tooltip;
  const _IconCircleButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vertical timeline trip summary (Pickup • Destination • Duration).
// ─────────────────────────────────────────────────────────────────────────────

class _TripSummary extends StatelessWidget {
  final BookingDetail? booking;
  const _TripSummary({required this.booking});

  String _formatDuration(BuildContext context, int m) {
    if (m % 60 == 0) {
      final h = m ~/ 60;
      return h == 1
          ? '${context.localizeNumber(h)} hour'
          : '${context.localizeNumber(h)} hours';
    }
    return '${context.localizeNumber(m ~/ 60)}h ${context.localizeNumber(m % 60)}m';
  }

  @override
  Widget build(BuildContext context) {
    final pickup = booking?.pickupLocationName ?? '—';
    final destination = booking?.destinationName ?? '—';
    final duration = booking == null
        ? '—'
        : _formatDuration(context, booking!.durationInMinutes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRIP SUMMARY',
            style: TextStyle(
              color: const Color(0xFF767683),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          _TimelineRow(
            color: BrandTokens.primaryBlue,
            label: 'Pickup',
            value: pickup,
            isFirst: true,
          ),
          _TimelineRow(
            color: const Color(0xFF924C00),
            label: 'Destination',
            value: destination,
          ),
          _TimelineRow(
            color: const Color(0xFF767683),
            label: 'Estimated Duration',
            value: duration,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _TimelineRow({
    required this.color,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail (dot + connecting line above/below).
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Vertical line — full height except the gap around
                // the dot. We render it in two halves so we can
                // suppress the top half on first row and the bottom
                // half on the last row, giving a clean timeline.
                Positioned(
                  top: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      width: 2,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE4E1EA),
                      ),
                    ),
                  ),
                ),
                if (isFirst)
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 2,
                      height: 12,
                      color: const Color(0xFFFBF8FF),
                    ),
                  ),
                if (isLast)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 2,
                      height: 12,
                      color: const Color(0xFFFBF8FF),
                    ),
                  ),
                // Coloured dot.
                Positioned(
                  top: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFBF8FF),
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF767683),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF1B1B21),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTAs (filled primary "Track Live" + outlined "Open Chat").
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryCta extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryCta({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PrimaryCta> createState() => _PrimaryCtaState();
}

class _PrimaryCtaState extends State<_PrimaryCta> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: BrandTokens.primaryBlue,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryCta extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SecondaryCta({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: const Color(0xFFC6C5D4),
              width: 1.4,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: BrandTokens.primaryBlue, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: BrandTokens.primaryBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
