import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../cubit/payment_cubit.dart';

class PaymentWebviewPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Payment Gateway', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Simulate cancel callback
            context.read<PaymentCubit>().mockPaymentComplete(paymentId, 'cancel');
          },
        ),
      ),
      body: BlocConsumer<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            context.pushReplacement('/payment-success', extra: bookingId);
          } else if (state is PaymentFailed) {
            context.pushReplacement('/payment-failed', extra: bookingId);
          }
        },
        builder: (context, state) {
          if (state is PaymentProcessing || state is PaymentLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Processing Payment...', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 64, color: Colors.blueGrey),
                const SizedBox(height: 20),
                const Text(
                  'Secure Checkout',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'URL: $paymentUrl',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: [
                      CustomButton(
                        text: 'Simulate Success',
                        color: Colors.green,
                        onPressed: () {
                          context.read<PaymentCubit>().mockPaymentComplete(paymentId, 'succeed');
                        },
                      ),
                      const SizedBox(height: 15),
                      CustomButton(
                        text: 'Simulate Insufficient Funds',
                        color: Colors.orange,
                        onPressed: () {
                          context.read<PaymentCubit>().mockPaymentComplete(paymentId, 'fail_insufficient');
                        },
                      ),
                      const SizedBox(height: 15),
                      CustomButton(
                        text: 'Simulate Network Fail',
                        color: Colors.red,
                        onPressed: () {
                          context.read<PaymentCubit>().mockPaymentComplete(paymentId, 'fail_network');
                        },
                      ),
                      const SizedBox(height: 15),
                      CustomButton(
                        text: 'Cancel Payment',
                        variant: ButtonVariant.outlined,
                        onPressed: () {
                          context.read<PaymentCubit>().mockPaymentComplete(paymentId, 'cancel');
                        },
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
}
