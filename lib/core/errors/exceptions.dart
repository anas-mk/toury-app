/// Base class for all exceptions that come from external sources (e.g. Firebase, APIs)
class ServerException implements Exception {
  final String message;

  ServerException([this.message = 'Server Exception']);
}

/// Exception thrown when there is no internet connection
class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = 'No Internet Connection']);
}

/// Exception thrown when something goes wrong in local storage (e.g. cache)
class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Cache Exception']);
}

/// Exception thrown when input or validation fails
class ValidationException implements Exception {
  final String message;

  ValidationException([this.message = 'Invalid Input']);
}
