import 'package:equatable/equatable.dart';

/// Base class for all failures in the app
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Server-related failures (e.g. API, Firebase)
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server Failure']) : super(message);
}

/// Cache or local storage failures
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache Failure']) : super(message);
}

/// Network connection failures
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No Internet Connection'])
      : super(message);
}

/// Validation or input failures
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Invalid Input']) : super(message);
}
