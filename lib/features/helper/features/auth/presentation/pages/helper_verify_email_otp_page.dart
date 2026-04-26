import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_button.dart';
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
              SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error),
            );
          } else if (state is HelperAuthRegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Verification Successful!"), backgroundColor: Colors.green),
            );
            context.go(AppRouter.helperHome);
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
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.space2XL),
                // Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceXL),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space2XL),

                Text(
                  loc.translate("verify_email") ?? "Verify Your Email",
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  loc.translate("verify_email_subtitle") ?? "We've sent a verification code to",
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space2XL),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: state is! HelperAuthLoading,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: "000000",
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                            letterSpacing: 12,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXL),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length != 6) return 'Must be 6 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space2XL),

                      CustomButton(
                        text: loc.translate("verify") ?? 'Verify',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<HelperAuthCubit>().verifyEmail(
                                  email: widget.email,
                                  code: _codeController.text.trim(),
                                );
                          }
                        },
                        isLoading: state is HelperAuthLoading,
                      ),
                      const SizedBox(height: AppTheme.spaceLG),

                      TextButton(
                        onPressed: (state is HelperAuthLoading || !canResend) ? null : resendCode,
                        child: Text(
                          canResend ? (loc.translate("resend_code") ?? "Resend Code") : 'Resend in ${resendTimer}s',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: (state is HelperAuthLoading || !canResend) ? theme.colorScheme.onSurface.withOpacity(0.4) : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                TextButton(
                  onPressed: () => context.go(AppRouter.helperLogin),
                  child: Text(
                    loc.translate("back_to_login") ?? "Back to Login",
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
