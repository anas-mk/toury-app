import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/router/app_router.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String bookingId;

  const PaymentSuccessPage({super.key, required this.bookingId});

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
              Icons.check_circle_rounded,
              size: 100,
              color: AppColor.accentColor,
            ),
            const SizedBox(height: AppTheme.spaceXL),
            Text(
              'Payment Successful!',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceMD),
            const Text(
              'Your booking is confirmed. You can now view the trip details and track your helper.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColor.lightTextSecondary),
            ),
            const Spacer(),
            CustomButton(
              text: 'View Booking Details',
              onPressed: () => context.goNamed(
                'booking-details',
                pathParameters: {'id': bookingId},
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
