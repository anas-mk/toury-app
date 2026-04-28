import subprocess
from pathlib import Path

def patch_messaging():
    p = Path("lib/core/services/notifications/messaging_service.dart")
    raw = subprocess.check_output(["git", "show", "HEAD:lib/core/services/notifications/messaging_service.dart"])
    t = raw.decode("utf-8", errors="strict")
    for a, b in [("\r\r\n", "\n"), ("\r\n", "\n"), ("\r", "\n")]:
        t = t.replace(a, b)
    t = t.replace("_androidChannelId = 'toury_high_priority'", "_androidChannelId = 'rafiq_default'")
    n = "import '../realtime/event_dedup_cache.dart';\nimport '../realtime/realtime_logger.dart';"
    r = "import '../realtime/booking_realtime_event_bus.dart';\nimport '../realtime/event_dedup_cache.dart';\nimport '../realtime/realtime_logger.dart';"
    assert n in t
    t = t.replace(n, r, 1)
    oc = "        const channel = AndroidNotificationChannel(\n          _androidChannelId,\n          _androidChannelName,\n          description: _androidChannelDescription,\n          importance: Importance.high,\n        );"
    nc = "        const channel = AndroidNotificationChannel(\n          _androidChannelId,\n          _androidChannelName,\n          description: _androidChannelDescription,\n          importance: Importance.high,\n          enableVibration: true,\n        );"
    assert oc in t
    t = t.replace(oc, nc, 1)
    ofg = "  void _onForegroundMessage(RemoteMessage message) {\n    final data = _stringifyData(message.data);\n    final eventId = data['eventId'];\n    RealtimeLogger.instance.log(\n      'FCM',\n      'onMessage',\n      'type=${data['notificationType']} '\n          'title=${message.notification?.title ?? '-'}',\n      eventId: eventId,\n    );\n    if (data['notificationType'] == 'Test') {\n      _postFrameSnackFromRoot('Test push (dev)');\n      final eid = eventId?.toString();\n      if (eid != null && eid.isNotEmpty) {\n        EventDedupCache.instance.mark(eid);\n      }\n      return;\n    }\n    final isDup = EventDedupCache.instance.isDuplicate(eventId);\n    _showHeadsUp(message, isDuplicate: isDup);\n  }"
    nfg = "  void _onForegroundMessage(RemoteMessage message) {\n    final data = _stringifyData(message.data);\n    final eventId = message.data['eventId']?.toString();\n    RealtimeLogger.instance.log(\n      'FCM',\n      'foreground',\n      'data=${message.data} notification=${message.notification?.title}',\n      eventId: eventId,\n    );\n    if (data['notificationType'] == 'Test') {\n      _postFrameSnackFromRoot('Test push (dev)');\n      if (eventId != null && eventId.isNotEmpty) {\n        EventDedupCache.instance.mark(eventId);\n      }\n      return;\n    }\n    final isDup = EventDedupCache.instance.contains(eventId);\n    _showHeadsUp(message, isDuplicate: isDup);\n    if (!isDup && eventId != null && eventId.isNotEmpty) {\n      EventDedupCache.instance.mark(eventId);\n    }\n  }"
    assert ofg in t
    t = t.replace(ofg, nfg, 1)
    a = "  }\n\n  void _postFrameSnackFromRoot(String text) {"
    ins = "  }\n\n  void showInAppBanner(String title, String body, [Map<String, dynamic>? data]) {\n    final line = title.isEmpty\n        ? body\n        : (body.isEmpty ? title : '$title: $body');\n    _postFrameSnackFromRoot(line);\n  }\n\n  void maybeInAppBannerFromBusEvent(BookingRealtimeBusEvent e) {\n    late final String eventId;\n    String title = 'Rafiq';\n    String body = '';\n    if (e is BusBookingStatusChanged) {\n      if (e.event.newStatus != 'Confirmed') return;\n      eventId = e.event.eventId;\n      title = 'Booking update';\n      body = e.event.newStatus;\n    } else if (e is BusBookingTripStarted) {\n      eventId = e.event.eventId;\n      title = 'Trip started';\n      body = 'Your trip is underway.';\n    } else if (e is BusBookingTripEnded) {\n      eventId = e.event.eventId;\n      title = 'Trip ended';\n      body = 'Time to complete payment.';\n    } else if (e is BusBookingPaymentChanged) {\n      eventId = e.event.eventId;\n      title = 'Payment';\n      body = e.event.status;\n    } else {\n      return;\n    }\n    if (eventId.isNotEmpty && EventDedupCache.instance.contains(eventId)) {\n      return;\n    }\n    showInAppBanner(title, body);\n  }\n\n  void _postFrameSnackFromRoot(String text) {"
    assert a in t
    t = t.replace(a, ins, 1)
    tail = "  void debugIngestForTest(RemoteMessage m) => _onForegroundMessage(m);\n}"
    dbg = "  void debugIngestForTest(RemoteMessage m) => _onForegroundMessage(m);\n\n  void debugFakeForegroundHeadsUp() {\n    _onForegroundMessage(\n      RemoteMessage(\n        data: {\n          'eventId': 'debug-fg-${DateTime.now().millisecondsSinceEpoch}',\n          'notificationType': 'Diagnostics',\n        },\n        notification: const RemoteNotification(\n          title: 'Rafiq',\n          body: 'Synthetic foreground heads-up',\n        ),\n      ),\n    );\n  }\n\n}"
    assert tail in t
    t = t.replace(tail, dbg, 1)
    p.write_text(t, encoding="utf-8", newline="\n")
    print("messaging patched")

def write_pay_now():
    p = Path("lib/features/tourist/features/user_booking/presentation/pages/instant/pay_now_page.dart")
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(PAY_NOW_SRC, encoding="utf-8", newline="\n")
    print("pay_now written", p.stat().st_size)

PAY_NOW_SRC = r"""import 'dart:async';

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
"""

if __name__ == "__main__":
    patch_messaging()
    write_pay_now()