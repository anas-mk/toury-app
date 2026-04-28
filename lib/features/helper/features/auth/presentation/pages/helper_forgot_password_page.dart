import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/helper_auth_cubit.dart';
import '../cubit/helper_auth_state.dart';

class HelperForgotPasswordPage extends StatefulWidget {
  const HelperForgotPasswordPage({super.key});

  @override
  State<HelperForgotPasswordPage> createState() => _HelperForgotPasswordPageState();
}

class _HelperForgotPasswordPageState extends State<HelperForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
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
          } else if (state is HelperAuthForgotPasswordSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.push(
              '${AppRouter.helperLogin}/${AppRouter.forgotPassword}/${AppRouter.resetPassword}',
              extra: state.email,
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

                Text(
                  "Forgot Password?",
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  "Enter your helper email and we'll send you a code to reset your password.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space2XL),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EmailTextField(
                        controller: emailController,
                        label: "Email Address",
                      ),
                      const SizedBox(height: AppTheme.spaceXL),

                      CustomButton(
                        text: "Send Reset Code",
                        onPressed: _handleSendCode,
                        isLoading: state is HelperAuthLoading,
                      ),

                      const SizedBox(height: AppTheme.spaceLG),

                      Center(
                        child: TextButton(
                          onPressed: state is HelperAuthLoading ? null : () => context.go(AppRouter.helperLogin),
                          child: Text(
                            "Back to Login",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleSendCode() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<HelperAuthCubit>().forgotPassword(emailController.text.trim());
  }
}
