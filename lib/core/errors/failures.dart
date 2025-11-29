
/// Base class for all failures in the app
abstract class Failure {
  final String message;
  const Failure(this.message);
}

/// Server-related failures (e.g. API, Firebase)
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Failure']);
}

/// Cache or local storage failures
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Failure']);
}

/// Network connection failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}

/// Validation or input failures
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid Input']);
}




