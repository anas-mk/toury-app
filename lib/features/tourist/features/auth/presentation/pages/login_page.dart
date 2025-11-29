import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final backgroundColor =
    isDarkMode ? const Color(0xFF0A0A0A) : AppColor.primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const BasicAppBar(),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: _handleAuthState,
          builder: (context, state) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/logo/logo.png', height: 180),
                      const SizedBox(height: 30),
                      _buildGlassCard(context, state, isDarkMode, l10n),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassCard(
      BuildContext context,
      AuthState state,
      bool isDarkMode,
      dynamic l10n,
      ) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                l10n.login,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColor.primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // Email Input
              CustomTextField(
                hintText: l10n.email,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                fillColor: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
                borderRadius: 16,
                onChanged: (value) {},
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return l10n.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Continue Button
              ElevatedButton(
                onPressed: state is AuthLoading
                    ? null
                    : () {
                  final email = emailController.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.invalidEmail)),
                    );
                    return;
                  }
                  context.read<AuthCubit>().checkEmail(email);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state is AuthLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  l10n.continueText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.or,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? Colors.white70
                            : Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // Google Sign-In
              OutlinedButton.icon(
                onPressed: state is AuthLoading
                    ? null
                    : () => _handleGoogleSignIn(context, l10n),
                icon: Icon(Icons.g_mobiledata,
                    size: 30,
                    color: isDarkMode ? Colors.white : AppColor.primaryColor),
                label: Text(
                  l10n.continueWithGoogle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColor.primaryColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: AppColor.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Register Redirect
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.dontHaveAccount,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('${AppRouter.login}/${AppRouter.register}');
                    },
                    child: Text(
                      l10n.register,
                      style: TextStyle(
                        color: AppColor.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    } else if (state is AuthEmailExists) {
      // ✅ استخدم GoRouter للتنقل
      context.go('${AppRouter.login}/enter-password/${state.email}');
    } else if (state is AuthGoogleRegistrationNeeded) {
      // ✅ استخدم GoRouter
      context.go('${AppRouter.login}/${AppRouter.register}');
    } else if (state is AuthGoogleVerificationNeeded) {
      // ✅ استخدم GoRouter
      context.go('${AppRouter.login}/verify-google-code/${state.email}');
    } else if (state is AuthAuthenticated) {
      // ✅ استخدم GoRouter للذهاب للصفحة الرئيسية
      context.go(AppRouter.home);
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context, dynamic l10n) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null && account.email.isNotEmpty) {
        if (mounted) {
          context.read<AuthCubit>().googleLogin(account.email);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.googleSignInCancelled)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = l10n.googleSignInFailed;
        if (e.toString().contains('ApiException: 10')) {
          errorMessage = l10n.googleSignInNotConfigured;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(errorMessage), backgroundColor: Colors.orange),
        );
      }
    }
  }
}