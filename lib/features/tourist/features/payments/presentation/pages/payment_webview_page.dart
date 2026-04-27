import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../../../core/di/injection_container.dart';
import '../../../../../../core/services/signalr/booking_hub_events.dart';
import '../../../../../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/payment_cubit.dart';
import '../cubit/payment_state.dart';

class PaymentWebviewPage extends StatefulWidget {
  final String paymentUrl;
  final String paymentId;
  final String bookingId;

  const PaymentWebviewPage({
    super.key,
    required this.paymentUrl,
    required this.paymentId,
    required this.bookingId,
  });

  @override
  State<PaymentWebviewPage> createState() => _PaymentWebviewPageState();
}

class _PaymentWebviewPageState extends State<PaymentWebviewPage> {
  late final WebViewController _controller;
  StreamSubscription<BookingPaymentChangedEvent>? _paymentSub;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('🌐 WebView Loading: $url');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    // The mock gateway POSTs back to the server which then pushes a
    // `BookingPaymentChanged` event. The WebView URL itself is NOT a
    // reliable success/failure source — we only trust the SignalR event.
    final hub = sl<BookingTrackingHubService>();
    _paymentSub = hub.bookingPaymentChangedStream
        .where((e) => e.bookingId == widget.bookingId)
        .listen(_onPaymentChanged);
  }

  void _onPaymentChanged(BookingPaymentChangedEvent event) {
    if (_resolved || !mounted) return;
    // Backend emits the C# `PaymentStatus` enum name verbatim:
    //   NotRequired | AwaitingPayment | PaymentPending | Paid | Refunded | Failed
    // Only `Paid` and `Failed` are terminal for this WebView; everything else
    // means we keep waiting.
    switch (event.status) {
      case 'Paid':
        _resolved = true;
        context.read<PaymentCubit>().completeMockPayment(widget.paymentId, true);
        break;
      case 'Failed':
        _resolved = true;
        context.read<PaymentCubit>().completeMockPayment(widget.paymentId, false);
        break;
      default:
        // NotRequired | AwaitingPayment | PaymentPending | Refunded → wait.
        break;
    }
  }

  @override
  void dispose() {
    _paymentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentCubit, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          context.go(AppRouter.paymentSuccess, extra: widget.bookingId);
        } else if (state is PaymentFailed) {
          context.go(AppRouter.paymentFailed, extra: widget.bookingId);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 16, color: AppColor.accentColor),
              SizedBox(width: 8),
              Text('Secure Payment'),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showCancelDialog(),
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('Are you sure you want to exit? Your payment will not be processed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Go back to payment method
            },
            child: const Text('Cancel', style: TextStyle(color: AppColor.errorColor)),
          ),
        ],
      ),
    );
  }
}
