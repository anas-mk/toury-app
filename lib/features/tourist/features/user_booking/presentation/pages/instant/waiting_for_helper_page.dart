import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../../core/widgets/hero_header.dart';
import '../../../domain/entities/booking_detail.dart';
import '../../../domain/entities/helper_search_result.dart';
import '../../cubits/instant_booking_cubit.dart';
import '../../cubits/instant_booking_state.dart';
import '../../widgets/instant/cancel_reason_sheet.dart';
import '../../widgets/instant/radar_pulse.dart';

/// Step 7 â€” radar / pulse waiting screen. Routes to confirmed,
/// alternatives, or home depending on SignalR + polling updates.
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
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer _) {
    final state = widget.cubit.state;
    DateTime? deadline;
    if (state is InstantBookingWaiting) {
      deadline = state.booking.responseDeadline;
    } else if (state is InstantBookingCreated) {
      deadline = state.booking.responseDeadline;
    }
    if (deadline == null) {
      if (_remaining != Duration.zero) {
        setState(() => _remaining = Duration.zero);
      }
      return;
    }
    final diff = deadline.difference(DateTime.now().toUtc());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _onCancel(BuildContext ctx) async {
    final reason = await showCancelReasonSheet(ctx);
    if (reason == null || !mounted) return;
    final ok = await widget.cubit.cancelBooking(widget.bookingId, reason);
    if (!ok || !mounted) return;
    if (!context.mounted) return;
    context.go(AppRouter.bookingHome);
  }

  String _formatRemaining(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.55,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: kBrandGradient,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kBrandGradient.first.withValues(alpha: 0.28),
                        blurRadius: 26,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spaceLG,
                          AppTheme.spaceSM,
                          AppTheme.spaceLG,
                          0,
                        ),
                        child: Row(
                          children: const [
                            Expanded(
                              child: Text(
                                'Looking for your helper',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      RadarPulse(
                        size: 240,
                        color: Colors.white,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: ClipOval(
                            child: AppNetworkImage(
                              imageUrl: helperAvatar,
                              width: 110,
                              height: 110,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceLG),
                      Text(
                        helperName == null
                            ? 'Looking for an available helperâ€¦'
                            : 'Waiting for $helperNameâ€¦',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceLG,
                        ),
                        child: Text(
                          'They\'ll respond shortly. We\'ll auto-suggest others if needed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spaceLG,
                          AppTheme.spaceLG,
                          AppTheme.spaceLG,
                          AppTheme.spaceLG,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spaceMD),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXL),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (_remaining > Duration.zero)
                                _CountdownPill(
                                  text: _formatRemaining(_remaining),
                                ),
                              if (attempt > 1) ...[
                                if (_remaining > Duration.zero)
                                  const SizedBox(height: AppTheme.spaceSM),
                                _AttemptBadge(attempt: attempt),
                              ],
                              const SizedBox(height: AppTheme.spaceMD),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _onCancel(context),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    foregroundColor: AppColor.errorColor,
                                    side: const BorderSide(
                                      color: AppColor.errorColor,
                                      width: 1.4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppTheme.radiusMD),
                                    ),
                                  ),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text(
                                    'Cancel request',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      context.pushReplacement(
        AppRouter.instantConfirmed
            .replaceFirst(':id', state.booking.bookingId),
        extra: {
          'cubit': widget.cubit,
          'helper': widget.helper,
        },
      );
    } else if (state is InstantBookingDeclined) {
      context.pushReplacement(
        AppRouter.instantAlternatives
            .replaceFirst(':id', state.booking.bookingId),
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
      context.go(AppRouter.bookingHome);
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

class _CountdownPill extends StatelessWidget {
  final String text;
  const _CountdownPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceLG,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColor.accentColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 18,
            color: AppColor.accentColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColor.accentColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptBadge extends StatelessWidget {
  final int attempt;
  const _AttemptBadge({required this.attempt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColor.warningColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.refresh_rounded,
            size: 14,
            color: AppColor.warningColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Attempt $attempt',
            style: const TextStyle(
              color: AppColor.warningColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

