/// [ApiConfig]
///
/// Centralized API configuration for the entire application.
/// All endpoint constants are defined here — no hardcoded URLs elsewhere.
///
/// Route Groups:
///   - Tourist Auth
///   - Helper Auth
///   - Helper Profile (basic info, image, selfie, documents, car, certificates)
///   - Language Interview
class ApiConfig {
  // ── Base URL ────────────────────────────────────────────────────────────────
  /// Production base URL (no trailing slash).
  static const String baseUrl = 'https://tourestaapi.runasp.net/api';

  // ── Timeouts ────────────────────────────────────────────────────────────────
  /// Connection timeout in milliseconds (2 minutes — allows large file uploads).
  static const int connectTimeout = 120000;

  /// Receive timeout in milliseconds (2 minutes).
  static const int receiveTimeout = 120000;

  // ── Default Headers ─────────────────────────────────────────────────────────
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
  };

  /// Returns authenticated headers with the given bearer token.
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // TOURIST — Auth Endpoints
  // ══════════════════════════════════════════════════════════════════════════════

  static const String loginEndpoint      = '/Auth/check-email';
  static const String verifyPassword     = '/Auth/verify-password';
  static const String registerEndpoint   = '/Auth/register';
  static const String verifyCode         = '/Auth/verify-code';
  static const String resendVerifyCode   = '/Auth/resend-verification-code';

  // Google Auth
  static const String googleLogin        = '/Auth/google-login';
  static const String googleRegister     = '/Auth/google-register';

  // Password Reset
  static const String forgotPassword     = '/Auth/forgot-password';
  static const String resetPassword      = '/Auth/reset-password';

  // Profile
  static const String updateProfile      = '/Auth/update-profile';

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER — Auth Endpoints
  // ══════════════════════════════════════════════════════════════════════════════

  static const String helperRegister         = '/helper/auth/register';
  static const String helperLogin            = '/helper/auth/login';
  static const String helperVerifyLoginOtp   = '/helper/auth/verify-login-otp';
  static const String helperVerifyEmail      = '/helper/auth/verify-email';
  static const String helperLoginOtp         = '/helper/auth/resend-login-otp';
  static const String helperResendCode       = '/helper/auth/resend-code';
  static const String helperForgotPassword   = '/helper/auth/forgot-password';
  static const String helperResetPassword    = '/helper/auth/reset-password';

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER — Profile Endpoints
  // ══════════════════════════════════════════════════════════════════════════════

  /// GET /api/helper/profile — fetch the full helper profile.
  static const String helperProfile           = '/helper/profile';

  /// GET /api/helper/status — fetch current helper account status.
  static const String helperStatus            = '/helper/status';

  /// GET /api/helper/eligibility — check if helper is eligible to work.
  static const String helperEligibility       = '/helper/eligibility';

  /// PUT /api/helper/profile/basic-info — update name, phone, etc.
  static const String helperProfileBasicInfo  = '/helper/profile/basic-info';

  /// PUT /api/helper/profile/image — upload/replace profile photo.
  static const String helperProfileImage      = '/helper/profile/image';

  /// PUT /api/helper/profile/selfie — upload/replace selfie verification photo.
  static const String helperProfileSelfie     = '/helper/profile/selfie';

  /// PUT /api/helper/profile/documents — upload/replace identity documents.
  static const String helperProfileDocuments  = '/helper/profile/documents';

  // ── Helper Profile — Car Sub-Resource ───────────────────────────────────────

  /// PUT /api/helper/profile/car — create or update car info.
  static const String helperProfileCar        = '/helper/profile/car';

  /// DELETE /api/helper/profile/car — remove the helper's car.
  static const String helperProfileCarDelete  = '/helper/profile/car';

  // ── Helper Profile — Certificates Sub-Resource ──────────────────────────────

  /// POST /api/helper/profile/certificates — add a new certificate.
  static const String helperProfileCertificates = '/helper/profile/certificates';

  /// DELETE /api/helper/profile/certificates/{id}
  static String helperProfileCertificateById(String id) =>
      '/helper/profile/certificates/$id';

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER — Language Interview Endpoints
  // ══════════════════════════════════════════════════════════════════════════════

  static const String getLanguages = '/helper/languages';

  static String startInterview(String code) =>
      '/helper/languages/$code/start-interview';

  static String getInterview(String id) => '/helper/interviews/$id';

  static String submitAnswer(String id) => '/helper/interviews/$id/answer';

  static String submitInterview(String id) => '/helper/interviews/$id/submit';
}