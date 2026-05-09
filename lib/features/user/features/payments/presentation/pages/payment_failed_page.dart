import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/router/app_router.dart';

class PaymentFailedPage extends StatelessWidget {
  final String bookingId;

  const PaymentFailedPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(
              Icons.error_outline_rounded,
              size: 100,
              color: AppColor.errorColor,
            ),
            const SizedBox(height: AppTheme.spaceXL),
            Text(
              'Payment Failed',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            const Text(
              'Something went wrong with your transaction. Please try again or use a different payment method.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColor.lightTextSecondary),
            ),
            const Spacer(),
            CustomButton(
              text: 'Try Again',
              onPressed: () => context.goNamed(
                'payment-method',
                pathParameters: {'bookingId': bookingId},
              ),
            ),
            const SizedBox(height: AppTheme.spaceMD),
            CustomButton(
              text: 'Go to Home',
              variant: ButtonVariant.text,
              onPressed: () => context.go(AppRouter.home),
            ),
            const SizedBox(height: AppTheme.spaceXL),
          ],
        ),
      ),
    );
  }
}
