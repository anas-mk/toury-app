import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/widgets/custom_button.dart';

class PaymentFailedPage extends StatelessWidget {
  final String bookingId;

  const PaymentFailedPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 100,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Payment Failed',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'We could not process your payment at this time. Please try another payment method.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Try Another Method',
                onPressed: () {
                  context.pushReplacement('/payment-method/$bookingId');
                },
              ),
              const SizedBox(height: 15),
              CustomButton(
                text: 'Back to Home',
                variant: ButtonVariant.outlined,
                onPressed: () {
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
