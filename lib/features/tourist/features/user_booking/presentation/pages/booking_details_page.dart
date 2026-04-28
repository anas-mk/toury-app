import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../core/widgets/brand/mesh_gradient.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../cubits/booking_status_cubit.dart';
import '../cubits/booking_status_state.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;
  final BookingDetailEntity? initialBooking;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
    this.initialBooking,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<BookingStatusCubit>()..refreshActiveBooking(widget.bookingId),
      child: Scaffold(
        backgroundColor: BrandTokens.bgSoft,
        body: BlocBuilder<BookingStatusCubit, BookingStatusState>(
          builder: (context, state) {
            if (state is BookingStatusLoading &&
                widget.initialBooking == null) {
              return const _BookingDetailsSkeleton();
            }

            final booking = (state is BookingStatusActive)
                ? state.booking
                : widget.initialBooking;

            if (booking == null) {
              return const _BookingNotFound();
            }

            return _BookingDetailsView(booking: booking);
          },
        ),
      ),
    );
  }
}

class _BookingDetailsView extends StatelessWidget {
  final BookingDetailEntity booking;

  const _BookingDetailsView({required this.booking});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _StatusHero(booking: booking)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLG,
            AppTheme.spaceMD,
            AppTheme.spaceLG,
            AppTheme.space2XL,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate.fixed([
              _HelperCard(booking: booking),
              const SizedBox(height: AppTheme.spaceMD),
              _PrimaryActions(booking: booking),
              const SizedBox(height: AppTheme.spaceMD),
              _TripSummaryCard(booking: booking),
              const SizedBox(height: AppTheme.spaceMD),
              _TimelineCard(booking: booking),
              if ((booking.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceMD),
                _NotesCard(notes: booking.notes!.trim()),
              ],
              if (booking.canCancel && !_isFinished(booking.status)) ...[
                const SizedBox(height: AppTheme.spaceLG),
                _CancelCard(bookingId: booking.id),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  static bool _isFinished(BookingStatus status) {
    return {
      BookingStatus.completed,
      BookingStatus.cancelledByUser,
      BookingStatus.cancelledByHelper,
      BookingStatus.cancelledBySystem,
      BookingStatus.declinedByHelper,
      BookingStatus.expiredNoResponse,
    }.contains(status);
  }
}

class _StatusHero extends StatelessWidget {
  final BookingDetailEntity booking;

  const _StatusHero({required this.booking});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const MeshGradientBackground(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BrandTokens.primaryBlueDark.withValues(alpha: 0.08),
                  BrandTokens.primaryBlueDark.withValues(alpha: 0.42),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 6,
            left: AppTheme.spaceMD,
            child: _GlassIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          Positioned(
            top: top + 62,
            left: AppTheme.spaceLG,
            right: AppTheme.spaceLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusPill(status: booking.status),
                const SizedBox(height: AppTheme.spaceMD),
                Text(
                  _heroTitle(booking.status),
                  style: BrandTokens.heading(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${booking.type.name.toUpperCase()} BOOKING · ${booking.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTokens.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: 'Total',
                        value: _price(booking),
                        icon: Icons.payments_rounded,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSM),
                    Expanded(
                      child: _HeroMetric(
                        label: 'Duration',
                        value: _duration(booking.durationInMinutes),
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _heroTitle(BookingStatus status) {
    switch (status) {
      case BookingStatus.inProgress:
        return 'Your helper is on the way';
      case BookingStatus.completed:
        return 'Trip completed';
      case BookingStatus.pendingHelperResponse:
      case BookingStatus.reassignmentInProgress:
        return 'Finding your helper';
      case BookingStatus.confirmedAwaitingPayment:
        return 'Confirm your payment';
      case BookingStatus.acceptedByHelper:
      case BookingStatus.confirmedPaid:
      case BookingStatus.upcoming:
        return 'Booking confirmed';
      default:
        return 'Booking details';
    }
  }
}

class _StatusPill extends StatelessWidget {
  final BookingStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 8),
          Text(
            _statusLabel(status),
            style: BrandTokens.body(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: BrandTokens.body(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.76),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTokens.numeric(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
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

class _HelperCard extends StatelessWidget {
  final BookingDetailEntity booking;

  const _HelperCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final helper = booking.helper;
    return _GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: BrandTokens.successGradient,
                  borderRadius: BorderRadius.circular(23),
                ),
                child: AppNetworkImage(
                  imageUrl: helper?.profileImageUrl,
                  width: 64,
                  height: 64,
                  borderRadius: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      helper?.name ??
                          booking.currentAssignment?.helperName ??
                          'Helper',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BrandTokens.heading(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      helper == null
                          ? 'We will show helper details as soon as they accept.'
                          : '${helper.rating.toStringAsFixed(1)} rating · ${helper.completedTrips} trips · ${helper.experienceYears}y exp',
                      style: BrandTokens.body(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (booking.chatEnabled)
                _RoundAction(
                  icon: Icons.chat_bubble_rounded,
                  onTap: () => context.pushNamed(
                    'user-chat',
                    pathParameters: {'id': booking.id},
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMD),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMD,
              vertical: AppTheme.spaceSM,
            ),
            decoration: BoxDecoration(
              color: BrandTokens.primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(
                color: BrandTokens.primaryBlue.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: BrandTokens.primaryBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.chatEnabled
                        ? 'Chat and live updates are available for this booking.'
                        : 'Live booking updates will appear here automatically.',
                    style: BrandTokens.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: BrandTokens.primaryBlue,
                    ),
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

class _PrimaryActions extends StatelessWidget {
  final BookingDetailEntity booking;

  const _PrimaryActions({required this.booking});

  @override
  Widget build(BuildContext context) {
    final canTrack = {
      BookingStatus.inProgress,
      BookingStatus.acceptedByHelper,
      BookingStatus.confirmedPaid,
      BookingStatus.upcoming,
    }.contains(booking.status);
    final showRate = booking.status == BookingStatus.completed;
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: canTrack ? 'Track helper' : 'Trip route',
            icon: Icons.map_rounded,
            enabled: canTrack,
            onTap: () {
              if (booking.status == BookingStatus.inProgress) {
                context.pushNamed(
                  'trip-live',
                  pathParameters: {'id': booking.id},
                );
                return;
              }
              context.pushNamed(
                'user-tracking',
                pathParameters: {'id': booking.id},
              );
            },
          ),
        ),
        const SizedBox(width: AppTheme.spaceSM),
        Expanded(
          child: _ActionButton(
            label: showRate ? 'Rate helper' : 'Open chat',
            icon: showRate ? Icons.star_rounded : Icons.chat_rounded,
            enabled: showRate || booking.chatEnabled,
            onTap: () {
              if (showRate) {
                context.pushNamed(
                  'helper-reviews',
                  pathParameters: {'id': booking.id},
                );
              } else {
                context.pushNamed(
                  'user-chat',
                  pathParameters: {'id': booking.id},
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: enabled ? BrandTokens.primaryGradient : null,
            color: enabled ? null : BrandTokens.borderSoft,
            borderRadius: BorderRadius.circular(18),
            boxShadow: enabled ? BrandTokens.ctaBlueGlow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? Colors.white : BrandTokens.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTokens.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: enabled ? Colors.white : BrandTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  final BookingDetailEntity booking;

  const _TripSummaryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Trip summary',
            subtitle: DateFormat(
              'MMM dd, yyyy · jm',
            ).format(booking.requestedDate),
          ),
          const SizedBox(height: AppTheme.spaceMD),
          _InfoTile(
            icon: Icons.trip_origin_rounded,
            label: 'Pickup',
            value: booking.pickupLocationName ?? 'Pickup location',
            color: BrandTokens.successGreen,
          ),
          _InfoTile(
            icon: Icons.flag_rounded,
            label: 'Destination',
            value: booking.destinationName ?? booking.destinationCity,
            color: BrandTokens.primaryBlue,
          ),
          _InfoTile(
            icon: Icons.payments_rounded,
            label: 'Payment',
            value: '${_price(booking)} · ${booking.paymentStatus ?? 'Pending'}',
            color: BrandTokens.accentAmberText,
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final BookingDetailEntity booking;

  const _TimelineCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final steps = booking.timeline.take(4).toList();
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Live timeline',
            subtitle: 'Latest booking changes from realtime updates.',
          ),
          const SizedBox(height: AppTheme.spaceMD),
          if (steps.isEmpty)
            Text(
              'No timeline events yet. Updates will appear here automatically.',
              style: BrandTokens.body(fontSize: 13),
            )
          else
            for (final step in steps) _TimelineRow(step: step),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final BookingTimelineStep step;

  const _TimelineRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: BrandTokens.successGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _readableStatus(step.newStatus),
                  style: BrandTokens.body(
                    fontWeight: FontWeight.w900,
                    color: BrandTokens.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('MMM dd · jm').format(step.changedAt),
                  style: BrandTokens.body(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;

  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: _InfoTile(
        icon: Icons.sticky_note_2_rounded,
        label: 'Notes',
        value: notes,
        color: BrandTokens.primaryBlue,
      ),
    );
  }
}

class _CancelCard extends StatelessWidget {
  final String bookingId;

  const _CancelCard({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        color: BrandTokens.dangerRedSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: BrandTokens.dangerRed.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: BrandTokens.dangerRed),
          const SizedBox(width: AppTheme.spaceSM),
          Expanded(
            child: Text(
              'Need to cancel? Review the policy before ending this booking.',
              style: BrandTokens.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: BrandTokens.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showCancelDialog(context, bookingId),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandTokens.surfaceWhite,
            BrandTokens.primaryBlue.withValues(alpha: 0.025),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: BrandTokens.borderSoft.withValues(alpha: 0.9),
        ),
        boxShadow: const [
          BoxShadow(
            color: BrandTokens.shadowSoft,
            blurRadius: 30,
            spreadRadius: -8,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: BrandTokens.heading(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        if (subtitle != null)
          Text(subtitle!, style: BrandTokens.body(fontSize: 12)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSM),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: BrandTokens.body(fontSize: 12)),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BrandTokens.body(
                    fontWeight: FontWeight.w900,
                    color: BrandTokens.textPrimary,
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

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      color: BrandTokens.primaryBlue,
      style: IconButton.styleFrom(
        backgroundColor: BrandTokens.primaryBlue.withValues(alpha: 0.08),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _BookingDetailsSkeleton extends StatelessWidget {
  const _BookingDetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: BrandTokens.primaryBlue),
    );
  }
}

class _BookingNotFound extends StatelessWidget {
  const _BookingNotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Booking not found',
        style: BrandTokens.heading(fontSize: 18),
      ),
    );
  }
}

String _price(BookingDetailEntity booking) {
  final value = booking.finalPrice ?? booking.estimatedPrice ?? 0;
  final currency = booking.currency ?? 'EGP';
  return '$currency ${value.toStringAsFixed(0)}';
}

String _duration(int minutes) {
  if (minutes % 60 == 0) return '${minutes ~/ 60}h';
  return '${minutes ~/ 60}h ${minutes % 60}m';
}

String _statusLabel(BookingStatus status) => _readableStatus(status.name);

String _readableStatus(String raw) {
  final withSpaces = raw
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');
  return withSpaces
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
      .join(' ');
}

Color _statusColor(BookingStatus status) {
  switch (status) {
    case BookingStatus.completed:
    case BookingStatus.confirmedPaid:
    case BookingStatus.acceptedByHelper:
      return BrandTokens.successGreen;
    case BookingStatus.inProgress:
      return BrandTokens.accentAmber;
    case BookingStatus.cancelledByUser:
    case BookingStatus.cancelledByHelper:
    case BookingStatus.cancelledBySystem:
    case BookingStatus.declinedByHelper:
    case BookingStatus.expiredNoResponse:
      return BrandTokens.dangerRed;
    default:
      return Colors.white;
  }
}

void _showCancelDialog(BuildContext context, String bookingId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel booking?'),
      content: const Text(
        'Are you sure you want to cancel this trip? A cancellation fee may apply.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep booking'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            context.go(AppRouter.home);
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColor.errorColor),
          ),
        ),
      ],
    ),
  );
}
