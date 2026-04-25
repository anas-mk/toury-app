import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../domain/entities/payment_entity.dart';
import '../cubit/payment_cubit.dart';

class PaymentMethodPage extends StatefulWidget {
  final String bookingId;

  const PaymentMethodPage({super.key, required this.bookingId});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String _selectedMethod = 'MockCard';

  @override
  void initState() {
    super.initState();
    context.read<PaymentCubit>().getLatestPayment(widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentWebviewOpen) {
            context.pushReplacement('/payment-webview', extra: {
              'paymentUrl': state.paymentUrl,
              'paymentId': state.paymentId,
              'bookingId': widget.bookingId,
            });
          } else if (state is PaymentSuccess) {
            context.pushReplacement('/payment-success', extra: widget.bookingId);
          } else if (state is PaymentFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is PaymentCreated) {
            // If payment was already created and is pending, we can still change method or continue
            // Usually, if it's already created, we might want to just proceed to processing
            // but for this flow, we let them pick method until they hit 'Continue'
          }
        },
        builder: (context, state) {
          PaymentEntity? payment;
          if (state is PaymentCreated) payment = state.payment;
          if (state is PaymentSuccess) payment = state.payment;

          final phase = payment?.phase ?? 'Full';
          final amount = payment?.amount ?? 0.0;
          final currency = payment?.currency ?? 'EGP';

          String titleText = "Pay Full Amount";
          String buttonText = "Confirm Payment";

          if (phase == 'Deposit') {
            titleText = "Pay Deposit";
            buttonText = "Confirm Deposit";
          } else if (phase == 'Remaining') {
            titleText = "Pay Remaining Balance";
            buttonText = "Complete Payment";
          } else if (phase == 'Full') {
            titleText = "Pay Full Amount";
            buttonText = "Confirm Payment";
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: $amount $currency',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
                const Text(
                  'How would you like to pay?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 15),
                _buildMethodOption(
                  title: 'Credit / Debit Card',
                  subtitle: 'Pay securely using mock gateway',
                  value: 'MockCard',
                  icon: Icons.credit_card,
                ),
                const SizedBox(height: 15),
                _buildMethodOption(
                  title: 'Cash',
                  subtitle: 'Pay helper directly',
                  value: 'Cash',
                  icon: Icons.money,
                ),
                const Spacer(),
                if (state is PaymentLoading)
                  const Center(child: CircularProgressIndicator(color: AppColor.primaryColor))
                else
                  CustomButton(
                    text: buttonText,
                    onPressed: () {
                      context.read<PaymentCubit>().initiatePayment(widget.bookingId, _selectedMethod);
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMethodOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColor.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: isSelected ? AppColor.primaryColor : Colors.grey.shade600),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColor.primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColor.primaryColor),
          ],
        ),
      ),
    );
  }
}
