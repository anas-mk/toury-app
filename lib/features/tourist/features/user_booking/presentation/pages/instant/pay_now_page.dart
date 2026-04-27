import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../../../core/di/injection_container.dart';
import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/realtime/booking_realtime_event_bus.dart';
import '../../../../../../../core/theme/brand_tokens.dart';
import '../../../../payments/domain/entities/payment_entity.dart';
import '../../../../payments/presentation/cubit/payment_cubit.dart';
import '../../../../payments/presentation/cubit/payment_state.dart';
import '../../../domain/entities/app_payment_method.dart';
import '../../cubits/instant_booking_cubit.dart';

class PayNowPage extends StatefulWidget {
  final String bookingId;
  final InstantBookingCubit? instantCubit;

  const PayNowPage({super.key, required this.bookingId, this.instantCubit});

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

  @override
  void initState() {
    super.initState();
    _paymentCubit = sl<PaymentCubit>();
    _method = widget.instantCubit?.selectedPaymentMethod ?? AppPaymentMethod.cash;
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
    setState(() {
      _showRetry = false;
      _lastFailure = null;
      _busPaid = null;
      _web = null;
    });
    await _paymentCubit.initiatePayment(widget.bookingId, _method.apiName);
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
        if (!didPop) context.go(AppRouter.home);
      },
      child: BlocProvider.value(
        value: _paymentCubit,
        child: Scaffold(
          backgroundColor: BrandTokens.bgSoft,
          appBar: AppBar(
            title: const Text('Complete payment'),
            backgroundColor: BrandTokens.primaryBlue,
            foregroundColor: BrandTokens.surfaceWhite,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.go(AppRouter.home),
            ),
          ),
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
                final cash = isCash &&
                    (success.paymentUrl == null ||
                        success.paymentUrl!.isEmpty);
                return _SuccessCard(
                  title: cash ? 'Pay in cash' : 'Payment complete',
                  subtitle: cash
                      ? 'Pay ${success.amount.toStringAsFixed(2)} ${success.currency} to your helper.'
                      : '${success.amount.toStringAsFixed(2)} ${success.currency} (${success.method})',
                  onDone: () => context.go(AppRouter.home),
                );
              }
              if (state is PaymentLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is PaymentFailed) {
                return _ErrorCard(
                  message: state.message,
                  onRetry: () {
                    setState(() => _method = AppPaymentMethod.mockCard);
                    _startInitiate();
                  },
                  onCash: () {
                    setState(() => _method = AppPaymentMethod.cash);
                    _startInitiate();
                  },
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
                      setState(() {
                        _method = AppPaymentMethod.mockCard;
                        _showRetry = false;
                      });
                      _startInitiate();
                    },
                    onCash: () {
                      setState(() {
                        _method = AppPaymentMethod.cash;
                        _showRetry = false;
                      });
                      _startInitiate();
                    },
                  );
                }
                if (_web == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: [
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
                const Icon(Icons.check_circle_rounded,
                    size: 56, color: BrandTokens.primaryBlue),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: BrandTokens.textPrimary,
                    ),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: const TextStyle(color: BrandTokens.textSecondary),
                    textAlign: TextAlign.center),
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
              onPressed: onDone,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCash;
  const _ErrorCard({
    required this.message,
    required this.onRetry,
    required this.onCash,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: BrandTokens.textPrimary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: BrandTokens.primaryBlue,
                foregroundColor: BrandTokens.surfaceWhite,
              ),
              child: const Text('Try card again'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onCash,
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
        ],
      ),
    );
  }
}
