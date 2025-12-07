class ApiConfig {
  // API base URL (without trailing slash for cleaner URLs)
  
  static const String baseUrl = 'http://tourestaapi.runasp.net/api';

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
  


  // Update Profile
  static const String updateProfile = '/Auth/update-profile';


  // ========== Configuration ==========

  // Request timeout duration in seconds
  static const int connectTimeout = 30000; // 30 seconds in milliseconds
  static const int receiveTimeout = 30000; // 30 seconds in milliseconds

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
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