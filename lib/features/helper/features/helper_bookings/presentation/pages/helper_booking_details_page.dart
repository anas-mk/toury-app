// Modernized booking details / request details screen for helpers.
//
// Layout (top → bottom):
//   1. Sliver hero header (gradient background, traveler avatar, status,
//      payout chip, ID).
//   2. Status banner (animated when active).
//   3. Trip Progress stepper.
//   4. Trip Logistics (route + meta).
//   5. Traveler card (with chat button + notes).
//   6. Sticky bottom action bar with frosted background.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/config/api_config.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/utils/currency_format.dart';
import '../../../../../../core/widgets/app_error_state.dart';
import '../../../../../../core/widgets/app_loading.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../../domain/entities/helper_booking_status_x.dart';
import '../../../helper_chat/presentation/pages/helper_chat_page.dart';
import '../../../helper_ratings/presentation/widgets/rate_traveler_dialog.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../cubit/trip_action_cubit.dart';
import '../widgets/details/booking_progress_stepper.dart';
import '../widgets/details/booking_route_card.dart';
import '../widgets/details/booking_status_banner.dart';
import '../widgets/details/traveler_info_section.dart';
import '../widgets/shared/booking_action_button.dart';
import '../widgets/shared/trip_completed_dialog.dart';

class HelperBookingDetailsPage extends StatefulWidget {
  final String bookingId;
  final bool isRequest;

  const HelperBookingDetailsPage({
    super.key,
    required this.bookingId,
    this.isRequest = false,
  });

  @override
  State<HelperBookingDetailsPage> createState() =>
      _HelperBookingDetailsPageState();
}

class _HelperBookingDetailsPageState extends State<HelperBookingDetailsPage> {
  late final HelperBookingDetailsCubit _detailsCubit;
  late final RequestDetailsCubit _requestCubit;
  late final AcceptRejectRequestCubit _acceptRejectCubit;
  late final TripActionCubit _tripActionCubit;

  @override
  void initState() {
    super.initState();
    _detailsCubit = sl<HelperBookingDetailsCubit>();
    _requestCubit = sl<RequestDetailsCubit>();
    _acceptRejectCubit = sl<AcceptRejectRequestCubit>();
    _tripActionCubit = sl<TripActionCubit>();

    if (widget.isRequest) {
      _requestCubit.load(widget.bookingId);
    } else {
      _detailsCubit.load(widget.bookingId);
    }
  }

  @override
  void dispose() {
    _detailsCubit.close();
    _requestCubit.close();
    _acceptRejectCubit.close();
    _tripActionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _detailsCubit),
        BlocProvider.value(value: _requestCubit),
        BlocProvider.value(value: _acceptRejectCubit),
        BlocProvider.value(value: _tripActionCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AcceptRejectRequestCubit, AcceptRejectRequestState>(
            listener: (context, state) {
              if (state is AcceptSuccess) {
                // Stay on the details page and swap in the server-confirmed
                // booking so the action bar transitions from "Decline / Accept"
                // to the confirmed actions ("Chat" + "Start Trip / Open Live
                // Tracking"). Helper decides when to enter live tracking —
                // we don't auto-navigate.
                if (widget.isRequest) {
                  _requestCubit.setBooking(state.booking);
                } else {
                  _detailsCubit.load(widget.bookingId);
                }
              } else if (state is RejectSuccess) {
                AppSnackbar.info(context, 'Request declined');
                context.pop();
              } else if (state is AcceptRejectFailure) {
                AppSnackbar.error(context, state.message);
              }
            },
          ),
          BlocListener<TripActionCubit, TripActionState>(
            listener: (context, state) {
              if (state is TripActionSuccess) {
                if (state.actionType == 'start') {
                  AppSnackbar.success(context, 'Trip started');
                  context.pushReplacement(
                    AppRouter.helperActiveBooking,
                    extra: widget.bookingId,
                  );
                } else if (state.actionType == 'end') {
                  // Optimistically clear so the dashboard's active-trip card
                  // disappears immediately when the user navigates back.
                  sl<ActiveBookingCubit>().clear();
                  sl<ActiveBookingCubit>().load(silent: true);
                  showTripCompletedDialog(
                    context,
                    earnings: state.result as double,
                    primaryLabel: 'Done',
                    onPrimary: () => context.pop(),
                  );
                }
              } else if (state is TripActionError) {
                AppSnackbar.error(context, state.message);
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: palette.scaffold,
          body: widget.isRequest
              ? BlocBuilder<RequestDetailsCubit, RequestDetailsState>(
                  builder: (context, state) {
                    if (state is RequestDetailsLoading) return _buildLoading();
                    if (state is RequestDetailsLoaded) {
                      return _buildContent(context, state.booking);
                    }
                    if (state is RequestDetailsError) {
                      return _buildError(context, state.message, true);
                    }
                    return const SizedBox.shrink();
                  },
                )
              : BlocBuilder<HelperBookingDetailsCubit,
                  HelperBookingDetailsState>(
                  builder: (context, state) {
                    if (state is HelperBookingDetailsLoading) {
                      return _buildLoading();
                    }
                    if (state is HelperBookingDetailsLoaded) {
                      return _buildContent(context, state.booking);
                    }
                    if (state is HelperBookingDetailsError) {
                      return _buildError(context, state.message, false);
                    }
                    return const SizedBox.shrink();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildLoading() => const Center(child: AppLoading(fullScreen: false));

  Widget _buildContent(BuildContext context, HelperBooking booking) {
    final palette = AppColors.of(context);
    final hasActions = _hasActions(booking);

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _SliverHeroHeader(
              booking: booking,
              isRequest: widget.isRequest,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageGutter,
                  AppSpacing.lg,
                  AppSpacing.pageGutter,
                  hasActions
                      ? AppSize.buttonLg + AppSpacing.giga + AppSpacing.lg
                      : AppSpacing.huge,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookingStatusBanner(status: booking.status),
                    const SizedBox(height: AppSpacing.lg),
                    BookingProgressStepper(booking: booking),
                    const SizedBox(height: AppSpacing.lg),
                    BookingRouteCard(booking: booking),
                    // Trip request: traveler + chat already implied in hero; skip duplicate card.
                    if (!widget.isRequest) ...[
                      const SizedBox(height: AppSpacing.lg),
                      TravelerInfoSection(
                        booking: booking,
                        onChat: (booking.isConfirmed || booking.isActive)
                            ? null
                            : () => _openChat(context, booking),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (hasActions)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StickyActionBar(
              palette: palette,
              child: _buildActionsFor(context, booking),
            ),
          ),
      ],
    );
  }

  bool _hasActions(HelperBooking b) =>
      b.isPending ||
      b.isConfirmed ||
      b.isActive ||
      b.isCompleted ||
      b.isCancelled;

  Widget _buildActionsFor(BuildContext context, HelperBooking booking) {
    if (booking.isPending) return _buildRequestActions(booking);
    if (booking.isConfirmed) return _buildConfirmedActions(booking);
    if (booking.isActive) return _buildActiveActions(booking);
    if (booking.isCompleted) return _buildCompletedActions(booking);
    if (booking.isCancelled) return _buildCancelledActions();
    return const SizedBox.shrink();
  }

  Widget _buildRequestActions(HelperBooking booking) {
    return BlocBuilder<AcceptRejectRequestCubit, AcceptRejectRequestState>(
      builder: (context, state) {
        final palette = AppColors.of(context);
        final isAcceptLoading = state is AcceptLoading;
        final isRejectLoading = state is RejectLoading;
        final isDisabled = isAcceptLoading || isRejectLoading;
        return Row(
          children: [
            Expanded(
              child: BookingActionButton(
                label: 'Decline',
                color: palette.danger,
                outline: true,
                isLoading: isRejectLoading,
                isDisabled: isDisabled,
                onTap: () {
                  if (widget.isRequest) {
                    _requestCubit.optimisticUpdateStatus('Rejected');
                  }
                  _acceptRejectCubit.rejectRequest(booking.id);
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: BookingActionButton(
                label: 'Accept',
                color: palette.success,
                isLoading: isAcceptLoading,
                isDisabled: isDisabled,
                onTap: () {
                  if (widget.isRequest) {
                    _requestCubit.optimisticUpdateStatus('Accepted');
                  }
                  _acceptRejectCubit.acceptRequest(booking.id);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmedActions(HelperBooking booking) {
    return BlocBuilder<TripActionCubit, TripActionState>(
      builder: (context, state) {
        final palette = AppColors.of(context);
        final isLoading = state is TripActionLoading;
        return Row(
          children: [
            BookingActionButton(
              label: '',
              icon: Icons.chat_bubble_rounded,
              color: palette.primary,
              outline: true,
              isDisabled: isLoading,
              onTap: () => _openChat(context, booking),
              height: AppSize.buttonLg,
            ).inFlex(0, 70),
            const SizedBox(width: AppSpacing.md),
            // Always route through live-tracking first — it shows the way to
            // the pickup, and only enables "Start Trip" once the helper is
            // actually within the pickup-arrival radius. Calling
            // `_tripActionCubit.start()` directly here would skip that safety
            // gate and start the trip the moment the helper accepts.
            BookingActionButton(
              label: 'Navigate to Pickup',
              color: palette.success,
              isDisabled: isLoading,
              onTap: () => context.pushReplacement(
                AppRouter.helperActiveBooking,
                extra: booking.id,
              ),
            ).inFlex(2, 0),
          ],
        );
      },
    );
  }

  Widget _buildActiveActions(HelperBooking booking) {
    return BlocBuilder<TripActionCubit, TripActionState>(
      builder: (context, state) {
        final palette = AppColors.of(context);
        final isLoading = state is TripActionLoading;
        return Row(
          children: [
            BookingActionButton(
              label: '',
              icon: Icons.chat_bubble_rounded,
              color: palette.primary,
              outline: true,
              isDisabled: isLoading,
              onTap: () => _openChat(context, booking),
            ).inFlex(0, 70),
            const SizedBox(width: AppSpacing.md),
            BookingActionButton(
              label: 'Open Live Tracking',
              icon: Icons.gps_fixed_rounded,
              trailingIcon: Icons.arrow_forward_rounded,
              color: palette.success,
              isDisabled: isLoading,
              onTap: () => context.pushReplacement(
                AppRouter.helperActiveBooking,
                extra: booking.id,
              ),
            ).inFlex(2, 0),
          ],
        );
      },
    );
  }

  Widget _buildCompletedActions(HelperBooking booking) {
    final palette = AppColors.of(context);
    return Row(
      children: [
        BookingActionButton(
          label: 'Back',
          icon: Icons.arrow_back_rounded,
          color: palette.primary,
          outline: true,
          onTap: () => context.go(AppRouter.helperBookings),
        ).inFlex(0, 70),
        const SizedBox(width: AppSpacing.md),
        BookingActionButton(
          label: 'Rate Traveler',
          color: const Color(0xFFFFB300),
          onTap: () => unawaited(_showRatingSheet(context, booking)),
        ).inFlex(2, 0),
      ],
    );
  }

  Widget _buildCancelledActions() {
    final palette = AppColors.of(context);
    return BookingActionButton(
      label: 'Back to Bookings',
      icon: Icons.home_rounded,
      color: palette.primary,
      outline: true,
      onTap: () => context.go(AppRouter.helperBookings),
    );
  }

  void _openChat(BuildContext context, HelperBooking booking) {
    HelperChatPage.open(
      context,
      bookingId: booking.id,
      userName: booking.travelerName,
      userAvatar: booking.travelerImage,
    );
  }

  Future<void> _showRatingSheet(BuildContext context, HelperBooking booking) {
    return openRateTravelerForBooking(
      context,
      bookingId: booking.id,
      travelerName: booking.travelerName,
      travelerAvatar: booking.travelerImage ?? '',
    );
  }

  Widget _buildError(BuildContext context, String msg, bool isReq) {
    return Center(
      child: AppErrorState(
        message: msg,
        onRetry: () => isReq
            ? _requestCubit.load(widget.bookingId)
            : _detailsCubit.load(widget.bookingId),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
      ),
    );
  }
}

String _heroTripTypeLabel(HelperBooking booking) {
  final raw = booking.bookingType.trim();
  if (raw.isNotEmpty) {
    final lower = raw.toLowerCase();
    if (lower == 'instant') return 'Instant trip';
    if (lower == 'scheduled') return 'Scheduled trip';
    return raw[0].toUpperCase() + raw.substring(1);
  }
  return booking.isInstant ? 'Instant trip' : 'Scheduled trip';
}

extension _Flex on Widget {
  /// Convenience to wrap a button in a sized [Expanded] inside the action row.
  Widget inFlex(int flex, double minWidth) {
    if (flex == 0) {
      return SizedBox(width: minWidth, child: this);
    }
    return Expanded(flex: flex, child: this);
  }
}

class _SliverHeroHeader extends StatelessWidget {
  final HelperBooking booking;
  final bool isRequest;
  const _SliverHeroHeader({required this.booking, required this.isRequest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final accent = _accent(palette);

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: accent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: _GlassIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        isRequest ? 'Trip Request' : 'Booking Details',
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: _HeroBackground(booking: booking, accent: accent),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(
          height: 24,
          decoration: BoxDecoration(
            color: palette.scaffold,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
        ),
      ),
    );
  }

  Color _accent(AppColors p) {
    // Pending / trip-request hero uses brand primary (not warning orange).
    if (booking.isPending) return p.primary;
    if (booking.isActive) return p.success;
    if (booking.isCancelled) return p.danger;
    if (booking.isCompleted) return p.textMuted;
    return p.primary;
  }
}

class _HeroBackground extends StatelessWidget {
  final HelperBooking booking;
  final Color accent;
  const _HeroBackground({required this.booking, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = ApiConfig.resolveImageUrl(booking.travelerImage);

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent,
                Color.lerp(accent, Colors.black, 0.30)!,
              ],
            ),
          ),
        ),
        // Decorative orbs.
        Positioned(
          top: -36,
          right: -36,
          child: _orb(180, 0.10),
        ),
        Positioned(
          bottom: -50,
          left: -36,
          child: _orb(180, 0.06),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageGutter,
              AppSpacing.giga,
              AppSpacing.pageGutter,
              AppSpacing.xl,
            ),
            child: Row(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: resolved.isNotEmpty
                        ? Image.network(
                            resolved,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _initials(booking.travelerName),
                          )
                        : _initials(booking.travelerName),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        booking.travelerName.isEmpty
                            ? 'Traveler'
                            : booking.travelerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _heroTripTypeLabel(booking),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              booking.isInstant
                                  ? Icons.flash_on_rounded
                                  : Icons.event_outlined,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d · hh:mm a')
                                  .format(booking.startTime),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 14,
                              color: accent,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              Money.egp(booking.payout),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
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
      ],
    );
  }

  Widget _initials(String name) => Container(
        color: Colors.white,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ),
      );

  Widget _orb(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: alpha),
          shape: BoxShape.circle,
        ),
      );
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white.withValues(alpha: 0.22),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  final AppColors palette;
  final Widget child;
  const _StickyActionBar({required this.palette, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: palette.surfaceElevated.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: palette.border.withValues(alpha: 0.45),
                width: 0.6,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: palette.isDark ? 0.40 : 0.06,
                ),
                blurRadius: 16,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.lg,
            AppSpacing.pageGutter,
            AppSpacing.lg + MediaQuery.of(context).padding.bottom,
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}
