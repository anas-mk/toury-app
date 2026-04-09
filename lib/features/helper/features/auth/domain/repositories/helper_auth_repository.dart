import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/helper_auth_response_model.dart';
import '../../data/models/helper_login_response_model.dart';
import '../../domain/usecases/register_helper_usecase.dart';

abstract class HelperAuthRepository {
  Future<Either<Failure, HelperLoginResponseModel>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, HelperAuthResponseModel>> verifyLoginOtp({
    required String email,
    required String code,
  });

  Future<Either<Failure, HelperAuthResponseModel>> verifyEmail({
    required String email,
    required String code,
  });

  Future<Either<Failure, HelperAuthResponseModel>> registerHelper(HelperRegisterParams params);

  Future<Either<Failure, Unit>> resendLoginOtp(String email);

  Future<Either<Failure, Unit>> resendRegistrationCode(String email);

  Future<Either<Failure, void>> logout();

  // Password Reset (inherited structure from tourist if needed)
  Future<Either<Failure, Map<String, dynamic>>> forgotPassword(String email);
  Future<Either<Failure, Map<String, dynamic>>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
