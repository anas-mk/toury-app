class ApiConfig {
  // API base URL (without trailing slash for cleaner URLs)
  
  static const String baseUrl = 'https://tourestaapi.runasp.net/api';

  // ========== Auth Endpoints (relative paths) ==========

  // Login & Registration
  static const String loginEndpoint = '/Auth/check-email';
  static const String verifyPassword = '/Auth/verify-password';
  static const String registerEndpoint = '/Auth/register';
  static const String verifyCode = '/Auth/verify-code';
  static const String resendVerifyCode = '/Auth/resend-verification-code';

  // Google Authentication
  static const String googleLogin = '/Auth/google-login';
  static const String googleRegister = '/Auth/google-register';

  // Password Reset
  static const String forgotPassword = '/Auth/forgot-password';
  static const String resetPassword = '/Auth/reset-password';
  

  // ========== Helper Auth Endpoints ==========
  static const String helperRegister = '/helper/auth/register';
  static const String helperLogin = '/helper/auth/login';
  static const String helperVerifyLoginOtp = '/helper/auth/verify-login-otp';
  static const String helperVerifyEmail = '/helper/auth/verify-email';
  static const String helperLoginOtp = '/helper/auth/resend-login-otp';
  static const String helperResendCode = '/helper/auth/resend-code';


  static const String helperForgotPassword = '/helper/auth/forgot-password';
  static const String helperResetPassword = '/helper/auth/reset-password';



  // Update Profile
  static const String updateProfile = '/Auth/update-profile';


  // ========== Configuration ==========

  // Request timeout duration in seconds
  static const int connectTimeout = 120000; // 120 seconds (2 minutes)
  static const int receiveTimeout = 120000; // 120 seconds (2 minutes)

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
  };

  // Helper method to create authenticated headers
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }
}