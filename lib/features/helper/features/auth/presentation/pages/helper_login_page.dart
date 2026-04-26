import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/localization/app_localizations.dart';
import '../../../../../../core/router/app_router.dart';
import '../cubit/helper_auth_cubit.dart';
import '../cubit/helper_auth_state.dart';

class HelperLoginPage extends StatefulWidget {
  const HelperLoginPage({super.key});

  @override
  State<HelperLoginPage> createState() => _HelperLoginPageState();
}

class _HelperLoginPageState extends State<HelperLoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _googleSignIn = GoogleSignIn(scopes: ['email']);

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<HelperAuthCubit, HelperAuthState>(
        listener: _handleHelperAuthState,
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

                    // Welcome Text
                    Text(
                      l10n.login,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spaceSM),
                    Text(
                      "Login as a Helper to start earning",
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
                          EmailTextField(
                            controller: _emailController,
                            label: l10n.email,
                          ),
                          const SizedBox(height: AppTheme.spaceXL),

                          CustomButton(
                            text: l10n.continueText,
                            onPressed: _handleContinue,
                            isLoading: state is HelperAuthLoading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXL),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMD),
                          child: Text(
                            l10n.or,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceXL),

                    // Google Sign-In
                    SocialLoginButton(
                      text: l10n.continueWithGoogle,
                      icon: Icon(Icons.g_mobiledata_rounded, size: 32, color: theme.colorScheme.secondary),
                      onPressed: _handleGoogleSignIn,
                      isLoading: state is HelperAuthLoading,
                    ),
                    const SizedBox(height: AppTheme.spaceXL),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.dontHaveAccount,
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go('${AppRouter.helperLogin}/helper-register'),
                          child: Text(
                            l10n.register,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
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
        },
      ),
    );
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    context.push('${AppRouter.helperLogin}/enter-password/$email');
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null && account.email.isNotEmpty) {
        // Implement Google Login
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _handleHelperAuthState(BuildContext context, HelperAuthState state) {
    if (state is HelperAuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
