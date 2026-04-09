import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
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

class _HelperEnterPasswordPageState extends State<HelperEnterPasswordPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController passwordController = TextEditingController();
  bool isObscured = true;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
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
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : AppColor.primaryColor,
      appBar: const BasicAppBar(),
      body: SafeArea(
        child: BlocConsumer<HelperAuthCubit, HelperAuthState>(
          listener: (context, state) {
            if (state is HelperAuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } else if (state is HelperAuthLoginOtpRequired) {
              // Navigate to Verify OTP page
              context.push('${AppRouter.helperLogin}/${AppRouter.helperVerifyCode.replaceAll(':email', state.email)}');
            } else if (state is HelperAuthAuthenticated) {
              context.go(AppRouter.helperHome);
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo
                        Image.asset(
                          'assets/logo/logo.png',
                          height: 160,
                        ),
                        const SizedBox(height: 24),

                        // Password Card
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[900] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                loc.translate("enter_password_title") ??
                                    "Enter Your Password",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : AppColor.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              TextField(
                                controller: passwordController,
                                obscureText: isObscured,
                                enabled: state is! HelperAuthLoading,
                                decoration: InputDecoration(
                                  labelText:
                                  loc.translate("password") ?? "Password",
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey.shade700,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColor.primaryColor,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: AnimatedSwitcher(
                                      duration:
                                      const Duration(milliseconds: 250),
                                      transitionBuilder:
                                          (child, animation) =>
                                          ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                      child: Icon(
                                        isObscured
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        key: ValueKey<bool>(isObscured),
                                        color: isDark
                                            ? Colors.white70
                                            : AppColor.primaryColor,
                                      ),
                                    ),
                                    onPressed: state is HelperAuthLoading
                                        ? null
                                        : () {
                                      setState(() {
                                        isObscured = !isObscured;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Login Button
                              ElevatedButton(
                                onPressed: state is HelperAuthLoading
                                    ? null
                                    : () {
                                  final password =
                                  passwordController.text.trim();
                                  if (password.isEmpty ||
                                      password.length < 6) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          loc.translate(
                                              "invalid_password") ??
                                              "Password must be at least 6 characters",
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  context
                                      .read<HelperAuthCubit>()
                                      .login(
                                    email: widget.email,
                                    password: password,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize:
                                  const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: state is HelperAuthLoading
                                    ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Text(
                                  loc.translate("login_button") ??
                                      "Login",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextButton(
                                onPressed: state is HelperAuthLoading
                                    ? null
                                    : () {
                                  context.go(
                                      '${AppRouter.helperLogin}/${AppRouter.forgotPassword}');
                                },
                                child: Text(
                                  loc.translate("forgot_password") ??
                                      "Forgot Password?",
                                  style: TextStyle(
                                    color: AppColor.primaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}