class ApiConfig {
  //API base URL
  //http://tourestaapi.runasp.net/api/Auth/register
  static const String baseUrl = 'http://tourestaapi.runasp.net/api/';

  // Auth endpoints
  static const String loginEndpoint = 'Auth/check-email';
  static const String verifyPassword = 'Auth/verify-password';
  static const String registerEndpoint = 'Auth/register';
  static const String logoutEndpoint = 'Auth/logout';
  static const String googleLogin = 'Auth/google-login';
  static const String verifyCode = 'Auth/verify-code';
  static const String googleRegister = 'Auth/google-register';
  static const String googleVerifyCode = 'Auth/google-verify-code';
  static const String verifyGoogleToken = 'Auth/verify-google-token';

  static const String forgotPasswordEndpoint = 'Auth/forgot-password';
  static const String profileEndpoint = 'Auth/profile';

  // Request timeout duration in seconds
  static const int timeoutDuration = 30;

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Error messages
  static const String networkErrorMessage = 'No internet connection';
  static const String serverErrorMessage = 'Server error, please try again';
  static const String timeoutErrorMessage = 'Request timeout, please try again';
  static const String unknownErrorMessage = 'An unexpected error occurred';
}
