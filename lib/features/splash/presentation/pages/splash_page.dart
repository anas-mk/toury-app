import 'package:flutter/material.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_theme.dart';
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

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
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

    final authService = sl<AuthService>();
    final token = authService.getToken();
    final role = authService.getRole();

    String targetRoute = AppRouter.roleSelection;

    if (token != null && token.isNotEmpty) {
      if (role == 'helper') {
        targetRoute = AppRouter.helperHome;
      } else if (role == 'tourist') {
        targetRoute = AppRouter.home;
      }
    }

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

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primary.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Decorative Elements
            Positioned(
              top: -100,
              right: -100,
              child: _buildCircle(theme.colorScheme.primary.withOpacity(0.05), 300),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: _buildCircle(theme.colorScheme.secondary.withOpacity(0.03), 200),
            ),

            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo/logo.png',
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppTheme.spaceXL),
                      SizedBox(
                        width: 40,
                        height: 2,
                        child: LinearProgressIndicator(
                          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
