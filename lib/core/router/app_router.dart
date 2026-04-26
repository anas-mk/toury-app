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
import '../../features/helper/features/helper_service_areas/domain/entities/service_area_entities.dart' as helper_sa;
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
import '../../features/helper/features/profile/presentation/pages/account_control_center_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/booking_home_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/scheduled_search_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/instant_search_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/helper_profile_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/booking_confirm_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/waiting_helper_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/booking_details_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/my_bookings_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/scheduled_trip_details_page.dart';
import '../../features/tourist/features/user_booking/domain/entities/helper_booking_entity.dart';
import '../../features/tourist/features/user_booking/domain/entities/booking_detail_entity.dart';
import '../../features/tourist/features/payments/presentation/pages/payment_method_page.dart';
import '../../features/tourist/features/payments/presentation/pages/payment_processing_page.dart';
import '../../features/tourist/features/payments/presentation/pages/payment_webview_page.dart';
import '../../features/tourist/features/payments/presentation/pages/payment_success_page.dart';
import '../../features/tourist/features/payments/presentation/pages/payment_failed_page.dart';
import '../../features/tourist/features/payments/domain/entities/payment_entity.dart';
import '../../features/tourist/features/user_invoices/presentation/pages/user_invoices_page.dart';
import '../../features/tourist/features/user_invoices/domain/entities/invoice_entity.dart';
import '../../features/tourist/features/user_invoices/presentation/pages/user_invoice_detail_page.dart';
import '../../features/tourist/features/user_booking/presentation/pages/reassignment_page.dart';
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

// Helper Bookings imports
import '../../features/helper/features/helper_bookings/presentation/pages/helper_dashboard_page.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/bookings_center_page.dart';
import '../../features/helper/features/helper_chat/presentation/pages/conversations_list_page.dart';
import '../../features/helper/features/helper_invoices/presentation/pages/wallet_hub_page.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/request_details_page.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/active_booking_page.dart';
import '../../features/helper/features/helper_bookings/presentation/pages/helper_booking_details_page.dart';

import 'dart:async';

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
  static const String bookingHome = '/booking-home';
  static const String scheduledSearch = '/scheduled-search';
  static const String instantSearch = '/instant-search';
  static const String helperProfile = '/helper-profile/:id';
  static const String bookingConfirm = '/booking-confirm';
  static const String waitingHelper = '/waiting-helper/:id';
  static const String bookingDetails = '/booking-details/:id';
  static const String scheduledTripDetails = '/scheduled-trip-details';
  static const String myBookings = '/my-bookings';
  static const String reassignment = '/reassignment/:id';
  
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
  static const String helperHome      = '/helper/home';
  static const String helperBookings  = '/helper/bookings';
  static const String helperMessages  = '/helper/messages';
  static const String helperWallet    = '/helper/wallet';
  static const String helperAccount   = '/helper/account';

  // Helper Sub-Routes
  static const String helperDashboard       = helperHome; // For backward compatibility if needed
  static const String helperRequests        = '/helper/requests';
  static const String helperRequestDetails  = '/helper/request-details/:id';
  static const String helperUpcoming        = '/helper/upcoming';
  static const String helperActiveBooking   = '/helper/active-booking';
  static const String helperBookingDetails  = '/helper/booking-details/:id';
  static const String helperHistory         = '/helper/history';
  static const String helperEarnings        = '/helper/earnings';
  static const String helperLocation         = '/helper/location';
  static const String helperEligibilityDebug = '/helper/eligibility-debug';
  static const String helperServiceAreas     = '/helper/service-areas';
  static const String helperAddServiceArea   = '/helper/add-service-area';
  static const String helperEditServiceArea  = '/helper/edit-service-area';
  static const String helperInvoices         = '/helper/invoices';
  static const String helperInvoiceDetail    = '/helper/invoice-detail/:id';
  static const String helperInvoiceView      = '/helper/invoice-view/:id';
  static const String helperRatings          = '/helper/ratings';
  static const String rateUser               = '/helper/rate-user/:id';
  static const String helperReports          = '/helper/reports';
  static const String helperSos              = '/helper/sos';

  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

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
      final isAuthenticated = helper != null && helper.token != null && helper.token!.isNotEmpty;

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

      final authRoutes = [
        roleSelection,
        login,
        helperLogin,
      ];

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
              final email = state.uri.queryParameters['email'] ?? 'mock@example.com';
              return HelperVerifyEmailOtpPage(email: email);
            },
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
          final id = state.pathParameters['id'] ?? (state.extra as String? ?? '');
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
                    BlocProvider(create: (context) => sl<MyBookingsCubit>()..getBookings(pageSize: 5)),
                    BlocProvider(create: (context) => sl<BookingStatusCubit>()..startPollingForActive()),
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
            child: InterviewScreen(interviewId: cubit.state.interview?.id ?? ''),
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
          final destination = state.extra as String?;
          return BlocProvider(
            create: (_) => sl<SearchHelpersCubit>(),
            child: ScheduledSearchPage(initialDestination: destination),
          );
        },
      ),
      GoRoute(
        path: instantSearch,
        name: 'instant-search',
        builder: (context, state) {
          final helper = state.extra as HelperBookingEntity?;
          return BlocProvider(
            create: (_) => sl<SearchHelpersCubit>(),
            child: InstantSearchPage(preSelectedHelper: helper),
          );
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
      GoRoute(
        path: waitingHelper,
        name: 'waiting-helper',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>;
          return WaitingHelperPage(
            bookingId: id,
            booking: extra['booking'] as BookingDetailEntity,
          );
        },
      ),
      GoRoute(
        path: scheduledTripDetails,
        name: 'scheduled-trip-details',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ScheduledTripDetailsPage(
            trip: extra?['trip'] as ScheduledTripEntity?,
          );
        },
      ),
      GoRoute(
        path: bookingDetails,
        name: 'booking-details',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>?;
          return BookingDetailsPage(
            bookingId: id,
            initialBooking: extra?['booking'] as BookingDetailEntity?,
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

      // ── User Booking Tracking ─────────────────────────────────────────
      GoRoute(
        path: userTracking,
        name: 'user-tracking',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final pickupLat = double.parse(state.uri.queryParameters['pickupLat'] ?? '0');
          final pickupLng = double.parse(state.uri.queryParameters['pickupLng'] ?? '0');
          final destLat = double.parse(state.uri.queryParameters['destLat'] ?? '0');
          final destLng = double.parse(state.uri.queryParameters['destLng'] ?? '0');
          
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
          final pickupLat = double.parse(state.uri.queryParameters['pickupLat'] ?? '0');
          final pickupLng = double.parse(state.uri.queryParameters['pickupLng'] ?? '0');
          final destLat = double.parse(state.uri.queryParameters['destLat'] ?? '0');
          final destLng = double.parse(state.uri.queryParameters['destLng'] ?? '0');
          
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
      GoRoute(
        path: reassignment,
        name: 'reassignment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>;
          return ReassignmentPage(
            bookingId: id,
            booking: extra['booking'] as BookingDetailEntity,
          );
        },
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
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 16),
            const Text('Page not found', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(state.uri.toString(), style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(splash),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
              child: const Text('Go to Start'),
            ),
          ],
        ),
      ),
    ),
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
        position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
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
      position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}
