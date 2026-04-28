import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/theme/app_color.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/widgets/app_network_image.dart';
import '../../../../../../../core/widgets/brand/brand_kit.dart';
import '../../../domain/entities/app_payment_method.dart';
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
    final reason = await showCancelReasonSheet(
      ctx,
      refundToWallet:
          widget.cubit.selectedPaymentMethod == AppPaymentMethod.mockCard,
    );
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
          final helperAvatar =
              widget.helper?.profileImageUrl ??
              booking?.helper?.profileImageUrl;
          final attempt = booking?.assignmentAttemptCount ?? 0;

          return Scaffold(
            backgroundColor: BrandTokens.bgSoft,
            body: Stack(
              children: [
                ClipPath(
                  clipper: const _WaitingHeroBlobClipper(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.55,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const RepaintBoundary(child: MeshGradientBackground()),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                BrandTokens.primaryBlueDark.withValues(
                                  alpha: 0.05,
                                ),
                                BrandTokens.primaryBlueDark.withValues(
                                  alpha: 0.30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                          children: [
                            Expanded(
                              child: Text(
                                'Looking for your helper',
                                style: BrandTokens.heading(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const _LiveRequestBadge(),
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
                            ? 'Matching you with a nearby helper...'
                            : 'Waiting for $helperName...',
                        textAlign: TextAlign.center,
                        style: BrandTokens.heading(
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
                          'We are keeping the request live and will suggest another trusted helper if this one is busy.',
                          textAlign: TextAlign.center,
                          style: BrandTokens.body(
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
                            color: BrandTokens.surfaceWhite,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXL,
                            ),
                            border: Border.all(color: BrandTokens.borderSoft),
                            boxShadow: [
                              BoxShadow(
                                color: BrandTokens.primaryBlue.withValues(
                                  alpha: 0.10,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: BrandTokens.primaryGradient,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: BrandTokens.ctaBlueGlow,
                                    ),
                                    child: const Icon(
                                      Icons.radar_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spaceMD),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Request is live',
                                          style: BrandTokens.heading(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        Text(
                                          'We are watching helper responses in realtime.',
                                          style: BrandTokens.body(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spaceMD),
                              const _SearchStageRow(),
                              const SizedBox(height: AppTheme.spaceMD),
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
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMD,
                                      ),
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

class _LiveRequestBadge extends StatelessWidget {
  const _LiveRequestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: BrandTokens.successGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: BrandTokens.body(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
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

class _SearchStageRow extends StatelessWidget {
  const _SearchStageRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _SearchStage(
            icon: Icons.radar_rounded,
            label: 'Searching',
            active: true,
          ),
        ),
        _StageLine(),
        Expanded(
          child: _SearchStage(
            icon: Icons.touch_app_rounded,
            label: 'Waiting',
            active: true,
          ),
        ),
        _StageLine(),
        Expanded(
          child: _SearchStage(
            icon: Icons.verified_rounded,
            label: 'Confirm',
            active: false,
          ),
        ),
      ],
    );
  }
}

class _SearchStage extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _SearchStage({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? BrandTokens.primaryBlue : BrandTokens.textSecondary;
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: active ? 0.12 : 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BrandTokens.body(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StageLine extends StatelessWidget {
  const _StageLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: BrandTokens.borderSoft,
        borderRadius: BorderRadius.circular(2),
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

class _WaitingHeroBlobClipper extends CustomClipper<Path> {
  const _WaitingHeroBlobClipper();

  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 50);
    p.cubicTo(
      size.width * 0.25,
      size.height - 10,
      size.width * 0.55,
      size.height - 80,
      size.width * 0.78,
      size.height - 40,
    );
    p.cubicTo(
      size.width * 0.92,
      size.height - 20,
      size.width,
      size.height - 50,
      size.width,
      size.height - 80,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
