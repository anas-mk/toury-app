/// Base Exception Class
class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}

/// Server Exception - مشكلة في الـ Server
class ServerException extends AppException {
  ServerException(super.message);
}

/// Location Exception - مشكلة في الـ Location
class LocationException extends AppException {
  LocationException(super.message);
}

/// Cache Exception - مشكلة في الـ Cache
class CacheException extends AppException {
  CacheException(super.message);
}

/// Network Exception - مشكلة في الإنترنت
class NetworkException extends AppException {
  NetworkException(super.message);
}

/// Unauthorized Exception - 401 Unauthorized
class UnauthorizedException extends AppException {
  UnauthorizedException([super.message = 'Unauthorized']);
}

/// Forbidden Exception - 403 Forbidden
class ForbiddenException extends AppException {
  ForbiddenException([super.message = 'Forbidden']);
}

/// Validation Exception - 400 Bad Request
class ValidationException extends AppException {
  ValidationException(super.message);
}

/// Timeout Exception - Connection Timeout
class TimeoutException extends AppException {
  TimeoutException([super.message = 'Connection Timeout']);
}

/// Not Found Exception - 404
class NotFoundException extends AppException {
  NotFoundException([super.message = 'Not Found']);
}
