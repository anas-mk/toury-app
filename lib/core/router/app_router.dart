import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/tourist/features/auth/presentation/pages/login_page.dart';
import '../../features/tourist/features/auth/presentation/pages/register_page.dart';
import '../../features/tourist/features/auth/presentation/pages/enter_password_page.dart';
import '../../features/tourist/features/auth/presentation/pages/role_selection_page.dart';
import '../../features/tourist/features/home/presentation/pages/home_layout.dart';
import '../../features/tourist/features/home/presentation/pages/accounts_settings_page.dart';
import '../../features/tourist/features/profile/presentation/profile_page.dart';

// Placeholder pages
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Forgot Password Page (Placeholder)')));
}

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
  static const String enterPassword = 'enter-password/:email';
  static const String forgotPassword = 'forgot-password';
  static const String googleVerifyCode = 'verify-google-code/:email';
  static const String accountSettings = 'account-settings';
  static const String profile = 'profile';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true, // ✅ للمساعدة في debugging

    // ----------------------------------------
    // Redirection Logic - Simple Version
    // ----------------------------------------
    redirect: (context, state) {
      final isGoingToSplash = state.uri.toString() == splash;

      // ✅ Let splash page handle the navigation logic
      // This prevents redirect loops
      if (isGoingToSplash) return null;

      // Allow all other routes
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
            Text('خطأ: الصفحة غير موجودة: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(splash),
              child: const Text('الذهاب إلى البداية'),
            ),
          ],
        ),
      ),
    ),
  );
}