import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/realtime/booking_realtime_event_bus.dart';
import '../../../../../../../core/theme/app_theme.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../../../../core/widgets/brand/mesh_gradient.dart';
import '../../../../payments/domain/entities/payment_entity.dart';
import '../../../../payments/presentation/cubit/payment_cubit.dart';
import '../../../../payments/presentation/cubit/payment_state.dart';
import '../../../domain/entities/app_payment_method.dart';

class PayNowPage extends StatefulWidget {
  final String bookingId;

  const PayNowPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<PayNowPage> createState() => _PayNowPageState();
}

class _PayNowPageState extends State<PayNowPage> {
  late final PaymentCubit _paymentCubit;
  StreamSubscription<BookingRealtimeBusEvent>? _busSub;
  WebViewController? _web;
  AppPaymentMethod _method = AppPaymentMethod.cash;
  bool _showRetry = false;
  String? _lastFailure;
  PaymentEntity? _busPaid;
  bool _actionLocked = false;
  bool _terminalInitiateError = false;

  @override
  void initState() {
    super.initState();
    _paymentCubit = sl<PaymentCubit>();
    _method = AppPaymentMethod.cash;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenBus();
      _startInitiate();
    });
  }

  void _listenBus() {
    _busSub = BookingRealtimeEventBus.instance.stream.listen((e) {
      if (e is! BusBookingPaymentChanged) return;
      if (e.event.bookingId != widget.bookingId) return;
      final st = e.event.status.toLowerCase();
      if (!mounted) return;
      if (st == 'paid') {
        setState(() {
          _terminalInitiateError = false;
          _showRetry = false;
          _lastFailure = null;
          _busPaid = PaymentEntity(
            paymentId: e.event.paymentId ?? '',
            bookingId: widget.bookingId,
            amount: e.event.amount ?? 0,
            currency: e.event.currency ?? 'EGP',
            method: e.event.method ?? _method.apiName,
            status: PaymentStatus.paid,
          );
        });
      } else if (st == 'failed' || st == 'cancelled' || st == 'canceled') {
        setState(() {
          _showRetry = true;
          _lastFailure = e.event.status;
        });
      }
    });
  }

  Future<void> _startInitiate() async {
    if (_actionLocked) return;
    if (_terminalInitiateError) return;
    setState(() {
      _actionLocked = true;
      _showRetry = false;
      _lastFailure = null;
      _busPaid = null;
      _web = null;
    });
    try {
      await _paymentCubit.initiatePayment(widget.bookingId, _method.apiName);
    } finally {
      if (mounted) {
        setState(() => _actionLocked = false);
      }
    }
  }

  @override
  void dispose() {
    _busSub?.cancel();
    super.dispose();
  }

  PaymentEntity? _effectiveSuccess(PaymentState s) {
    if (_busPaid != null) return _busPaid;
    if (s is PaymentSuccess) return s.payment;
    if (s is PaymentInitiated) {
      final p = s.payment;
      final url = p.paymentUrl;
      if (p.status == PaymentStatus.paid || url == null || url.isEmpty) {
        return p;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finishPaymentFlow(context);
      },
      child: BlocProvider.value(
        value: _paymentCubit,
        child: Scaffold(
          backgroundColor: BrandTokens.bgSoft,
          body: BlocConsumer<PaymentCubit, PaymentState>(
            listener: (context, state) {
              if (state is PaymentInitiated) {
                final url = state.payment.paymentUrl;
                if (url != null && url.isNotEmpty) {
                  final ctrl = WebViewController()
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..loadRequest(Uri.parse(url));
                  setState(() => _web = ctrl);
                } else {
                  setState(() => _web = null);
                }
              }
            },
            builder: (context, state) {
              final success = _effectiveSuccess(state);
              if (success != null &&
                  success.status == PaymentStatus.paid &&
                  !_showRetry) {
                final isCash = success.method.toLowerCase() == 'cash';
                final cash =
                    isCash &&
                    (success.paymentUrl == null || success.paymentUrl!.isEmpty);
                return _SuccessCard(
                  title: cash ? 'Pay in cash' : 'Payment complete',
                  subtitle: cash
                      ? 'Pay ${success.amount.toStringAsFixed(2)} ${success.currency} to your helper.'
                      : '${success.amount.toStringAsFixed(2)} ${success.currency} (${success.method})',
                  onDone: () => _finishPaymentFlow(context),
                );
              }
              if (state is PaymentLoading) {
                return _PaymentLoadingView(
                  onClose: () => context.go(AppRouter.home),
                );
              }
              if (state is PaymentFailed) {
                final msg = state.message.toLowerCase();
                final terminal = msg.contains('cannot be initiated') ||
                    msg.contains('completed') ||
                    msg.contains('already paid');
                if (terminal && !_terminalInitiateError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _terminalInitiateError = true);
                  });
                }
                return _ErrorCard(
                  message: state.message,
                  onRetry: () {
                    if (_actionLocked) return;
                    if (_terminalInitiateError) return;
                    setState(() => _method = AppPaymentMethod.mockCard);
                    _startInitiate();
                  },
                  onCash: () {
                    if (_actionLocked) return;
                    if (_terminalInitiateError) return;
                    setState(() => _method = AppPaymentMethod.cash);
                    _startInitiate();
                  },
                  busy: _actionLocked,
                  terminal: _terminalInitiateError,
                  onDone: () => _finishPaymentFlow(context),
                );
              }
              if (state is PaymentInitiated) {
                final p = state.payment;
                final url = p.paymentUrl;
                if (url == null || url.isEmpty) {
                  return const SizedBox.shrink();
                }
                if (_showRetry) {
                  return _ErrorCard(
                    message: _lastFailure ?? 'Payment failed',
                    onRetry: () {
                      if (_actionLocked) return;
                      if (_terminalInitiateError) return;
                      setState(() {
                        _method = AppPaymentMethod.mockCard;
                        _showRetry = false;
                      });
                      _startInitiate();
                    },
                    onCash: () {
                      if (_actionLocked) return;
                      if (_terminalInitiateError) return;
                      setState(() {
                        _method = AppPaymentMethod.cash;
                        _showRetry = false;
                      });
                      _startInitiate();
                    },
                    busy: _actionLocked,
                    terminal: _terminalInitiateError,
                    onDone: () => _finishPaymentFlow(context),
                  );
                }
                if (_web == null) {
                  return _PaymentLoadingView(
                    onClose: () => context.go(AppRouter.home),
                  );
                }
                return Column(
                  children: [
                    _PaymentTopBar(
                      title: 'Secure payment',
                      subtitle: 'Complete the payment in the secure window.',
                      onClose: () => context.go(AppRouter.home),
                    ),
                    Expanded(child: WebViewWidget(controller: _web!)),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Complete the payment in the secure window.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  void _finishPaymentFlow(BuildContext context) {
    // Phase 4: do NOT route to /rate-booking anymore. The global
    // MandatoryRatingOverlay (bound from main.dart) shows the popup
    // automatically because BusBookingTripEnded already marked this
    // booking as pending-rating. We simply go home.
    context.go(AppRouter.home);
  }
}

class _SuccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onDone;
  const _SuccessCard({
    required this.title,
    required this.subtitle,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BrandTokens.primaryBlue.withValues(alpha: 0.08),
                  BrandTokens.bgSoft,
                  BrandTokens.accentAmber.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -90,
          left: -60,
          right: -60,
          height: 360,
          child: ClipPath(
            clipper: _PaymentHeroClipper(),
            child: const MeshGradientBackground(),
          ),
        ),
        Positioned(
          top: top + 8,
          left: AppTheme.spaceMD,
          child: _CircleButton(icon: Icons.close_rounded, onTap: onDone),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceLG,
              88,
              AppTheme.spaceLG,
              AppTheme.spaceLG,
            ),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spaceLG),
                  decoration: BoxDecoration(
                    color: BrandTokens.surfaceWhite.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: BrandTokens.borderSoft.withValues(alpha: 0.9),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: BrandTokens.shadowDeep,
                        blurRadius: 42,
                        spreadRadius: -14,
                        offset: Offset(0, 22),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          gradient: BrandTokens.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: BrandTokens.ctaBlueGlow,
                          border: Border.all(
                            color: BrandTokens.accentAmber,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceLG),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: BrandTokens.heading(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: BrandTokens.body(
                          fontSize: 15,
                          height: 1.55,
                          color: BrandTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceLG),
                      const _PaymentSteps(),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLG),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandTokens.primaryBlue,
                      foregroundColor: BrandTokens.surfaceWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: onDone,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                      'Done',
                      style: BrandTokens.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentSteps extends StatelessWidget {
  const _PaymentSteps();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _PaymentStep(
            icon: Icons.verified_user_rounded,
            label: 'Booking',
            active: true,
          ),
        ),
        _StepDivider(),
        Expanded(
          child: _PaymentStep(
            icon: Icons.payments_rounded,
            label: 'Cash',
            active: true,
          ),
        ),
        _StepDivider(),
        Expanded(
          child: _PaymentStep(
            icon: Icons.route_rounded,
            label: 'Trip',
            active: false,
          ),
        ),
      ],
    );
  }
}

class _PaymentStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _PaymentStep({
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: active ? 0.12 : 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: BrandTokens.body(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 2,
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: BrandTokens.accentAmber.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _PaymentLoadingView extends StatelessWidget {
  final VoidCallback onClose;

  const _PaymentLoadingView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaymentTopBar(
          title: 'Preparing payment',
          subtitle: 'Securing your booking payment session.',
          onClose: onClose,
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              margin: const EdgeInsets.all(AppTheme.spaceLG),
              decoration: BoxDecoration(
                color: BrandTokens.surfaceWhite,
                borderRadius: BorderRadius.circular(30),
                boxShadow: BrandTokens.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: BrandTokens.primaryBlue,
                  ),
                  const SizedBox(height: AppTheme.spaceMD),
                  Text(
                    'Connecting to realtime payment updates...',
                    textAlign: TextAlign.center,
                    style: BrandTokens.body(
                      fontWeight: FontWeight.w800,
                      color: BrandTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaymentTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _PaymentTopBar({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const MeshGradientBackground(),
          Container(color: BrandTokens.primaryBlueDark.withValues(alpha: 0.28)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMD,
                vertical: AppTheme.spaceSM,
              ),
              child: Row(
                children: [
                  _CircleButton(icon: Icons.close_rounded, onTap: onClose),
                  const SizedBox(width: AppTheme.spaceMD),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: BrandTokens.heading(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: BrandTokens.body(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.82),
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
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

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

class _PaymentHeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 58);
    p.cubicTo(
      size.width * 0.22,
      size.height - 4,
      size.width * 0.52,
      size.height - 92,
      size.width * 0.82,
      size.height - 42,
    );
    p.cubicTo(
      size.width * 0.95,
      size.height - 18,
      size.width,
      size.height - 42,
      size.width,
      size.height - 70,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCash;
  final bool busy;
  final bool terminal;
  final VoidCallback onDone;
  const _ErrorCard({
    required this.message,
    required this.onRetry,
    required this.onCash,
    this.busy = false,
    this.terminal = false,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BrandTokens.surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BrandTokens.borderSoft, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 24,
                  color: BrandTokens.shadowSoft,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_rounded,
                  size: 56,
                  color: BrandTokens.dangerRed,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: BrandTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: BrandTokens.primaryBlue,
                foregroundColor: BrandTokens.surfaceWhite,
              ),
              onPressed: (busy || terminal) ? null : onRetry,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Try card again'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: (busy || terminal) ? null : onCash,
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandTokens.primaryBlue,
                side: const BorderSide(
                  color: BrandTokens.primaryBlue,
                  width: 1.5,
                ),
              ),
              child: const Text('Switch to cash'),
            ),
          ),
          if (terminal) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: onDone,
                child: const Text('Back to home'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
