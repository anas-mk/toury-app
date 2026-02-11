import 'package:equatable/equatable.dart';

/// Base Failure Class
/// كل الـ Failures يجب أن ترث من هذا الـ Class
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

/// Server Failure - فشل في الاتصال بالـ Server أو API
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Failure']);
}

/// Cache Failure - فشل في الـ Cache أو Local Storage
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Failure']);
}

/// Network Failure - فشل في الاتصال بالإنترنت
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}

/// Validation Failure - فشل في الـ Input أو Validation
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Invalid Input']);
}

/// Location Failure - فشل في الحصول على الموقع
class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Location Failure']);
}

/// Authentication Failure - فشل في الـ Authentication
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'Authentication Failed']);
}

/// Unauthorized Failure - المستخدم غير مصرح له
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized Access']);
}

/// Timeout Failure - انتهى وقت الطلب
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request Timeout']);
}

/// Generic Failure - خطأ عام غير محدد
class GenericFailure extends Failure {
  const GenericFailure([super.message = 'Something went wrong']);
}