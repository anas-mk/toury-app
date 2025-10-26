import 'package:flutter/material.dart';
import '../../../../../../core/router/app_navigator.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/CustomCard.dart';
import '../../../../../../core/widgets/custom_button.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode
        ? const Color(0xFF0A0A0A)
        : const Color(0xFF0B3D91);

    final textColor = isDarkMode ? Colors.white : Colors.white.withOpacity(0.9);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/logo/logo.png',
                  height: 200,
                ),
                const SizedBox(height: 30),

                // Card Container
                CustomCard(
                  child: Column(
                    children: [
                      _buildContinueAsText(isDarkMode),
                      const SizedBox(height: 30),
                      _buildTouristButton(context),
                      const SizedBox(height: 20),
                      _buildGuideButton(context),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Footer
                Text(
                  'Select your role to continue',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Continue As Text
  Widget _buildContinueAsText(bool isDarkMode) {
    return Text(
      "Continue as",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : AppColor.primaryColor,
      ),
    );
  }

  // Tourist Button
  Widget _buildTouristButton(BuildContext context) {
    return CustomButton(
      text: 'Tourist',
      color: AppColor.primaryColor,
      height: 55,
      borderRadius: 16,
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      onPressed: () {
        AppNavigator.push(context, const LoginPage());
      },
    );
  }

  // Guide Button
  Widget _buildGuideButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton.icon(
      onPressed: () {
        AppNavigator.push(context, const LoginPage());
      },
      label: Text(
        'Guide',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : AppColor.primaryColor,
        ),
      ),

      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        side: BorderSide(
          color: AppColor.primaryColor,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
