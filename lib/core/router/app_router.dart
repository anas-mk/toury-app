import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/helper/features/language_interview/presentation/cubit/exams_cubit.dart';
import '../../features/helper/features/language_interview/presentation/pages/interview_pending_screen.dart';
import '../../features/helper/features/language_interview/presentation/pages/interview_screen.dart';
import '../../features/helper/features/language_interview/presentation/pages/pre_interview_screen.dart';
import '../di/injection_container.dart';
import '../../features/helper/features/auth/data/datasources/helper_local_data_source.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/tourist/features/auth/presentation/pages/login_page.dart';
import '../../features/tourist/features/auth/presentation/pages/register_page.dart';
import '../../features/tourist/features/auth/presentation/pages/enter_password_page.dart';
import '../../features/splash/presentation/pages/role_selection_page.dart';
import '../../features/tourist/features/auth/presentation/pages/forgot_password_page.dart'; // ✅ Updated import
import '../../features/tourist/features/auth/presentation/pages/reset_password_page.dart'; // ✅ New import
import '../../features/tourist/features/auth/presentation/pages/verify_code_page.dart';
import '../../features/tourist/features/home/presentation/pages/home_layout.dart';
import '../../features/tourist/features/profile/presentation/page/accounts_settings_page.dart';
import '../../features/tourist/features/profile/presentation/page/profile_page.dart';

// Helper imports
import '../../features/helper/features/auth/presentation/pages/helper_login_page.dart';
import '../../features/helper/features/auth/presentation/pages/helper_enter_password_page.dart';
import '../../features/helper/features/auth/presentation/pages/verify_login_otp_page.dart';
import '../../features/helper/features/auth/presentation/pages/helper_register_page.dart';
import '../../features/helper/features/auth/presentation/pages/helper_verify_email_otp_page.dart';
import '../../features/helper/features/home/presentation/pages/home_page.dart';

import 'dart:async';
import '../../features/helper/features/helper_bookings/presentation/bloc/booking_cubit.dart';
import '../../features/helper/features/helper_bookings/presentation/bloc/booking_state.dart';

/// Helper class to make GoRouter react to Stream changes (Bloc/Cubit streams)
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Placeholder page for Google
// Placeholder pages for specialized authentication states
class GoogleVerifyCodePage extends StatelessWidget {
  final String email;
  const GoogleVerifyCodePage({super.key, required this.email});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Google Verify Code Page for $email (Placeholder)')));
}

class HelperOnboardingPage extends StatelessWidget {
  const HelperOnboardingPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Helper Onboarding')),
    body: const Center(child: Text('Onboarding Status: Incomplete\nComplete your profile settings.')),
  );
}

class WaitingApprovalPage extends StatelessWidget {
  const WaitingApprovalPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account Pending')),
    body: const Center(child: Text('Your account is waiting for admin approval.\nWe will notify you soon.')),
  );
}

class AccountInactivePage extends StatelessWidget {
  const AccountInactivePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account Inactive')),
    body: const Center(child: Text('Your account has been deactivated.\nPlease contact support.')),
  );
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

  // Trip Routes
  static const String helperIncoming = '/helper-incoming';
  static const String helperTrip = '/helper-trip';
  static const String helperRating = '/helper-rating';

  // Home Sub-Routes
  static const String helperRequests = '/helper-requests';
  static const String helperUpcoming = '/helper-upcoming';
  static const String helperHistory = '/helper-history';
  static const String helperActive = '/helper-active';
  static const String helperChat = '/helper-chat';
  static const String helperLocation = '/helper-location';

  // Helper Routes
  static const String helperLogin = '/helper-login';
  static const String helperHome = '/helper-home';
  static const String helperRegister = 'helper-register';
  static const String helperEnterPassword = 'enter-password/:email';
  static const String helperVerifyCode = 'helper-verify-code/:email';
  static const String helperRegisterVerifyOtp = 'helper-register-verify-otp';
  
  // Status Routes
  static const String helperOnboarding = '/helper-onboarding';
  static const String waitingApproval = '/waiting-approval';
  static const String accountInactive = '/account-inactive';
  static const String interviewScreen = '/interview-screen';
  static const String preInterview = '/pre-interview';
  static const String interviewPending = '/interview-pending';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,

    // ----------------------------------------
    // Redirection Logic - Auth Guard
    // ----------------------------------------
    redirect: (context, state) async {
      final matchedPath = state.matchedLocation;
      final isGoingToSplash = matchedPath == splash;
      if (isGoingToSplash) return null;

      final localDataSource = sl<HelperLocalDataSource>();
      final helper = await localDataSource.getCurrentHelper();
      final isAuthenticated = helper != null && helper.token != null && helper.token!.isNotEmpty;

      // Debug Logs as requested
      print('--- 🧭 ROUTER AUDIT ---');
      print('Current Route: $matchedPath');
      print('Token Status: ${isAuthenticated ? "AUTHENTICATED" : "NOT AUTHENTICATED"}');

      // Define public routes (accessible without login)
      final publicRoutes = [
        splash,
        roleSelection,
        login,
        helperLogin,
        register,
        '/helper-register',
        forgotPassword,
        resetPassword,
        verifyCode,
      ];

      // Routes that should NOT be accessible if already logged in
      final authRoutes = [
        roleSelection,
        login,
        helperLogin,
      ];

      final isPublic = publicRoutes.any((path) => matchedPath.startsWith(path));
      final isAuthRoute = authRoutes.contains(matchedPath);

      // 🚨 Case: Unauthenticated user
      if (!isAuthenticated) {
        // Block direct access to login/helper-login unless coming from role-selection
        final isLoginRoute = matchedPath == login || matchedPath == helperLogin;
        final hasRoleSelectionFlag = state.extra == 'from_role_selection';

        if (isLoginRoute && !hasRoleSelectionFlag) {
          print('Decision: Blocked direct access to login. Redirecting to Role Selection.');
          return roleSelection;
        }

        if (!isPublic) {
          print('Decision: Unauthorized access. Redirecting to Role Selection.');
          return roleSelection;
        }
      }

      // 🚨 Case: Authenticated user
      if (isAuthenticated && isAuthRoute) {
        print('Decision: user is authenticated. Redirecting away from Auth routes to Home.');
        return helperHome;
      }

      // 🚨 Trip / Booking Guard
      if (isAuthenticated && sl.isRegistered<BookingCubit>()) {
        final bookingState = sl<BookingCubit>().state;
        
        String? tripTarget;
        if (bookingState is BookingIncomingRequest) {
          tripTarget = helperIncoming;
        } else if (bookingState is BookingNavigatingToPickup ||
                 bookingState is BookingArrived ||
                 bookingState is BookingTripStarted ||
                 bookingState is BookingTripInProgress ||
                 bookingState is BookingTripEnding) {
          tripTarget = helperTrip;
        } else if (bookingState is BookingCompleted) {
          tripTarget = helperRating;
        } else if (matchedPath == helperIncoming || matchedPath == helperTrip || matchedPath == helperRating) {
           tripTarget = helperHome;
        }
        
        if (tripTarget != null && matchedPath != tripTarget) {
          print('Decision: Active Trip Guard. Redirecting to $tripTarget.');
          return tripTarget;
        }
      }

      print('Decision: Allowed (null)');
      print('-----------------------');
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

      // 4. Helper Authentication Logic
      GoRoute(
        path: helperLogin,
        name: 'helper-login',
        builder: (context, state) => const HelperLoginPage(),
        routes: [
          GoRoute(
            path: helperEnterPassword,
            name: 'helper-enter-password',
            builder: (context, state) {
              final email = state.pathParameters['email']!;
              return HelperEnterPasswordPage(email: email);
            },
          ),
          GoRoute(
            path: helperVerifyCode,
            name: 'helper-verify-code',
            builder: (context, state) {
              final email = state.pathParameters['email']!;
              return VerifyLoginOtpPage(email: email);
            },
          ),
          GoRoute(
            path: helperRegister,
            name: 'helper-register',
            builder: (context, state) => const HelperRegisterPage(),
          ),
          GoRoute(
            path: helperRegisterVerifyOtp,
            name: 'helper-register-verify-otp',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'] ?? 'mock@example.com';
              return HelperVerifyEmailOtpPage(email: email);
            },
          ),
        ],
      ),

      // 5. Helper Home
      GoRoute(
        path: helperHome,
        name: 'helper-home',
        builder: (context, state) => const HomePage(),
      ),

      // 5b. Helper Trip Flow
      GoRoute(
        path: helperIncoming,
        name: 'helper-incoming',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Incoming Booking Request'))),
      ),
      GoRoute(
        path: helperTrip,
        name: 'helper-trip',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Active Trip / Tracking'))),
      ),
      GoRoute(
        path: helperRating,
        name: 'helper-rating',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Rating Screen'))),
      ),

      // 5c. Home Sub-Routes
      GoRoute(
        path: helperRequests,
        name: 'helper-requests',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Helper Requests'))),
      ),
      GoRoute(
        path: helperUpcoming,
        name: 'helper-upcoming',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Helper Upcoming'))),
      ),
      GoRoute(
        path: helperHistory,
        name: 'helper-history',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Helper History'))),
      ),
      GoRoute(
        path: helperActive,
        name: 'helper-active',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Helper Active'))),
      ),
      GoRoute(
        path: helperChat,
        name: 'helper-chat',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Helper Chat'))),
      ),
      GoRoute(
        path: helperLocation,
        name: 'helper-location',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Helper Location'))),
      ),

      // 6. Helper Status Routes
      GoRoute(
        path: helperOnboarding,
        name: 'helper-onboarding',
        builder: (context, state) => const HelperOnboardingPage(),
      ),
      GoRoute(
        path: waitingApproval,
        name: 'waiting-approval',
        builder: (context, state) => const WaitingApprovalPage(),
      ),
      GoRoute(
        path: accountInactive,
        name: 'account-inactive',
        builder: (context, state) => const AccountInactivePage(),
      ),
      GoRoute(
        path: preInterview,
        name: 'pre-interview',
        builder: (context, state) {
          // Always resolve from singleton — never pass cubit via extra
          return BlocProvider.value(
            value: sl<ExamsCubit>(),
            child: const PreInterviewScreen(),
          );
        },
      ),
      GoRoute(
        path: interviewScreen,
        name: 'interview-screen',
        builder: (context, state) {
          // Always resolve from singleton — never pass cubit via extra
          final cubit = sl<ExamsCubit>();
          return BlocProvider.value(
            value: cubit,
            child: InterviewScreen(interviewId: cubit.state.interview?.id ?? ''),
          );
        },
      ),
      GoRoute(
        path: interviewPending,
        name: 'interview-pending',
        builder: (context, state) => const InterviewPendingScreen(),
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