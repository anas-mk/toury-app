import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../tourist/features/auth/presentation/cubit/auth_cubit.dart';
import '../../../tourist/features/auth/presentation/cubit/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

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

    // Start navigation after animation
    _startNavigation();
  }

  void _startNavigation() async {
    // Wait for splash animation (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _hasNavigated) return;

    // Check auth state
    final authState = context.read<AuthCubit>().state;

    _navigateBasedOnAuth(authState);
  }

  void _navigateBasedOnAuth(AuthState state) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    if (state is AuthAuthenticated) {
      // ✅ User is logged in → go to home
      context.go(AppRouter.home);
    } else {
      // ✅ User is not logged in → go to role selection
      context.go(AppRouter.roleSelection);
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

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Listen for auth changes after initial load
        if (!_hasNavigated) {
          _navigateBasedOnAuth(state);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : theme.primaryColor,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with error handling
                  Image.asset(
                    'assets/logo/logo.png',
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.travel_explore,
                        size: 120,
                        color: isDark ? Colors.white : Colors.blue,
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // App Name
                  Text(
                    'Toury',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Your Travel Companion',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Loading Indicator
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}