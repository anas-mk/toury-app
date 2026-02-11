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