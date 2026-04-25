import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/basic_app_bar.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/helper_auth_cubit.dart';
import '../cubit/helper_auth_state.dart';

class HelperVerifyEmailOtpPage extends StatefulWidget {
  final String email;

  const HelperVerifyEmailOtpPage({
    super.key,
    required this.email,
  });

  @override
  State<HelperVerifyEmailOtpPage> createState() => _HelperVerifyEmailOtpPageState();
}

class _HelperVerifyEmailOtpPageState extends State<HelperVerifyEmailOtpPage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int resendTimer = 0;
  Timer? _timer;
  bool canResend = true;

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startResendTimer() {
    setState(() {
      resendTimer = 60;
      canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (resendTimer > 0) {
            resendTimer--;
          } else {
            canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void resendCode() {
    if (canResend) {
      context.read<HelperAuthCubit>().resendRegistrationCode(widget.email);
      startResendTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : AppColor.primaryColor.withOpacity(0.95),
      appBar: const BasicAppBar(),
      body: SafeArea(
        child: BlocConsumer<HelperAuthCubit, HelperAuthState>(
          listener: (context, state) {
            if (state is HelperAuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
              );
            } else if (state is HelperAuthRegistrationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );

              if (state.action == 'start_onboarding') {
                context.go(AppRouter.helperHome); 
              } else if (state.helper != null || state.action == 'go_to_helper_dashboard') {
                context.go(AppRouter.helperHome);
              } else {
                context.go(AppRouter.helperLogin);
              }
            } else if (state is HelperAuthResendSuccess) {
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.email_outlined, size: 80, color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      loc.translate("verify_email") ?? "Verify Your Email",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.translate("verify_email_subtitle") ?? "We've sent a verification code to",
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              enabled: state is! HelperAuthLoading,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: "000000",
                                hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 8),
                                filled: true,
                                fillColor: isDark ? Colors.grey[850] : Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return loc.translate("field_required") ?? 'This field is required';
                                if (v.length != 6) return loc.translate("code_must_be_6_digits") ?? 'Code must be 6 digits';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: state is HelperAuthLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<HelperAuthCubit>().verifyEmail(
                                              email: widget.email,
                                              code: _codeController.text.trim(),
                                            );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColor.primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: state is HelperAuthLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      loc.translate("verify") ?? 'Verify',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: (state is HelperAuthLoading || !canResend) ? null : resendCode,
                              child: Text(
                                canResend ? (loc.translate("resend_code") ?? "Resend Code") : 'Resend in ${resendTimer}s',
                                style: TextStyle(
                                  color: (state is HelperAuthLoading || !canResend) ? Colors.grey : AppColor.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        if (context.mounted) {
                          context.go(AppRouter.roleSelection);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (context.mounted) {
                              context.push(AppRouter.helperLogin);
                            }
                          });
                        }
                      },
                      child: Text(
                        loc.translate("back_to_login") ?? "Back to Login",
                        style: const TextStyle(color: Colors.white70),
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
