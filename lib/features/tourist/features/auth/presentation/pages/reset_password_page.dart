import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isPasswordObscured = true;
  bool isConfirmPasswordObscured = true;

  // ✅ Resend code timer
  int resendTimer = 0;
  Timer? _timer;
  bool canResend = true;

  @override
  void dispose() {
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ✅ Start resend timer
  void startResendTimer() {
    setState(() {
      resendTimer = 60; // 60 seconds
      canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (resendTimer > 0) {
          resendTimer--;
        } else {
          canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // ✅ Resend password reset code
  void resendCode() {
    if (canResend) {
      context.read<AuthCubit>().resendVerificationCode(widget.email);
      startResendTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFF0B3D91),
      appBar: const BasicAppBar(),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } else if (state is AuthPasswordResetSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              // Navigate to login page
              context.go(AppRouter.login);
            } else if (state is AuthResendCodeSuccess) {
              // ✅ Show success message when code is resent
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Image.asset(
                      'assets/logo/logo.png',
                      height: 160,
                    ),
                    const SizedBox(height: 24),

                    // Card Container
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Reset Password",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColor.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the code sent to ${widget.email}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Reset Code Field
                            TextFormField(
                              controller: codeController,
                              enabled: state is! AuthLoading,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Reset Code',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.grey[700],
                                ),
                                prefixIcon: Icon(
                                  Icons.password_outlined,
                                  color: isDark ? Colors.white70 : AppColor.primaryColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the reset code';
                                }
                                if (value.length < 4) {
                                  return 'Code must be at least 4 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),

                            // ✅ Resend Code Button with Timer
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: (state is AuthLoading || !canResend)
                                    ? null
                                    : resendCode,
                                child: Text(
                                  canResend
                                      ? 'Resend Code'
                                      : 'Resend in ${resendTimer}s',
                                  style: TextStyle(
                                    color: (state is AuthLoading || !canResend)
                                        ? Colors.grey
                                        : AppColor.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // New Password Field
                            TextFormField(
                              controller: passwordController,
                              enabled: state is! AuthLoading,
                              obscureText: isPasswordObscured,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.grey[700],
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: isDark ? Colors.white70 : AppColor.primaryColor,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isPasswordObscured
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: isDark ? Colors.white70 : AppColor.primaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isPasswordObscured = !isPasswordObscured;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter new password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            TextFormField(
                              controller: confirmPasswordController,
                              enabled: state is! AuthLoading,
                              obscureText: isConfirmPasswordObscured,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.grey[700],
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: isDark ? Colors.white70 : AppColor.primaryColor,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    isConfirmPasswordObscured
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: isDark ? Colors.white70 : AppColor.primaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isConfirmPasswordObscured = !isConfirmPasswordObscured;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Reset Button
                            ElevatedButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthCubit>().resetPassword(
                                    email: widget.email,
                                    code: codeController.text.trim(),
                                    newPassword: passwordController.text.trim(),
                                  );
                                }
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
                                  : const Text(
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Back to Login Button
                            TextButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                context.go(AppRouter.login);
                              },
                              child: Text(
                                'Back to Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}