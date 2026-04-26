import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/router/app_router.dart';
import '../../domain/entities/payment_entity.dart';

class PaymentProcessingPage extends StatefulWidget {
  final PaymentEntity payment;

  const PaymentProcessingPage({super.key, required this.payment});

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  @override
  void initState() {
    super.initState();
    // Simulate a brief delay before opening webview
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.pushReplacement(
          AppRouter.paymentWebview,
          extra: {
            'paymentUrl': widget.payment.paymentUrl,
            'paymentId': widget.payment.paymentId,
            'bookingId': widget.payment.bookingId,
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColor.primaryColor),
            const SizedBox(height: AppTheme.spaceXL),
            Text(
              'Processing your payment...',
              style: AppTheme.displayLarge,
            ),
            const SizedBox(height: AppTheme.spaceSM),
            const Text(
              'Please do not close this screen',
              style: TextStyle(color: AppColor.lightTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
