import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../../../../core/localization/app_localizations.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _googleSignIn = GoogleSignIn(scopes: ['email']);

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

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
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: _handleAuthState,
        builder: (context, state) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLG,
                ),
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
                      "Enter your email to continue",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.space2XL),

                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          EmailTextField(
                            controller: _emailController,
                            label: l10n.email,
                            hintText: "example@email.com",
                          ),
                          const SizedBox(height: AppTheme.spaceXL),

                          CustomButton(
                            text: l10n.continueText,
                            onPressed: _handleContinue,
                            isLoading: state is AuthLoading,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.space2XL),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceMD,
                          ),
                          child: Text(
                            l10n.or,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.4,
                              ),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: AppTheme.space2XL),

                    // Social Login
                    SocialLoginButton(
                      text: l10n.continueWithGoogle,
                      icon: const Icon(
                        Icons.g_mobiledata_rounded,
                        size: 32,
                        color: AppColor.secondaryColor,
                      ),
                      onPressed: _handleGoogleSignIn,
                      isLoading: state is AuthLoading,
                    ),

                    const SizedBox(height: AppTheme.space2XL),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.dontHaveAccount,
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go(
                            '${AppRouter.login}/${AppRouter.register}',
                          ),
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
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    context.read<AuthCubit>().checkEmail(email);
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null && account.email.isNotEmpty) {
        if (mounted) {
          context.read<AuthCubit>().googleLogin(account.email);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Google sign-in failed: ${e.toString()}');
      }
    }
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthError) {
      AppSnackbar.error(context, state.message);
    } else if (state is AuthEmailExists) {
      context.go('${AppRouter.login}/enter-password/${state.email}');
    } else if (state is AuthGoogleRegistrationNeeded) {
      context.go('${AppRouter.login}/${AppRouter.register}');
    } else if (state is AuthGoogleVerificationNeeded) {
      context.go('${AppRouter.login}/verify-google-code/${state.email}');
    }
  }
}
