import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:toury/core/config/api_config.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories_impl/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_email_usecas.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/verify_password_usecase.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/google_login_usecase.dart';
import '../../features/auth/domain/usecases/google_register_usecase.dart';
import '../../features/auth/domain/usecases/verify_google_token_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //  Dio Configuration
  sl.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: ApiConfig.timeoutDuration),
        receiveTimeout: const Duration(seconds: ApiConfig.timeoutDuration),
        headers: ApiConfig.defaultHeaders,
      ),
    ),
  );

  // Data Source
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  //  Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

  // UseCases
  sl.registerLazySingleton(() => CheckEmailUseCase(sl()));
  sl.registerLazySingleton(() => VerifyPasswordUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => GoogleLoginUseCase(sl()));
  sl.registerLazySingleton(() => GoogleRegisterUseCase(sl()));
  sl.registerLazySingleton(() => VerifyGoogleTokenUseCase(sl()));

  // Cubit
  sl.registerFactory(
    () => AuthCubit(
      checkEmailUseCase: sl(),
      verifyPasswordUseCase: sl(),
      registerUseCase: sl(),
      forgotPasswordUseCase: sl(),
      googleLoginUseCase: sl(),
      googleRegisterUseCase: sl(),
      verifyGoogleTokenUseCase: sl(),
      authRepository: sl(),
    ),
  );
}
