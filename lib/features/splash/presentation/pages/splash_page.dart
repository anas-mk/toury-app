import 'package:flutter/material.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../helper/features/auth/data/datasources/helper_local_data_source.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isNavigated = false;
  bool _minimumTimeElapsed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _ensureMinimumDisplayTime();
  }

  void _ensureMinimumDisplayTime() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _minimumTimeElapsed = true;
    });

    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    if (!_minimumTimeElapsed || _isNavigated) return;

    final localDataSource = sl<HelperLocalDataSource>();
    final helper = await localDataSource.getCurrentHelper();
    
    // Debug Logs
    print('--- 🌊 SPLASH AUTH AUDIT ---');
    print('Token: ${helper?.token ?? "NULL"}');
    print('Helper Data: ${helper?.fullName ?? "NULL"} (ID: ${helper?.helperId ?? "N/A"})');
    print('Approval Status: ${helper?.isApproved ?? "N/A"}');
    print('Active Status: ${helper?.isActive ?? "N/A"}');

    String targetRoute = AppRouter.roleSelection;

    if (helper == null || helper.token == null || helper.token!.isEmpty) {
      targetRoute = AppRouter.roleSelection;
    } else {
      // Priority Routing Logic
      targetRoute = AppRouter.helperHome;
    }

    print('Final Selected Route: $targetRoute');
    print('---------------------------');

    if (mounted && !_isNavigated) {
      _isNavigated = true;
      context.go(targetRoute);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : theme.primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/logo/logo.png',
              height: 230,
              width: 230,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.travel_explore,
                  size: 120,
                  color: Colors.white,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}