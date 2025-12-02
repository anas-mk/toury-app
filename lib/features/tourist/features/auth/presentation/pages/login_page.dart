// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/theme/app_color.dart';
import '../../../../../../core/widgets/custom_text_field.dart';
import '../../../../../../core/widgets/custom_button.dart';
import '../../../../../../core/widgets/custom_card.dart';
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
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
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
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: _handleAuthState,
          builder: (context, state) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      floating: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceLG),
                        child: Column(
                          children: [
                            // Logo
                            Hero(
                              tag: 'app-logo',
                              child: Image.asset(
                                'assets/logo/logo.png',
                                height: 140,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceSM),

                            // Welcome Text
                            Text(
                              l10n.login,
                              style: AppTheme.displayLarge.copyWith(
                                color: theme.colorScheme.onSecondary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceSM),
                            Text(
                              'Welcome back! Please login to continue',
                              style: AppTheme.bodyMedium.copyWith(
                                color: theme.colorScheme.onSecondary
                                    .withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.space2XL),

                            // Login Form Card
                            CustomCard(
                              variant: CardVariant.elevated,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    // Email Field
                                    EmailTextField(
                                      controller: _emailController,
                                      label: l10n.email,
                                    ),
                                    const SizedBox(height: AppTheme.spaceLG),

                                    // Continue Button
                                    CustomButton(
                                      text: l10n.continueText,
                                      onPressed: _handleContinue,
                                      isLoading: state is AuthLoading,
                                    ),
                                    const SizedBox(height: AppTheme.spaceLG),

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
                                            style: AppTheme.bodySmall.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                        const Expanded(child: Divider()),
                                      ],
                                    ),
                                    const SizedBox(height: AppTheme.spaceLG),

                                    // Google Sign-In
                                    SocialLoginButton(
                                      text: l10n.continueWithGoogle,
                                      icon: Icons.g_mobiledata,
                                      color: AppColor.primaryColor,
                                      onPressed: _handleGoogleSignIn,
                                      isLoading: state is AuthLoading,
                                    ),
                                    const SizedBox(height: AppTheme.spaceLG),
                                    // Register Link
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          l10n.dontHaveAccount,
                                          style: AppTheme.bodyMedium,
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            context.go(
                                              '${AppRouter.login}/${AppRouter.register}',
                                            );
                                          },
                                          child: Text(
                                            l10n.register,
                                            style: AppTheme.labelLarge.copyWith(
                                              color: AppColor.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    } else if (state is AuthEmailExists) {
      context.go('${AppRouter.login}/enter-password/${state.email}');
    } else if (state is AuthGoogleRegistrationNeeded) {
      context.go('${AppRouter.login}/${AppRouter.register}');
    } else if (state is AuthGoogleVerificationNeeded) {
      context.go('${AppRouter.login}/verify-google-code/${state.email}');
    } else if (state is AuthAuthenticated) {
      context.go(AppRouter.home);
    }
  }
}