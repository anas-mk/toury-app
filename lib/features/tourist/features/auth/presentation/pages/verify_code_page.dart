import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;

  const VerifyCodePage({
    super.key,
    required this.email,
  });

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
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
      if (!mounted) return;
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

  void resendCode() {
    if (canResend) {
      context.read<AuthCubit>().resendVerificationCode(widget.email);
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
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is AuthVerificationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) context.go(AppRouter.login);
            });
          } else if (state is AuthResendCodeSuccess) {
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
                const SizedBox(height: AppTheme.spaceLG),
                // Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceXL),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),

                // Title
                Text(
                  loc.translate("verify_email") ?? "Verify Your Email",
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  "${loc.translate("verify_email_subtitle") ?? "We've sent a code to"}\n${widget.email}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space2XL),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: state is! AuthLoading,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 12,
                          color: theme.colorScheme.primary,
                        ),
                        decoration: InputDecoration(
                          hintText: "000000",
                          hintStyle: theme.textTheme.displayMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            letterSpacing: 12,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLG),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Code is required';
                          if (v.length != 6) return 'Code must be 6 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.space2XL),

                      CustomButton(
                        text: loc.translate("verify") ?? 'Verify',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthCubit>().verifyRegistrationCode(
                              email: widget.email,
                              code: _codeController.text.trim(),
                            );
                          }
                        },
                        isLoading: state is AuthLoading,
                      ),
                      const SizedBox(height: AppTheme.spaceLG),

                      // Resend Timer
                      Center(
                        child: TextButton(
                          onPressed: (state is AuthLoading || !canResend) ? null : resendCode,
                          child: Text(
                            canResend
                                ? (loc.translate("resend_code") ?? "Resend Code")
                                : 'Resend in ${resendTimer}s',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: canResend ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRouter.login),
                    child: Text(
                      loc.translate("back_to_login") ?? "Back to Login",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
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
