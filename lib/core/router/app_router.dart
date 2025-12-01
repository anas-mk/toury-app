import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/tourist/features/auth/presentation/pages/login_page.dart';
import '../../features/tourist/features/auth/presentation/pages/register_page.dart';
import '../../features/tourist/features/auth/presentation/pages/enter_password_page.dart';
import '../../features/tourist/features/auth/presentation/pages/role_selection_page.dart';
import '../../features/tourist/features/auth/presentation/pages/forgot_password_page.dart'; // ✅ Updated import
import '../../features/tourist/features/auth/presentation/pages/reset_password_page.dart'; // ✅ New import
import '../../features/tourist/features/auth/presentation/pages/verify_code_page.dart';
import '../../features/tourist/features/home/presentation/pages/home_layout.dart';
import '../../features/tourist/features/profile/presentation/page/accounts_settings_page.dart';
import '../../features/tourist/features/profile/presentation/page/profile_page.dart';

// Placeholder page for Google
class GoogleVerifyCodePage extends StatelessWidget {
  final String email;
  const GoogleVerifyCodePage({super.key, required this.email});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Google Verify Code Page for $email (Placeholder)')));
}



class AppRouter {
  // ----------------------------------------
  // Routes
  // ----------------------------------------
  static const String splash = '/';
  static const String roleSelection = '/role-selection';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = 'register';
  static const String verifyCode = '/verify-code'; // ✨ Added this route constant
  static const String enterPassword = 'enter-password/:email';
  static const String forgotPassword = 'forgot-password';
  static const String resetPassword = 'reset-password';
  static const String googleVerifyCode = 'verify-google-code/:email';
  static const String accountSettings = 'account-settings';
  static const String profile = 'profile';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,

    // ----------------------------------------
    // Redirection Logic - Simple Version
    // ----------------------------------------
    redirect: (context, state) {
      final isGoingToSplash = state.uri.toString() == splash;

      if (isGoingToSplash) return null;

      return null;
    },

    routes: [
      // 1. Splash & Role Selection
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      GoRoute(
        path: roleSelection,
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionPage(),
      ),

      // 1b. Verify Code - New Top Level Route
      GoRoute(
        path: verifyCode,
        name: 'verify-code', // Added name
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyCodePage(email: email);
        },
      ),

      // 2. Login Flow Group
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
        routes: [
          GoRoute(
            path: register,
            name: 'register',
            builder: (context, state) => const RegisterPage(),
          ),
          GoRoute(
            path: enterPassword,
            name: 'enter-password',
            builder: (context, state) {
              final email = state.pathParameters['email']!;
              return EnterPasswordPage(email: email);
            },
          ),
          GoRoute(
            path: forgotPassword,
            name: 'forgot-password',
            builder: (context, state) => const ForgotPasswordPage(),
            routes: [
              GoRoute(
                path: resetPassword,
                name: 'reset-password',
                builder: (context, state) {
                  // Get email from extra parameter
                  final email = state.extra as String? ?? '';
                  return ResetPasswordPage(email: email);
                },
              ),
            ],
          ),
          GoRoute(
            path: googleVerifyCode,
            name: 'google-verify-code',
            builder: (context, state) {
              final email = state.pathParameters['email']!;
              return GoogleVerifyCodePage(email: email);
            },
          ),
        ],
      ),

      // 3. Home Layout Group
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeLayout(),
        routes: [
          GoRoute(
            path: accountSettings,
            name: 'account-settings',
            builder: (context, state) => const AccountSettingsPage(),
            routes: [
              GoRoute(
                path: profile,
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],

    // 4. Custom 404 Error Page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('GO TO START PAGE${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(splash),
              child: const Text('GO TO START'),
            ),
          ],
        ),
      ),
    ),
  );
}