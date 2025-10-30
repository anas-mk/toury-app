import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toury/features/tourist/features/auth/presentation/pages/role_selection_page.dart';
import 'package:toury/features/tourist/features/home/presentation/pages/home_layout.dart';
import 'package:toury/features/tourist/features/auth/data/models/user_model.dart';
import 'package:toury/core/theme/app_color.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutBack,
      ),
    );

    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    final user = await _getCurrentUser();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 900),
      pageBuilder: (_, animation, __) => FadeTransition(
        opacity: animation,
        child: user != null ? const HomeLayout() : const RoleSelectionPage(),
      ),
    ));
  }

  Future<UserModel?> _getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;
    try {
      final Map<String, dynamic> data = jsonDecode(userJson);
      return UserModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg1 =
    isDark ? Colors.black : AppColor.primaryColor;
    final Color bg2 =
    isDark ? Colors.grey.shade900 : AppColor.primaryColor.withOpacity(0.8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final animatedColor1 =
        Color.lerp(bg1, bg2, _controller.value)!;
        final animatedColor2 =
        Color.lerp(bg2, bg1, _controller.value)!;

        return Scaffold(
          backgroundColor: animatedColor1,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [animatedColor1, animatedColor2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    'assets/logo/logo.png',
                    height: 180,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
