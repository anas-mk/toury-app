import 'package:flutter/material.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_navigator.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/CustomCard.dart';
import '../../../../../../core/widgets/custom_button.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    final gradientColors = isDarkMode
        ? [const Color(0xFF0A0A0A), const Color(0xFF1A1A1A)]
        : [AppColor.primaryColor, const Color(0xFF4C84FF)];

    final textColor = isDarkMode ? Colors.white70 : Colors.white;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Image.asset(
                            'assets/logo/logo.png',
                            height: 180,
                          ),
                          const SizedBox(height: 30),

                          // Card
                          CustomCard(
                          backgroundColor: isDarkMode
                                ? Colors.grey[900]
                                : Colors.white.withOpacity(0.95),
                            child: Column(
                              children: [
                                Text(
                                  loc.translate("continue_as"),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? Colors.white
                                        : AppColor.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                _buildTouristButton(context,loc),
                                const SizedBox(height: 20),
                                _buildGuideButton(context,loc),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Footer
                          Text(
                            loc.translate("select_role"),
                            style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTouristButton(BuildContext context,AppLocalizations loc) {
    return CustomButton(
      text:  loc.translate("tourist") ,
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

  Widget _buildGuideButton(BuildContext context,AppLocalizations loc) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return OutlinedButton.icon(
      onPressed: () {
        AppNavigator.push(context, const LoginPage());
      },
      label: Text(
        loc.translate("guide"),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : AppColor.primaryColor,
        ),
      ),
      icon: const Icon(Icons.map_outlined, size: 20),
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
