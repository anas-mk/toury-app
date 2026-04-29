import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:toury/features/tourist/features/profile/presentation/page/accounts_settings_page.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/booking_status_cubit.dart';
import 'package:toury/features/tourist/features/user_booking/presentation/cubits/my_bookings_cubit.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/earnings_page.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/helper_history_page.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/incoming_requests_page.dart';
import '../../features/helper/features/helper_location/presentation/pages/helper_location_page.dart';
import '../../features/helper/features/helper_location/presentation/pages/eligibility_debug_page.dart';
import '../../features/helper/features/helper_service_areas/presentation/pages/service_areas_page.dart';
import '../../features/helper/features/helper_service_areas/presentation/pages/add_edit_service_area_page.dart';
import '../../features/helper/features/helper_service_areas/domain/entities/service_area_entities.dart'
    as helper_sa;
import '../../features/helper/features/helper_invoices/presentation/pages/invoices_page.dart';
import '../../features/helper/features/helper_invoices/presentation/pages/invoice_detail_page.dart';
import '../../features/helper/features/helper_invoices/presentation/pages/invoice_view_page.dart';
import '../../features/helper/features/home/presentation/pages/helper_home_layout.dart';
import '../../features/helper/features/language_interview/presentation/cubit/exams_cubit.dart';
import '../../features/helper/features/language_interview/presentation/pages/interview_pending_screen.dart';
import '../../features/helper/features/language_interview/presentation/pages/interview_screen.dart';
import '../../features/helper/features/language_interview/presentation/pages/pre_interview_screen.dart';
import '../../features/helper/features/language_interview/presentation/pages/exams_page.dart';
import '../../features/helper/features/profile/presentation/pages/profile_page.dart';
import '../../features/tourist/features/home/presentation/pages/tourist_home_page.dart';
import '../../features/tourist/features/payments/presentation/cubit/payment_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubits/search_helpers_cubit.dart';
import '../../features/helper/features/helper_ratings/presentation/pages/helper_ratings_page.dart';
import '../../features/helper/features/helper_ratings/presentation/pages/rate_user_page.dart';
import '../di/injection_container.dart';
import '../services/notifications/notification_router.dart';
import '../../features/helper/features/auth/data/datasources/helper_local_data_source.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../diagnostics/realtime_diagnostics_page.dart';
import '../../features/tourist/features/auth/presentation/pages/login_page.dart';
import '../../features/tourist/features/auth/presentation/pages/register_page.dart';
import '../../features/tourist/features/auth/presentation/pages/enter_password_page.dart';
import '../../features/splash/presentation/pages/role_selection_page.dart';
import '../../features/tourist/features/auth/presentation/pages/forgot_password_page.dart'; // ✅ Updated import
import '../../features/tourist/features/auth/presentation/pages/reset_password_page.dart'; // ✅ New import
import '../../features/tourist/features/auth/presentation/pages/verify_code_page.dart';
import '../../features/tourist/features/home/presentation/pages/home_layout.dart';
import '../../features/helper/features/profile/presentation/pages/account_control_center_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/booking_home_page.dart';
import '../../features/tourist/features/user_booking/domain/entities/search_params.dart';
import '../../features/tourist/features/user_booking/presentation/pages/scheduled/scheduled_search_form_screen.dart';
import '../../features/tourist/features/user_booking/presentation/pages/scheduled/scheduled_search_results_screen.dart';
import '../../features/tourist/features/user_booking/presentation/pages/scheduled/scheduled_helper_profile_screen.dart';
import '../../features/tourist/features/user_booking/presentation/pages/scheduled/scheduled_review_screen.dart';
import '../../features/tourist/features/user_booking/presentation/pages/scheduled/scheduled_alternatives_screen.dart';
import '../../features/tourist/features/user_booking/presentation/pages/scheduled/scheduled_booking_detail_screen.dart';
import '../../features/tourist/features/user_booking/presentation/widgets/scheduled/scheduled_trip_config.dart';
import '../../features/tourist/features/user_booking/presentation/pages/helper_profile_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/booking_confirm_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/my_bookings_page.dart';
// New instant-flow pages (Step 2 → 10).
import '../../features/tourist/features/user_booking/presentation/pages/instant/instant_trip_details_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant/instant_helpers_list_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant/helper_booking_profile_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant/booking_review_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant/waiting_for_helper_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant/booking_alternatives_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant/booking_confirmed_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant/trip_tracking_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant/trip_tracking_entry_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant/pay_now_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant/location_pick_result.dart';
import '../../features/tourist/features/user_booking/domain/entities/alternatives_response.dart'
    as instant_alt;
import '../../features/tourist/features/user_booking/domain/entities/booking_detail.dart'
    as instant_booking;
import '../../features/tourist/features/user_booking/domain/entities/helper_search_result.dart'
    as instant_helper;
import '../../features/tourist/features/user_booking/domain/entities/instant_search_request.dart'
    as instant_req;
import '../../features/tourist/features/user_booking/presentation/cubits/instant_booking_cubit.dart';
import '../../features/tourist/features/user_booking/domain/entities/helper_booking_entity.dart';
import '../../features/tourist/features/payments/presentation/pages/payment_method_page.dart';
import '../../features/tourist/features/payments/presentation/pages/payment_processing_page.dart';
import '../../features/tourist/features/payments/presentation/pages/payment_webview_page.dart';
import '../../features/tourist/features/payments/presentation/pages/payment_success_page.dart';
import '../../features/tourist/features/payments/presentation/pages/payment_failed_page.dart';
import '../../features/tourist/features/payments/domain/entities/payment_entity.dart';
import '../../features/tourist/features/user_invoices/presentation/pages/user_invoices_page.dart';
import '../../features/tourist/features/user_invoices/domain/entities/invoice_entity.dart';
import '../../features/tourist/features/user_invoices/presentation/pages/user_invoice_detail_page.dart';
import '../../features/tourist/features/user_ratings/presentation/pages/helper_reviews_page.dart';
import '../../features/tourist/features/user_ratings/presentation/pages/rate_booking_page.dart';
import '../../features/tourist/features/user_chat/presentation/pages/user_chat_page.dart';
import '../../features/tourist/features/user_booking_tracking/presentation/pages/user_booking_tracking_page.dart';
import '../../features/helper/features/helper_booking_tracking/presentation/pages/helper_booking_tracking_page.dart';
import '../../features/helper/features/helper_booking_tracking/presentation/cubit/helper_tracking_cubit.dart';

// Helper imports
import '../../features/helper/features/auth/presentation/pages/helper_login_page.dart';
import '../../features/helper/features/auth/presentation/pages/helper_enter_password_page.dart';
import '../../features/helper/features/auth/presentation/pages/verify_login_otp_page.dart';
import '../../features/helper/features/auth/presentation/pages/helper_register_page.dart';
import '../../features/helper/features/auth/presentation/pages/helper_verify_email_otp_page.dart';

import '../../features/helper/features/auth/presentation/pages/helper_forgot_password_page.dart';
import '../../features/helper/features/auth/presentation/pages/helper_reset_password_page.dart';
// Helper Bookings imports
import '../../features/helper/features/helper_bookings/presentation/pages/helper_dashboard_page.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/bookings_center_page.dart';
import '../../features/helper/features/helper_chat/presentation/pages/conversations_list_page.dart';
import '../../features/helper/features/helper_invoices/presentation/pages/wallet_hub_page.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/request_details_page.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/active_booking_page.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/helper_booking_details_page.dart';

import 'dart:async';

import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

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
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Text('Google Verify Code Page for $email (Placeholder)'),
    ),
  );
}

class HelperOnboardingPage extends StatelessWidget {
  const HelperOnboardingPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Helper Onboarding')),
    body: const Center(
      child: Text(
        'Onboarding Status: Incomplete\nComplete your profile settings.',
      ),
    ),
  );
}

class WaitingApprovalPage extends StatelessWidget {
  const WaitingApprovalPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account Pending')),
    body: const Center(
      child: Text(
        'Your account is waiting for admin approval.\nWe will notify you soon.',
      ),
    ),
  );
}

/// Minimal target for report-related push / SignalR routes.
class UserReportsPlaceholderPage extends StatelessWidget {
  const UserReportsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Report updates open here. Pull down on My Bookings to refresh statuses.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class AccountInactivePage extends StatelessWidget {
  const AccountInactivePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Account Inactive')),
    body: const Center(
      child: Text(
        'Your account has been deactivated.\nPlease contact support.',
      ),
    ),
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
  static const String verifyCode =
      '/verify-code'; // ✨ Added this route constant
  static const String enterPassword = 'enter-password/:email';
  static const String forgotPassword = 'forgot-password';
  static const String resetPassword = 'reset-password';
  static const String googleVerifyCode = 'verify-google-code/:email';
  static const String accountSettings = 'account-settings';
  static const String profile = 'profile';
  static const String bookingHome = '/booking-home';
  static const String scheduledSearch = '/scheduled/search';
  static const String scheduledResults = '/scheduled/results';
  static const String scheduledHelperProfile = '/scheduled/helpers/:id';
  static const String scheduledReview = '/scheduled/review';
  static const String scheduledAlternatives = '/bookings/:id/alternatives';
  static const String helperProfile = '/helper-profile/:id';
  static const String bookingConfirm = '/booking-confirm';
  static const String bookingDetails = '/booking-details/:id';
  // Removed: scheduledTripDetails (use bookingDetails instead).
  static const String myBookings = '/my-bookings';

  // ── Instant Booking (rebuilt) ──────────────────────────────────────
  static const String instantTripDetails = '/instant/details';
  static const String instantHelpersList = '/instant/helpers';
  static const String instantHelperProfile = '/instant/helpers/:id';
  static const String instantBookingReview = '/instant/review';
  static const String instantWaiting = '/instant/waiting/:id';
  static const String instantAlternatives = '/instant/alternatives/:id';
  static const String instantConfirmed = '/instant/confirmed/:id';
  static const String instantTripTracking = '/instant/tracking/:id';

  /// Push contract alias — same live map as [instantTripTracking].
  static const String tripLive = '/trip/:id';
  static const String instantPayNow = '/instant/pay-now/:id';

  /// Push contract — `id` is booking / conversation id on the wire.
  static const String chatByConversation = '/chat/:id';
  static const String reports = '/reports';

  // Payment Routes
  static const String paymentMethod = '/payment-method/:bookingId';
  static const String paymentProcessing = '/payment-processing';
  static const String paymentWebview = '/payment-webview';
  static const String paymentSuccess = '/payment-success';
  static const String paymentFailed = '/payment-failed';

  // User Invoice Routes
  static const String userInvoices = '/user-invoices';
  static const String userInvoiceDetail = '/invoice-detail/:id';
  static const String userInvoiceView = '/invoice-view/:id';

  // User Chat Routes
  static const String userChat = '/user-chat/:id';

  // User Tracking Routes
  static const String userTracking = '/user-tracking/:id';
  static const String helperTracking = '/helper-tracking/:id';

  // User Rating Routes
  static const String helperReviews = '/helper-reviews/:id';
  static const String rateBooking = '/rate-booking/:bookingId';

  // Hidden diagnostics
  static const String devRealtime = '/dev/realtime';

  // Helper Constants
  static const String helperLogin = '/helper-login';
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

  // Helper Shell Routes
  static const String helperHome = '/helper/home';
  static const String helperBookings = '/helper/bookings';
  static const String helperMessages = '/helper/messages';
  static const String helperWallet = '/helper/wallet';
  static const String helperAccount = '/helper/account';

  // Helper Sub-Routes
  static const String helperDashboard =
      helperHome; // For backward compatibility if needed
  static const String helperRequests = '/helper/requests';
  static const String helperRequestDetails = '/helper/request-details/:id';
  static const String helperUpcoming = '/helper/upcoming';
  static const String helperActiveBooking = '/helper/active-booking';
  static const String helperBookingDetails = '/helper/booking-details/:id';
  static const String helperHistory = '/helper/history';
  static const String helperEarnings = '/helper/earnings';
  static const String helperLocation = '/helper/location';
  static const String helperEligibilityDebug = '/helper/eligibility-debug';
  static const String helperServiceAreas = '/helper/service-areas';
  static const String helperAddServiceArea = '/helper/add-service-area';
  static const String helperEditServiceArea = '/helper/edit-service-area';
  static const String helperInvoices = '/helper/invoices';
  static const String helperInvoiceDetail = '/helper/invoice-detail/:id';
  static const String helperInvoiceView = '/helper/invoice-view/:id';
  static const String helperRatings = '/helper/ratings';
  static const String rateUser = '/helper/rate-user/:id';
  static const String helperReports = '/helper/reports';
  static const String helperSos = '/helper/sos';

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: splash,
    debugLogDiagnostics: true,

    redirect: (context, state) async {
      final matchedPath = state.matchedLocation;
      final isGoingToSplash = matchedPath == splash;
      if (isGoingToSplash) return null;

      final localDataSource = sl<HelperLocalDataSource>();
      final helper = await localDataSource.getCurrentHelper();
      final isAuthenticated =
          helper != null && helper.token != null && helper.token!.isNotEmpty;

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
        devRealtime,
      ];

      final authRoutes = [roleSelection, login, helperLogin];

      final isPublic = publicRoutes.any((path) => matchedPath.startsWith(path));
      final isAuthRoute = authRoutes.contains(matchedPath);

      if (!isAuthenticated) {
        final isLoginRoute = matchedPath == login || matchedPath == helperLogin;
        final hasRoleSelectionFlag = state.extra == 'from_role_selection';

        if (isLoginRoute && !hasRoleSelectionFlag) {
          return roleSelection;
        }

        if (!isPublic) {
          return roleSelection;
        }
      }

      if (isAuthenticated && isAuthRoute) {
        return helperHome;
      }

      // Cold-start FCM deep-link consumption.
      //
      // If main() captured an initialMessage from getInitialMessage() and
      // the user is authenticated AND we're being routed to a non-public
      // screen, that's our cue: the splash → auth dance is done and the
      // navigator is ready to land somewhere real. Consume the pending
      // link and redirect there instead of the original target.
      //
      // Done LAST so we don't race the role-based redirects above.
      if (isAuthenticated && !isPublic) {
        final pendingRoute =
            NotificationRouter.instance.consumePendingDeepLink();
        if (pendingRoute != null && pendingRoute != matchedPath) {
          return pendingRoute;
        }
      }

      return null;
    },

    routes: [
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

      GoRoute(
        path: verifyCode,
        name: 'verify-code',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyCodePage(email: email);
        },
      ),

      // 1. Tourist Login Flow
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
                  final email = state.extra as String? ?? '';
                  return ResetPasswordPage(email: email);
                },
              ),
            ],
          ),
        ],
      ),

      // 2. Helper Authentication
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
              final email =
                  state.uri.queryParameters['email'] ?? 'mock@example.com';
              return HelperVerifyEmailOtpPage(email: email);
            },
          ),
          GoRoute(
            path: forgotPassword,
            name: 'helper-forgot-password',
            builder: (context, state) => const HelperForgotPasswordPage(),
            routes: [
              GoRoute(
                path: resetPassword,
                name: 'helper-reset-password',
                builder: (context, state) {
                  final email = state.extra as String? ?? '';
                  return HelperResetPasswordPage(email: email);
                },
              ),
            ],
          ),
        ],
      ),

      // 3. Helper Main Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HelperHomeLayout(navigationShell: navigationShell);
        },
        branches: [
          // Branch: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: helperHome,
                name: 'helper-home',
                builder: (context, state) => const HelperDashboardPage(),
              ),
            ],
          ),
          // Branch: Bookings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: helperBookings,
                name: 'helper-bookings',
                builder: (context, state) => const BookingsCenterPage(),
              ),
            ],
          ),
          // Branch: Messages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: helperMessages,
                name: 'helper-messages',
                builder: (context, state) => const ConversationsListPage(),
              ),
            ],
          ),
          // Branch: Wallet
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: helperWallet,
                name: 'helper-wallet',
                builder: (context, state) => const WalletHubPage(),
              ),
            ],
          ),
          // Branch: Language
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/helper/language-interview',
                name: 'language-interview-tab',
                builder: (context, state) => const ExamsPage(),
              ),
            ],
          ),
          // Branch: Account
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: helperAccount,
                name: 'helper-account',
                builder: (context, state) => const AccountControlCenterPage(),
              ),
            ],
          ),
        ],
      ),

      // 4. Helper Sub-Pages (Pushed on top of Shell)
      GoRoute(
        path: helperRequests,
        name: 'helper-requests',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const IncomingRequestsPage(),
      ),
      GoRoute(
        path: helperRequestDetails,
        name: 'helper-request-details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RequestDetailsPage(bookingId: id);
        },
      ),
      GoRoute(
        path: helperActiveBooking,
        name: 'helper-active-booking',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id =
              state.pathParameters['id'] ?? (state.extra as String? ?? '');
          return ActiveBookingPage(bookingId: id);
        },
      ),
      GoRoute(
        path: helperBookingDetails,
        name: 'helper-booking-details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return HelperBookingDetailsPage(bookingId: id);
        },
      ),
      GoRoute(
        path: helperHistory,
        name: 'helper-history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HelperHistoryPage(),
      ),
      GoRoute(
        path: helperEarnings,
        name: 'helper-earnings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EarningsPage(),
      ),

      // 5. Tourist Home & Flow (Shell Route)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeLayout(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: home,
                name: 'home',
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    // Cubits are created here, but the initial fetch is
                    // owned by TouristHomePage.initState. Calling
                    // ..getBookings(...) here causes the same endpoint to
                    // fire twice on every home mount (once from the
                    // cascade, once from initState's post-frame callback).
                    BlocProvider(create: (context) => sl<MyBookingsCubit>()),
                    BlocProvider(create: (context) => sl<BookingStatusCubit>()),
                    BlocProvider(create: (context) => sl<SearchHelpersCubit>()),
                  ],
                  child: const TouristHomePage(),
                ),
              ),
            ],
          ),
          // Tab 2: Activity
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: myBookings,
                name: 'my-bookings',
                builder: (context, state) => const MyBookingsPage(),
              ),
            ],
          ),
          // Tab 3: Wallet
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: userInvoices,
                name: 'user-invoices',
                builder: (context, state) => const UserInvoicesPage(),
              ),
            ],
          ),
          // Tab 4: Account
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/$accountSettings',
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
      ),

      // 6. Helper Status & Interview
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
        builder: (context, state) => BlocProvider.value(
          value: sl<ExamsCubit>(),
          child: const PreInterviewScreen(),
        ),
      ),
      GoRoute(
        path: interviewScreen,
        name: 'interview-screen',
        builder: (context, state) {
          final cubit = sl<ExamsCubit>();
          return BlocProvider.value(
            value: cubit,
            child: InterviewScreen(
              interviewId: cubit.state.interview?.id ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: interviewPending,
        name: 'interview-pending',
        builder: (context, state) => const InterviewPendingScreen(),
      ),

      // 7. User Booking Routes
      GoRoute(
        path: bookingHome,
        name: 'booking-home',
        builder: (context, state) => const BookingHomePage(),
      ),
      GoRoute(
        path: scheduledSearch,
        name: 'scheduled-search',
        builder: (context, state) {
          final initialDestination = state.extra is String
              ? state.extra as String
              : null;
          return ScheduledSearchFormScreen(
            initialDestination: initialDestination,
          );
        },
      ),
      GoRoute(
        path: scheduledResults,
        name: 'scheduled-results',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final params = extra?['params'] as ScheduledSearchParams?;
          if (params == null) {
            return const Scaffold(
              body: Center(child: Text('Missing search parameters.')),
            );
          }
          return ScheduledSearchResultsScreen(params: params);
        },
      ),
      GoRoute(
        path: scheduledHelperProfile,
        name: 'scheduled-helper-profile',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ScheduledHelperProfileScreen(
            helperId: id,
            initialHelper: extra?['helper'] as HelperBookingEntity?,
            searchParams: extra?['params'] as ScheduledSearchParams?,
          );
        },
      ),
      GoRoute(
        path: scheduledReview,
        name: 'scheduled-review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const Scaffold(
              body: Center(child: Text('Missing review payload.')),
            );
          }
          return ScheduledReviewScreen(
            helper: extra['helper'] as HelperBookingEntity,
            params: extra['params'] as ScheduledSearchParams,
            config: extra['config'] as ScheduledTripConfig,
          );
        },
      ),
      GoRoute(
        path: scheduledAlternatives,
        name: 'scheduled-alternatives',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ScheduledAlternativesScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: helperProfile,
        name: 'helper-profile',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return HelperProfilePage(
            helperId: id,
            initialHelper: extra?['helper'] as HelperBookingEntity?,
            searchParams: extra?['searchParams'],
            isInstant: extra?['isInstant'] ?? false,
          );
        },
      ),
      GoRoute(
        path: bookingConfirm,
        name: 'booking-confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingConfirmPage(
            helper: extra['helper'] as HelperBookingEntity,
            searchParams: extra['searchParams'],
            isInstant: extra['isInstant'] ?? false,
          );
        },
      ),
      // /scheduled-trip-details was removed. Both Instant and Scheduled
      // bookings now use the unified /booking-details/:id route.
      //
      // The ScheduledBookingDetailScreen (Phase 5) handles every booking
      // status branch (waiting / accepted / paid / upcoming / in-progress
      // / completed / cancelled / declined-needs-alternatives) and reuses
      // GetBookingDetailUC under the hood, so it works for both Scheduled
      // *and* Instant bookings opened from the bookings history.
      GoRoute(
        path: bookingDetails,
        name: 'booking-details',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ScheduledBookingDetailScreen(bookingId: id);
        },
      ),

      // ── Instant Booking flow (rebuilt) ──────────────────────────────────
      GoRoute(
        path: instantTripDetails,
        name: 'instant-trip-details',
        builder: (context, state) => const InstantTripDetailsPage(),
      ),
      GoRoute(
        path: instantHelpersList,
        name: 'instant-helpers-list',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return InstantHelpersListPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            searchRequest:
                extra['searchRequest'] as instant_req.InstantSearchRequest,
            pickup: extra['pickup'] as LocationPickResult,
            destination: extra['destination'] as LocationPickResult,
            travelers: extra['travelers'] as int,
            durationInMinutes: extra['durationInMinutes'] as int,
            languageCode: extra['languageCode'] as String?,
            requiresCar: extra['requiresCar'] as bool,
            notes: extra['notes'] as String?,
          );
        },
      ),
      GoRoute(
        path: instantHelperProfile,
        name: 'instant-helper-profile',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return HelperBookingProfilePage(
            cubit: extra['cubit'] as InstantBookingCubit,
            helper: extra['helper'] as instant_helper.HelperSearchResult,
            pickup: extra['pickup'] as LocationPickResult,
            destination: extra['destination'] as LocationPickResult,
            travelers: extra['travelers'] as int,
            durationInMinutes: extra['durationInMinutes'] as int,
            languageCode: extra['languageCode'] as String?,
            requiresCar: extra['requiresCar'] as bool,
            notes: extra['notes'] as String?,
          );
        },
      ),
      GoRoute(
        path: instantBookingReview,
        name: 'instant-booking-review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingReviewPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            helper: extra['helper'] as instant_helper.HelperSearchResult,
            pickup: extra['pickup'] as LocationPickResult,
            destination: extra['destination'] as LocationPickResult,
            travelers: extra['travelers'] as int,
            durationInMinutes: extra['durationInMinutes'] as int,
            languageCode: extra['languageCode'] as String?,
            requiresCar: extra['requiresCar'] as bool,
            notes: extra['notes'] as String?,
          );
        },
      ),
      GoRoute(
        path: instantWaiting,
        name: 'instant-waiting',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>;
          return WaitingForHelperPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            bookingId: id,
            helper: extra['helper'] as instant_helper.HelperSearchResult?,
          );
        },
      ),
      GoRoute(
        path: instantAlternatives,
        name: 'instant-alternatives',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingAlternativesPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            booking: extra['booking'] as instant_booking.BookingDetail,
            alternatives:
                extra['alternatives'] as instant_alt.AlternativesResponse,
          );
        },
      ),
      GoRoute(
        path: instantConfirmed,
        name: 'instant-confirmed',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>;
          return BookingConfirmedPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            bookingId: id,
            helper: extra['helper'] as instant_helper.HelperSearchResult?,
          );
        },
      ),
      GoRoute(
        path: instantTripTracking,
        name: 'instant-trip-tracking',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>;
          return TripTrackingPage(
            cubit: extra['cubit'] as InstantBookingCubit,
            bookingId: id,
            helper: extra['helper'] as instant_helper.HelperSearchResult?,
          );
        },
      ),
      GoRoute(
        path: tripLive,
        name: 'trip-live',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TripTrackingEntryPage(bookingId: id);
        },
      ),
      GoRoute(
        path: instantPayNow,
        name: 'instant-pay-now',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra;
          InstantBookingCubit? cubit;
          var requireRating = false;
          if (extra is Map<String, dynamic>) {
            cubit = extra['cubit'] as InstantBookingCubit?;
            requireRating = extra['requireRating'] == true;
          }
          return PayNowPage(
            bookingId: id,
            instantCubit: cubit,
            requireRating: requireRating,
          );
        },
      ),

      // ── Payments ────────────────────────────────────────────────────────
      GoRoute(
        path: paymentMethod,
        name: 'payment-method',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return BlocProvider(
            create: (_) => sl<PaymentCubit>(),
            child: PaymentMethodPage(bookingId: bookingId),
          );
        },
      ),
      GoRoute(
        path: paymentProcessing,
        name: 'payment-processing',
        builder: (context, state) {
          final payment = state.extra as PaymentEntity;
          return BlocProvider(
            create: (_) => sl<PaymentCubit>(),
            child: PaymentProcessingPage(payment: payment),
          );
        },
      ),
      GoRoute(
        path: paymentWebview,
        name: 'payment-webview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BlocProvider(
            create: (_) => sl<PaymentCubit>(),
            child: PaymentWebviewPage(
              paymentUrl: extra['paymentUrl'],
              paymentId: extra['paymentId'],
              bookingId: extra['bookingId'],
            ),
          );
        },
      ),
      GoRoute(
        path: paymentSuccess,
        name: 'payment-success',
        builder: (context, state) {
          final bookingId = state.extra as String;
          return PaymentSuccessPage(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: paymentFailed,
        name: 'payment-failed',
        builder: (context, state) {
          final bookingId = state.extra as String;
          return PaymentFailedPage(bookingId: bookingId);
        },
      ),

      // ── User Invoices ──────────────────────────────────────────────────
      GoRoute(
        path: userInvoiceDetail,
        name: 'user-invoice-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final invoice = state.extra as InvoiceEntity?;
          return UserInvoiceDetailPage(invoiceId: id, initialInvoice: invoice);
        },
      ),
      GoRoute(
        path: userInvoiceView,
        name: 'user-invoice-view',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return UserInvoiceDetailPage(invoiceId: id);
        },
      ),

      // ── User Ratings ──────────────────────────────────────────────────
      GoRoute(
        path: helperReviews,
        name: 'helper-reviews',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.uri.queryParameters['name'] ?? 'Helper';
          return HelperReviewsPage(helperId: id, helperName: name);
        },
      ),

      GoRoute(
        path: rateBooking,
        name: 'rate-booking',
        builder: (context, state) {
          final id = state.pathParameters['bookingId']!;
          return RateBookingPage(bookingId: id);
        },
      ),

      // ── Diagnostics (hidden — enter the URL manually) ────────────────────
      GoRoute(
        path: devRealtime,
        name: 'dev-realtime',
        builder: (context, state) => const RealtimeDiagnosticsPage(),
      ),

      // ── User Chat ──────────────────────────────────────────────────
      GoRoute(
        path: userChat,
        name: 'user-chat',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.uri.queryParameters['name'];
          final image = state.uri.queryParameters['image'];
          return UserChatPage(
            bookingId: id,
            helperName: name,
            helperImage: image,
          );
        },
      ),
      GoRoute(
        path: chatByConversation,
        name: 'user-chat-conversation',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.uri.queryParameters['name'];
          final image = state.uri.queryParameters['image'];
          return UserChatPage(
            bookingId: id,
            helperName: name,
            helperImage: image,
          );
        },
      ),
      GoRoute(
        path: reports,
        name: 'user-reports',
        builder: (context, state) => const UserReportsPlaceholderPage(),
      ),

      // ── User Booking Tracking ─────────────────────────────────────────
      GoRoute(
        path: userTracking,
        name: 'user-tracking',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final pickupLat = double.parse(
            state.uri.queryParameters['pickupLat'] ?? '0',
          );
          final pickupLng = double.parse(
            state.uri.queryParameters['pickupLng'] ?? '0',
          );
          final destLat = double.parse(
            state.uri.queryParameters['destLat'] ?? '0',
          );
          final destLng = double.parse(
            state.uri.queryParameters['destLng'] ?? '0',
          );

          return UserBookingTrackingPage(
            bookingId: id,
            pickupLocation: LatLng(pickupLat, pickupLng),
            destinationLocation: LatLng(destLat, destLng),
          );
        },
      ),

      // ── Helper Booking Tracking ─────────────────────────────────────────
      GoRoute(
        path: helperTracking,
        name: 'helper-tracking',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final pickupLat = double.parse(
            state.uri.queryParameters['pickupLat'] ?? '0',
          );
          final pickupLng = double.parse(
            state.uri.queryParameters['pickupLng'] ?? '0',
          );
          final destLat = double.parse(
            state.uri.queryParameters['destLat'] ?? '0',
          );
          final destLng = double.parse(
            state.uri.queryParameters['destLng'] ?? '0',
          );

          return BlocProvider(
            create: (context) => sl<HelperTrackingCubit>()..startTracking(id),
            child: HelperBookingTrackingPage(
              bookingId: id,
              pickupLat: pickupLat,
              pickupLng: pickupLng,
              destLat: destLat,
              destLng: destLng,
            ),
          );
        },
      ),

      // ── Helper Location ──────────────────────────────────────────────────
      GoRoute(
        path: helperLocation,
        name: 'helper-location',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HelperLocationPage(),
          transitionsBuilder: _slideUp,
        ),
      ),
      GoRoute(
        path: helperEligibilityDebug,
        name: 'helper-eligibility-debug',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EligibilityDebugPage(),
          transitionsBuilder: _fadeSlide,
        ),
      ),

      // ── Helper Service Areas ─────────────────────────────────────────────
      GoRoute(
        path: helperServiceAreas,
        name: 'helper-service-areas',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ServiceAreasPage(),
          transitionsBuilder: _fadeSlide,
        ),
      ),
      GoRoute(
        path: helperAddServiceArea,
        name: 'helper-add-service-area',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AddEditServiceAreaPage(),
          transitionsBuilder: _slideUp,
        ),
      ),
      GoRoute(
        path: helperEditServiceArea,
        name: 'helper-edit-service-area',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final area = state.extra as helper_sa.ServiceAreaEntity;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AddEditServiceAreaPage(existing: area),
            transitionsBuilder: _slideUp,
          );
        },
      ),
      // ── Helper Invoices ─────────────────────────────────────────────
      GoRoute(
        path: helperInvoices,
        name: 'helper-invoices',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const InvoicesPage(),
          transitionsBuilder: _fadeSlide,
        ),
      ),
      GoRoute(
        path: helperInvoiceDetail,
        name: 'helper-invoice-detail',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: InvoiceDetailPage(invoiceId: state.pathParameters['id']!),
          transitionsBuilder: _fadeSlide,
        ),
      ),
      GoRoute(
        path: helperInvoiceView,
        name: 'helper-invoice-view',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: InvoiceViewPage(invoiceId: state.pathParameters['id']!),
          transitionsBuilder: _slideUp,
        ),
      ),
      // ── Helper Ratings ─────────────────────────────────────────────
      GoRoute(
        path: helperRatings,
        name: 'helper-ratings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HelperRatingsPage(),
          transitionsBuilder: _fadeSlide,
        ),
      ),
      GoRoute(
        path: rateUser,
        name: 'rate-user',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>;
          return CustomTransitionPage(
            key: state.pageKey,
            child: RateUserPage(
              bookingId: id,
              travelerName: extra['name'] ?? 'Traveler',
              travelerAvatar: extra['avatar'] ?? '',
            ),
            transitionsBuilder: _slideUp,
          );
        },
      ),
    ],

    // 4. Custom 404 Error Page
    errorBuilder: (context, state) {
      final theme = Theme.of(context);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceXL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceXL),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                ),
                const SizedBox(height: AppTheme.space2XL),
                Text(
                  'Page Not Found',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceLG),
                Text(
                  'The page you are looking for does not exist or has been moved.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (state.uri.toString().isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spaceMD),
                  Text(
                    state.uri.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppTheme.space2XL),
                CustomButton(
                  text: 'Go to Home',
                  onPressed: () => context.go(splash),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  // ── Transition helpers ───────────────────────────────────────────────────

  static Widget _fadeSlide(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  static Widget _slideUp(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}
