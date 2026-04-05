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

    _tryNavigate();
  }

  void _tryNavigate() {
    if (!_minimumTimeElapsed || _hasNavigated) return;

    final authState = context.read<AuthCubit>().state;
    _navigateBasedOnAuth(authState);
  }

  void _navigateBasedOnAuth(AuthState state) {
    if (_hasNavigated || !_minimumTimeElapsed) return;
    _hasNavigated = true;

    print('✅ Navigating from splash - State: ${state.runtimeType}');

    if (state is AuthAuthenticated) {
      context.go(AppRouter.home);
    } else {
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
        print('🔔 Auth state changed: ${state.runtimeType}');
        if (state is! AuthLoading && state is! AuthInitial) {
          _tryNavigate();
        }
      },
      child: Scaffold(
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
                    color: isDark ? Colors.white : Colors.white,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}