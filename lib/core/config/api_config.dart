class ApiConfig {
  //API base URL
  //http://tourestaapi.runasp.net/api/Auth/register
  static const String baseUrl = 'http://tourestaapi.runasp.net/api/';

  // Auth endpoints
  static const String loginEndpoint = 'Auth/check-email';
  static const String verifyPassword = 'Auth/verify-password';
  static const String registerEndpoint = 'Auth/register';

  static const String googleLogin = 'Auth/google-login';
  static const String googleVerifyCode = 'Auth/verify-code';
  static const String googleRegister = 'Auth/google-register';


  // Request timeout duration in seconds
  static const int timeoutDuration = 30;

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };


}
