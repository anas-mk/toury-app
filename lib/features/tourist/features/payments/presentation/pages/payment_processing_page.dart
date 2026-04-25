import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../domain/entities/payment_entity.dart';
import '../cubit/payment_cubit.dart';

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
    // Usually this page might wait for a SignalR event.
    // If it's cash, it might just succeed immediately via backend.
    if (widget.payment.status == 'Paid') {
      Future.microtask(() {
        if (mounted) {
          context.pushReplacement('/payment-success', extra: widget.payment.bookingId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            context.pushReplacement('/payment-success', extra: widget.payment.bookingId);
          } else if (state is PaymentFailed) {
            context.pushReplacement('/payment-failed', extra: widget.payment.bookingId);
          }
        },
        child: Container(
          width: double.infinity,
          color: AppColor.primaryColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 30),
              const Text(
                'Waiting for confirmation...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Amount: ${widget.payment.currency} ${widget.payment.amount}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
