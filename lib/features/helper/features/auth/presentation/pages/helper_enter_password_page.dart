import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/helper_auth_cubit.dart';
import '../cubit/helper_auth_state.dart';

class HelperEnterPasswordPage extends StatefulWidget {
  final String email;
  const HelperEnterPasswordPage({super.key, required this.email});

  @override
  State<HelperEnterPasswordPage> createState() => _HelperEnterPasswordPageState();
}

class _HelperEnterPasswordPageState extends State<HelperEnterPasswordPage> with SingleTickerProviderStateMixin {
  final TextEditingController passwordController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<HelperAuthCubit, HelperAuthState>(
        listener: (context, state) {
          if (state is HelperAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is HelperAuthLoginOtpRequired) {
            context.push('${AppRouter.helperLogin}/${AppRouter.helperVerifyCode.replaceAll(':email', state.email)}');
          } else if (state is HelperAuthAuthenticated) {
            context.go(AppRouter.helperHome);
          }
        },
        builder: (context, state) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spaceLG),
                    // Logo
                    Center(
                      child: Hero(
                        tag: 'app-logo',
                        child: Image.asset(
                          'assets/logo/logo.png',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXL),

                    // Title
                    Text(
                      loc.translate("enter_password_title") ?? "Enter Your Password",
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      "Login to your account as ${widget.email}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.space2XL),

                    // Form
                    PasswordTextField(
                      controller: passwordController,
                      label: loc.translate("password") ?? "Password",
                      enabled: state is! HelperAuthLoading,
                    ),
                    const SizedBox(height: AppTheme.spaceLG),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: state is HelperAuthLoading
                            ? null
                            : () => context.go('${AppRouter.helperLogin}/${AppRouter.forgotPassword}'),
                        child: Text(
                          loc.translate("forgot_password") ?? "Forgot Password?",
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXL),

                    CustomButton(
                      text: loc.translate("login_button") ?? "Login",
                      onPressed: _handleLogin,
                      isLoading: state is HelperAuthLoading,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleLogin() {
    final password = passwordController.text.trim();
    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<HelperAuthCubit>().login(
          email: widget.email,
          password: password,
        );
  }
}
