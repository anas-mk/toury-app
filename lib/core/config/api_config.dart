/// ApiConfig
///
/// Single source of truth for every HTTP endpoint and timeout value
/// used throughout the Toury application.
class ApiConfig {
  // Base URL
  static const String baseUrl = 'https://tourestaapi.runasp.net/api';

  // Timeouts (milliseconds)
  static const int connectTimeout = 120000;
  static const int receiveTimeout = 120000;

  // Default Headers
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  // ==========================================================================
  // TOURIST - Auth Endpoints
  // ==========================================================================

  static const String loginEndpoint    = '/Auth/check-email';
  static const String verifyPassword   = '/Auth/verify-password';
  static const String registerEndpoint = '/Auth/register';
  static const String verifyCode       = '/Auth/verify-code';
  static const String resendVerifyCode = '/Auth/resend-verification-code';
  static const String googleLogin      = '/Auth/google-login';
  static const String googleRegister   = '/Auth/google-register';
  static const String forgotPassword   = '/Auth/forgot-password';
  static const String resetPassword    = '/Auth/reset-password';
  static const String updateProfile    = '/Auth/update-profile';

  // ==========================================================================
  // HELPER - Auth Endpoints
  // ==========================================================================

  static const String helperRegister        = '/helper/auth/register';
  static const String helperLogin           = '/helper/auth/login';
  static const String helperVerifyLoginOtp  = '/helper/auth/verify-login-otp';
  static const String helperVerifyEmail     = '/helper/auth/verify-email';
  static const String helperLoginOtp        = '/helper/auth/resend-login-otp';
  static const String helperResendCode      = '/helper/auth/resend-code';
  static const String helperForgotPassword  = '/helper/auth/forgot-password';
  static const String helperResetPassword   = '/helper/auth/reset-password';

  // ==========================================================================
  // HELPER - Profile Endpoints
  // ==========================================================================

  static const String helperProfile          = '/helper/profile';
  static const String helperStatus           = '/helper/status';
  static const String helperEligibility      = '/helper/eligibility';
  static const String helperProfileBasicInfo = '/helper/profile/basic-info';
  static const String helperProfileImage     = '/helper/profile/image';
  static const String helperProfileSelfie    = '/helper/profile/selfie';
  static const String helperProfileDocuments = '/helper/profile/documents';
  static const String helperProfileCar       = '/helper/profile/car';
  static const String helperProfileCarDelete = '/helper/profile/car';
  static const String helperProfileCertificates = '/helper/profile/certificates';
  static String helperProfileCertificateById(String id) =>
      '/helper/profile/certificates/$id';

  // ==========================================================================
  // TOURIST - User Bookings Endpoints
  // ==========================================================================

  static const String searchScheduledHelpers = '/user/bookings/scheduled/search';
  static const String searchInstantHelpers   = '/user/bookings/instant/search';
  static String getHelperProfile(String helperId) => '/user/bookings/helpers/$helperId/profile';
  static const String createScheduledBooking = '/user/bookings/scheduled';
  static const String createInstantBooking   = '/user/bookings/instant';
  static String getBookingDetails(String bookingId) => '/user/bookings/$bookingId';
  static const String getMyBookings          = '/user/bookings';
  static String cancelBooking(String bookingId) => '/user/bookings/$bookingId/cancel';
  static String getAlternatives(String bookingId) => '/user/bookings/$bookingId/alternatives';
  static String getBookingStatus(String bookingId) => '/user/bookings/$bookingId/status';

  // ==========================================================================
  // HELPER - Language Interview Endpoints
  // ==========================================================================

  static const String getLanguages = '/helper/languages';
  static String startInterview(String code) => '/helper/languages/$code/start-interview';
  static String getInterview(String id)     => '/helper/interviews/$id';
  static String submitAnswer(String id)     => '/helper/interviews/$id/answer';
  static String submitInterview(String id)  => '/helper/interviews/$id/submit';

  // ==========================================================================
  // HELPER - Service Areas Endpoints
  // ==========================================================================

  static const String helperServiceAreas = '/helper/service-areas';
  static String helperServiceAreaById(String id) => '/helper/service-areas/$id';

  // ==========================================================================
  // HELPER - Bookings Endpoints
  // ==========================================================================

  static const String helperDashboard    = '/helper/bookings/dashboard';
  static const String helperAvailability = '/helper/bookings/availability';
  static const String helperRequests     = '/helper/bookings/requests';
  static String helperRequestDetails(String id) => '/helper/bookings/requests/$id';
  static String helperAcceptRequest(String id)  => '/helper/bookings/requests/$id/accept';
  static String helperDeclineRequest(String id) => '/helper/bookings/requests/$id/decline';
  static const String helperUpcoming     = '/helper/bookings/upcoming';
  static const String helperActiveBooking = '/helper/bookings/active';
  static String helperStartTrip(String id) => '/helper/bookings/$id/start';
  static String helperEndTrip(String id)   => '/helper/bookings/$id/end';
  static const String helperHistory      = '/helper/bookings/history';
  static const String helperEarnings     = '/helper/bookings/earnings';
  static String helperBookingDetails(String id) => '/helper/bookings/$id';

  // ==========================================================================
  // HELPER - Location and Real-time Endpoints
  // ==========================================================================

  static const String helperLocationUpdate      = '/helper/location/update';
  static const String helperLocationStatus      = '/helper/location/status';
  static const String helperLocationEligibility = '/helper/location/instant-eligibility';

  // SignalR Hub URL (strips /api suffix from baseUrl)
  static String get bookingHub => baseUrl.replaceAll('/api', '') + '/hubs/booking';

  // ==========================================================================
  // HELPER - Invoices Endpoints
  // ==========================================================================

  static const String helperInvoices              = '/helper/invoices';
  static String helperInvoiceById(String id)      => '/helper/invoices/$id';
  static String helperInvoiceByBooking(String id) => '/helper/invoices/booking/$id';
  static const String helperInvoiceSummary        = '/helper/invoices/summary';
  static String helperInvoiceView(String id)      => '/helper/invoices/$id/view';

  // ==========================================================================
  // HELPER - Ratings Endpoints
  // ==========================================================================

  static String helperRateUser(String bookingId) => '/helper/ratings/booking/$bookingId/user';
  static String helperBookingRatingState(String bookingId) => '/helper/ratings/booking/$bookingId';
  static const String helperReceivedRatings = '/helper/ratings/received';
  static const String helperRatingsSummary  = '/helper/ratings/summary';

  // ==========================================================================
  // HELPER - Chat Endpoints
  // ==========================================================================

  static String helperConversation(String bookingId) => '/helper/bookings/$bookingId/chat';
  static String helperChatMessages(String bookingId) => '/helper/bookings/$bookingId/chat/messages';
  static String helperSendChatMessage(String bookingId) => '/helper/bookings/$bookingId/chat/messages';
  static String helperMarkChatRead(String bookingId) => '/helper/bookings/$bookingId/chat/read';

  // ==========================================================================
  // HELPER - SOS Endpoints (Placeholder for future integration)
  // ==========================================================================
  // static const String helperSosPanic = '/helper/sos/panic';
  // static const String helperSosCall  = '/helper/sos/call';
}