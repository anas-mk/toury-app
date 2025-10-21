import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/pages/role_selection_page.dart';
import '../../../home/presentation/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  void _checkUserSession() async {
    // Wait a bit for splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Check if user is already logged in
      context.read<AuthCubit>().getCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColor.primaryColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo/logo.png',
                height: 200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
