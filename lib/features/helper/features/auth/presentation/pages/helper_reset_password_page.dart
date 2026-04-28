import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/helper_auth_cubit.dart';
import '../cubit/helper_auth_state.dart';

class HelperResetPasswordPage extends StatefulWidget {
  final String email;
  const HelperResetPasswordPage({super.key, required this.email});

  @override
  State<HelperResetPasswordPage> createState() => _HelperResetPasswordPageState();
}

class _HelperResetPasswordPageState extends State<HelperResetPasswordPage> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    codeController.dispose();
    passwordController.dispose();
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
          } else if (state is HelperAuthPasswordResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.go(AppRouter.helperLogin);
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
                  "Reset Password",
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceSM),
                Text(
                  "Enter the code sent to ${widget.email} and your new password.",
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
                      CustomTextField(
                        label: "Reset Code",
                        controller: codeController,
                        prefixIcon: Icons.lock_clock_rounded,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppTheme.spaceLG),
                      PasswordTextField(
                        controller: passwordController,
                        label: "New Password",
                      ),
                      const SizedBox(height: AppTheme.spaceXL),

                      CustomButton(
                        text: "Reset Password",
                        onPressed: _handleReset,
                        isLoading: state is HelperAuthLoading,
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

  void _handleReset() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<HelperAuthCubit>().resetPassword(
      email: widget.email,
      code: codeController.text.trim(),
      newPassword: passwordController.text.trim(),
    );
  }
}
