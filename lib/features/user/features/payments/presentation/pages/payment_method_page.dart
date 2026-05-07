import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/payment_cubit.dart';
import '../cubit/payment_state.dart';

class PaymentMethodPage extends StatefulWidget {
  final String bookingId;

  const PaymentMethodPage({super.key, required this.bookingId});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String _selectedMethod = 'MockCard'; // Default method

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return BlocListener<PaymentCubit, PaymentState>(
      listener: (context, state) {
        // Cash settles synchronously: backend returns `status: Paid` directly,
        // the cubit emits `PaymentSuccess`, we navigate without WebView.
        if (state is PaymentSuccess) {
          context.go(AppRouter.paymentSuccess, extra: widget.bookingId);
        } else if (state is PaymentInitiated) {
          // Online methods (MockCard etc.) — open the gateway WebView and
          // wait for SignalR `BookingPaymentChanged` → Paid|Failed.
          context.push(AppRouter.paymentProcessing, extra: state.payment);
        } else if (state is PaymentFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColor.errorColor),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.translate('payment_method')),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('choose_payment_method'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spaceXL),
              
              _buildMethodTile(
                id: 'MockCard',
                title: loc.translate('credit_card'),
                subtitle: 'Pay via secure mock gateway',
                icon: Icons.credit_card_rounded,
              ),
              const SizedBox(height: AppTheme.spaceMD),
              _buildMethodTile(
                id: 'Cash',
                title: loc.translate('cash'),
                subtitle: loc.translate('pay_to_helper'),
                icon: Icons.payments_rounded,
              ),
              
              const Spacer(),
              
              BlocBuilder<PaymentCubit, PaymentState>(
                builder: (context, state) {
                  return CustomButton(
                    text: loc.translate('pay_now'),
                    isLoading: state is PaymentLoading,
                    onPressed: () {
                      context.read<PaymentCubit>().initiatePayment(
                        widget.bookingId,
                        _selectedMethod,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: AppTheme.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == id;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primaryColor.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(
            color: isSelected ? AppColor.primaryColor : AppColor.lightBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColor.primaryColor : AppColor.lightTextSecondary),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _selectedMethod,
              activeColor: AppColor.primaryColor,
              onChanged: (val) => setState(() => _selectedMethod = val!),
            ),
          ],
        ),
      ),
    );
  }
}
