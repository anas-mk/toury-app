import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/signalr/booking_hub_events.dart';
import '../../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../../core/widgets/hero_header.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';

/// Step 9 â€” green confirmation screen. Subscribes to `BookingTripStarted`
/// so we can push the live tracking screen when the helper begins the trip.
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

  @override
  void initState() {
    super.initState();
    _hub = sl<BookingTrackingHubService>();
    _tripStartedSub = _hub.bookingTripStartedStream
        .where((e) => e.bookingId == widget.bookingId)
        .listen(_onTripStarted);
  }

  @override
  void dispose() {
    _tripStartedSub?.cancel();
    super.dispose();
  }

  void _onTripStarted(BookingTripStartedEvent event) {
    if (!mounted) return;
    context.pushReplacement(
      AppRouter.instantTripTracking.replaceFirst(':id', widget.bookingId),
      extra: {
        'cubit': widget.cubit,
        'helper': widget.helper,
      },
    );
  }

  Future<void> _openChat() async {
    context.push(AppRouter.userChat.replaceFirst(':id', widget.bookingId));
  }

  Future<void> _openPayment() async {
    context.push(
      AppRouter.paymentMethod.replaceFirst(':bookingId', widget.bookingId),
    );
  }

  Future<void> _callHelper(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: BlocBuilder<InstantBookingCubit, InstantBookingState>(
        builder: (context, state) {
          final booking = _bookingFrom(state);
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) context.go(AppRouter.home);
            },
            child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            extendBodyBehindAppBar: true,
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: false,
                  delegate: HeroSliverHeader(
                    title: 'Helper accepted!',
                    subtitle:
                        'Your trip is confirmed. Chat with your helper or pay now.',
                    leadingIcon: Icons.check_circle_rounded,
                    height: 200,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -32),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceLG,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HelperCard(
                            booking: booking,
                            helper: widget.helper,
                            onCall: _callHelper,
                            onChat: _openChat,
                            onPay: _openPayment,
                          ),
                          if (booking != null) ...[
                            const SizedBox(height: AppTheme.spaceLG),
                            SectionTitle('Trip summary'),
                            const SizedBox(height: AppTheme.spaceSM),
                            _TripSummary(booking: booking),
                          ],
                          const SizedBox(height: AppTheme.spaceXL),
                          OutlinedButton.icon(
                            onPressed: () => context.go(AppRouter.bookingHome),
                            icon: const Icon(Icons.home_rounded),
                            label: const Text('Back to home'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusMD),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceLG),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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

class _HelperCard extends StatelessWidget {
  final BookingDetail? booking;
  final HelperSearchResult? helper;
  final void Function(String phone) onCall;
  final VoidCallback onChat;
  final VoidCallback onPay;
  const _HelperCard({
    required this.booking,
    required this.helper,
    required this.onCall,
    required this.onChat,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = booking?.helper;
    final name = summary?.fullName ?? helper?.fullName ?? 'Your helper';
    final avatar = summary?.profileImageUrl ?? helper?.profileImageUrl;
    final phone = summary?.phoneNumber;
    final paymentRequired = booking?.paymentRequired ?? false;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  AppNetworkImage(
                    imageUrl: avatar,
                    width: 64,
                    height: 64,
                    borderRadius: 32,
                  ),
                  const Positioned(
                    right: -2,
                    bottom: -2,
                    child: Icon(
                      Icons.verified_rounded,
                      color: AppColor.accentColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((phone ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phone!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColor.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.phone_rounded,
                  label: 'Call',
                  color: AppColor.secondaryColor,
                  onTap: (phone ?? '').isEmpty ? null : () => onCall(phone!),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  color: AppColor.accentColor,
                  onTap: onChat,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSM),
              Expanded(
                child: _ActionButton(
                  icon: Icons.payment_rounded,
                  label: 'Pay',
                  color: AppColor.warningColor,
                  highlighted: paymentRequired,
                  onTap: onPay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool highlighted;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: highlighted ? color : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
          child: Opacity(
            opacity: disabled ? 0.4 : 1,
            child: Column(
              children: [
                Icon(
                  icon,
                  color: highlighted ? Colors.white : color,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: highlighted ? Colors.white : color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripSummary extends StatelessWidget {
  final BookingDetail booking;
  const _TripSummary({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(
            theme,
            Icons.trip_origin_rounded,
            AppColor.accentColor,
            'Pickup',
            booking.pickupLocationName,
          ),
          if ((booking.destinationName ?? '').isNotEmpty)
            _line(
              theme,
              Icons.flag_rounded,
              AppColor.errorColor,
              'Destination',
              booking.destinationName!,
            ),
          _line(
            theme,
            Icons.schedule_rounded,
            AppColor.secondaryColor,
            'Duration',
            '${booking.durationInMinutes} minutes',
          ),
          _line(
            theme,
            Icons.group_rounded,
            AppColor.accentColor,
            'Travelers',
            '${booking.travelersCount}',
          ),
          if (booking.estimatedPrice != null)
            _line(
              theme,
              Icons.payments_rounded,
              AppColor.warningColor,
              'Estimated',
              'EGP ${booking.estimatedPrice!.toStringAsFixed(0)}',
            ),
        ],
      ),
    );
  }

  Widget _line(
    ThemeData theme,
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColor.lightTextSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
