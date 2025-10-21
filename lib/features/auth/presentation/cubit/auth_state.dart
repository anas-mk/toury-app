import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

/// Abstract base state
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// الحالة الابتدائية
class AuthInitial extends AuthState {}

/// حالة التحميل (Loading)
class AuthLoading extends AuthState {}

/// حالة تم التحقق من وجود الإيميل
class AuthEmailExists extends AuthState {
  final String email;
  const AuthEmailExists(this.email);

  @override
  List<Object?> get props => [email];
}

/// حالة تسجيل الدخول ناجح
class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// حالة تسجيل الخروج / غير مصرح به
class AuthUnauthenticated extends AuthState {}

/// حالة وجود خطأ
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// حالة خاصة بالخطأ في كلمة المرور (اختياري)
class AuthPasswordError extends AuthState {
  final String message;
  const AuthPasswordError(this.message);

  @override
  List<Object?> get props => [message];
}

/// حالة تغيير كلمة المرور ناجح (اختياري)
class AuthPasswordUpdated extends AuthState {
  const AuthPasswordUpdated();
}

/// حالة إرسال رابط إعادة تعيين كلمة المرور
class AuthPasswordResetSent extends AuthState {
  final String message;
  const AuthPasswordResetSent(this.message);

  @override
  List<Object?> get props => [message];
}

/// حالة الحاجة لتسجيل حساب Google
class AuthGoogleRegistrationNeeded extends AuthState {
  final String googleToken;
  const AuthGoogleRegistrationNeeded(this.googleToken);

  @override
  List<Object?> get props => [googleToken];
}
