import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../core/theme/brand_typography.dart';
import '../../domain/entities/helper_booking_entities.dart';
import '../cubit/helper_bookings_cubits.dart';
import '../widgets/details/booking_status_banner.dart';
import '../widgets/details/traveler_info_section.dart';
import '../widgets/details/booking_route_card.dart';
import '../widgets/details/payment_info_card.dart';
import '../../../helper_ratings/presentation/widgets/booking_rating_sheet.dart';
import '../../../helper_chat/presentation/pages/helper_chat_page.dart';
import '../cubit/trip_action_cubit.dart';

class HelperBookingDetailsPage extends StatefulWidget {
  final String bookingId;
  final bool isRequest; // If true, use RequestDetailsCubit

  const HelperBookingDetailsPage({
    super.key, 
    required this.bookingId,
    this.isRequest = false,
  });

  @override
  State<HelperBookingDetailsPage> createState() => _HelperBookingDetailsPageState();
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

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? BrandTokens.dangerRed : BrandTokens.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                _showSnack(context, '✓ Request accepted!');
                final b = state.booking;
                context.pushReplacement(AppRouter.helperActiveBooking, extra: b.id);
              } else if (state is RejectSuccess) {
                _showSnack(context, 'Request declined');
                context.pop();
              } else if (state is AcceptRejectFailure) {
                _showSnack(context, state.message, isError: true);
              }
            },
          ),
          BlocListener<TripActionCubit, TripActionState>(
            listener: (context, state) {
              if (state is TripActionSuccess) {
                if (state.actionType == 'start') {
                  _showSnack(context, 'Trip started!');
                  context.pushReplacement(AppRouter.helperActiveBooking, extra: widget.bookingId);
                } else if (state.actionType == 'end') {
                  _showEarningsDialog(context, state.result as double);
                }
              } else if (state is TripActionError) {
                _showSnack(context, state.message, isError: true);
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: BrandTokens.bgSoft,
          appBar: AppBar(
            backgroundColor: BrandTokens.surfaceWhite,
            foregroundColor: BrandTokens.textPrimary,
            title: Text(widget.isRequest ? 'Trip Request' : 'Booking Details', 
                style: BrandTypography.title()),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: widget.isRequest 
            ? BlocBuilder<RequestDetailsCubit, RequestDetailsState>(
                builder: (context, state) {
                  if (state is RequestDetailsLoading) return _buildLoading();
                  if (state is RequestDetailsLoaded) return _buildContent(context, state.booking);
                  if (state is RequestDetailsError) return _buildError(context, state.message, true);
                  return const SizedBox.shrink();
                },
              )
            : BlocBuilder<HelperBookingDetailsCubit, HelperBookingDetailsState>(
                builder: (context, state) {
                  if (state is HelperBookingDetailsLoading) return _buildLoading();
                  if (state is HelperBookingDetailsLoaded) return _buildContent(context, state.booking);
                  if (state is HelperBookingDetailsError) return _buildError(context, state.message, false);
                  return const SizedBox.shrink();
                },
              ),
        ),
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator.adaptive());

  Widget _buildContent(BuildContext context, HelperBooking booking) {
    final status = booking.status.toLowerCase();
    final isPending = status == 'pending' || status == 'pendinghelperresponse';
    final isConfirmed = booking.canStartTrip
        || status == 'confirmed'
        || status == 'accepted'
        || status == 'acceptedbyhelper'
        || status == 'confirmedpaid';
    final isActive = booking.canEndTrip
        || status == 'inprogress'
        || status == 'started'
        || status == 'active';
    final isCompleted = status == 'completed';
    final isCancelled = status.contains('cancelled') || status == 'rejected';

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            BookingStatusBanner(status: booking.status),
            const SizedBox(height: 16),
            TravelerInfoSection(booking: booking),
            const SizedBox(height: 12),
            BookingRouteCard(booking: booking),
            const SizedBox(height: 12),
            PaymentInfoCard(booking: booking),
            const SizedBox(height: 12),
            _FlowHintCard(
              title: _flowTitle(
                isPending: isPending,
                isConfirmed: isConfirmed,
                isActive: isActive,
                isCompleted: isCompleted,
                isCancelled: isCancelled,
              ),
              subtitle: _flowSubtitle(
                isPending: isPending,
                isConfirmed: isConfirmed,
                isActive: isActive,
                isCompleted: isCompleted,
                isCancelled: isCancelled,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
        
        // Dynamic Bottom Actions
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _buildBottomActions(
            context,
            booking,
            isPending,
            isConfirmed,
            isActive,
            isCompleted,
            isCancelled,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    HelperBooking booking,
    bool isPending,
    bool isConfirmed,
    bool isActive,
    bool isCompleted,
    bool isCancelled,
  ) {
    // If there are no actions to show, do not render the container to avoid empty space
    if (!isPending && !isConfirmed && !isActive && !isCompleted && !isCancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      decoration: BoxDecoration(
        color: BrandTokens.surfaceWhite,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPending) _buildRequestActions(context, booking),
          if (isConfirmed) _buildConfirmedActions(context, booking),
          if (isActive) _buildActiveActions(context, booking),
          if (isCompleted) _buildCompletedActions(context, booking),
          if (isCancelled) _buildCancelledActions(context),
        ],
      ),
    );
  }

  Widget _buildRequestActions(BuildContext context, HelperBooking booking) {
    return BlocBuilder<AcceptRejectRequestCubit, AcceptRejectRequestState>(
      builder: (context, state) {
        final isAcceptLoading = state is AcceptLoading;
        final isRejectLoading = state is RejectLoading;
        final isDisabled = isAcceptLoading || isRejectLoading;

        return Row(
          children: [
            Expanded(
              child: _ActionBtn(
                label: 'Decline',
                color: BrandTokens.dangerRed,
                outline: true,
                isLoading: isRejectLoading,
                isDisabled: isDisabled,
                onTap: () {
                  if (widget.isRequest) _requestCubit.optimisticUpdateStatus('Rejected');
                  _acceptRejectCubit.rejectRequest(booking.id);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionBtn(
                label: 'Accept Request',
                color: BrandTokens.successGreen,
                isLoading: isAcceptLoading,
                isDisabled: isDisabled,
                onTap: () {
                  if (widget.isRequest) _requestCubit.optimisticUpdateStatus('Accepted');
                  _acceptRejectCubit.acceptRequest(booking.id);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmedActions(BuildContext context, HelperBooking booking) {
    return BlocBuilder<TripActionCubit, TripActionState>(
      builder: (context, state) {
        final isStartLoading =
            state is TripActionLoading && state.actionType == 'start';
        final isEndLoading =
            state is TripActionLoading && state.actionType == 'end';
        final isDisabled = isStartLoading || isEndLoading;

        return Column(
          children: [
            _ActionBtn(
              label: booking.canStartTrip ? 'Start Trip' : 'Open Live Tracking',
              icon: Icons.play_circle_fill_rounded,
              color: BrandTokens.successGreen,
              isLoading: isStartLoading,
              isDisabled: isDisabled,
              onTap: () {
                if (booking.canStartTrip) {
                  _tripActionCubit.start(booking.id);
                } else {
                  context.pushReplacement(AppRouter.helperActiveBooking, extra: booking.id);
                }
              },
            ),
            const SizedBox(height: 12),
            _ActionBtn(
              label: 'Message Traveler',
              icon: Icons.chat_bubble_outline_rounded,
              color: BrandTokens.primaryBlue,
              outline: true,
              isDisabled: isDisabled,
              onTap: () => _openChat(context, booking.id),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveActions(BuildContext context, HelperBooking booking) {
    return BlocBuilder<TripActionCubit, TripActionState>(
      builder: (context, state) {
        final isLoading = state is TripActionLoading;

        return Column(
          children: [
            _ActionBtn(
              label: 'Open Live Tracking',
              icon: Icons.gps_fixed_rounded,
              color: BrandTokens.primaryBlue,
              isLoading: false,
              isDisabled: isLoading,
              onTap: () => context.pushReplacement(
                AppRouter.helperActiveBooking,
                extra: booking.id,
              ),
            ),
            const SizedBox(height: 12),
            _ActionBtn(
              label: 'Message Traveler',
              icon: Icons.chat_bubble_outline_rounded,
              color: BrandTokens.primaryBlue,
              outline: true,
              isDisabled: isLoading,
              onTap: () => _openChat(context, booking.id),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompletedActions(BuildContext context, HelperBooking booking) {
    return Column(
      children: [
        _ActionBtn(
          label: 'Rate Traveler',
          icon: Icons.star_rounded,
          color: Colors.amber,
          onTap: () => _showRatingSheet(context, booking),
        ),
        const SizedBox(height: 12),
        _ActionBtn(
          label: 'Back to bookings',
          icon: Icons.home_rounded,
          color: BrandTokens.primaryBlue,
          outline: true,
          onTap: () => context.go(AppRouter.helperBookings),
        ),
      ],
    );
  }

  Widget _buildCancelledActions(BuildContext context) {
    return _ActionBtn(
      label: 'Back to bookings',
      icon: Icons.home_rounded,
      color: BrandTokens.primaryBlue,
      outline: true,
      onTap: () => context.go(AppRouter.helperBookings),
    );
  }

  void _openChat(BuildContext context, String id) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => HelperChatPage(bookingId: id)));
  }

  void _showRatingSheet(BuildContext context, HelperBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingRatingSheet(
        bookingId: booking.id,
        travelerName: booking.travelerName,
        travelerAvatar: '',
      ),
    );
  }

  void _showEarningsDialog(BuildContext context, double earnings) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: BrandTokens.successGreen, size: 64),
              const SizedBox(height: 16),
              Text('Trip Completed!', style: BrandTokens.heading(fontSize: 22)),
              const SizedBox(height: 8),
              Text('You earned', style: BrandTypography.caption()),
              Text('\$${earnings.toStringAsFixed(2)}', style: BrandTokens.numeric(fontSize: 36, color: BrandTokens.successGreen, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop();
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: BrandTokens.primaryBlue),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String msg, bool isReq) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: BrandTokens.dangerRed, size: 48),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => isReq ? _requestCubit.load(widget.bookingId) : _detailsCubit.load(widget.bookingId),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _flowTitle({
    required bool isPending,
    required bool isConfirmed,
    required bool isActive,
    required bool isCompleted,
    required bool isCancelled,
  }) {
    if (isPending) return 'Action required';
    if (isConfirmed) return 'Ready to start';
    if (isActive) return 'Trip is live';
    if (isCompleted) return 'Trip completed';
    if (isCancelled) return 'Trip closed';
    return 'Booking details';
  }

  String _flowSubtitle({
    required bool isPending,
    required bool isConfirmed,
    required bool isActive,
    required bool isCompleted,
    required bool isCancelled,
  }) {
    if (isPending) return 'Accept or decline this request to continue.';
    if (isConfirmed) return 'Start trip when traveler is ready, then switch to live tracking.';
    if (isActive) return 'Use live tracking to navigate and end the trip safely.';
    if (isCompleted) return 'Rate the traveler and return to your bookings list.';
    if (isCancelled) return 'This booking has been closed and no further actions are needed.';
    return 'Review booking information below.';
  }
}

class _FlowHintCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _FlowHintCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrandTokens.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandTokens.primaryBlue.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: BrandTokens.primaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: BrandTypography.body(weight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: BrandTypography.caption(color: BrandTokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;
  final bool outline;
  final bool isLoading;
  final bool isDisabled;

  const _ActionBtn({
    required this.label, 
    this.icon, 
    required this.color, 
    required this.onTap, 
    this.outline = false,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnTap = isDisabled ? null : onTap;
    final contentColor = outline ? color : Colors.white;

    Widget childContent = isLoading 
        ? SizedBox(
            width: 24, height: 24, 
            child: CircularProgressIndicator(color: contentColor, strokeWidth: 2.5)
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, color: contentColor, size: 20),
              if (icon != null) const SizedBox(width: 8),
              Text(label, style: BrandTypography.body(color: contentColor, weight: FontWeight.bold)),
            ],
          );

    if (outline) {
      return SizedBox(
        width: double.infinity, height: 56,
        child: OutlinedButton(
          onPressed: effectiveOnTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: isDisabled ? Colors.grey : color, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: childContent,
        ),
      );
    }
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: effectiveOnTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: childContent,
      ),
    );
  }
}
