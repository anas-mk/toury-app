import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/auth_interceptor.dart';
import '../config/api_config.dart';

// ============================================================
// Auth Feature Imports
// ============================================================
import '../../features/tourist/features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/tourist/features/auth/domain/repositories/auth_repository.dart';
import '../../features/tourist/features/auth/domain/usecases/get_cached_user_usecase.dart';
import '../../features/tourist/features/auth/domain/usecases/resend_verification_code_usecase.dart';
import '../../features/tourist/features/auth/domain/usecases/verify_code_usecase.dart';
import '../../features/tourist/features/maps/data/datasources/location_data_source.dart';
import '../../features/tourist/features/maps/data/datasources/location_data_source_impl.dart';
import '../../features/tourist/features/maps/data/datasources/routing_data_source.dart';
import '../../features/tourist/features/maps/data/datasources/routing_data_source_impl.dart';
import '../../features/tourist/features/maps/data/repositories/location_repository_impl.dart';
import '../../features/tourist/features/maps/data/repositories/routing_repository_impl.dart';
import '../../features/tourist/features/maps/domain/repositories/location_repository.dart';
import '../../features/tourist/features/maps/domain/repositories/routing_repository.dart';
import '../../features/tourist/features/maps/domain/usecases/get_current_location.dart';
import '../../features/tourist/features/maps/domain/usecases/get_route.dart';
import '../../features/tourist/features/maps/domain/usecases/search_locations.dart';
import '../../features/tourist/features/maps/presentation/cubit/map_cubit.dart';
import '../../features/tourist/features/maps/presentation/cubit/search_location_cubit.dart';
import '../../features/tourist/features/maps/presentation/cubit/trip_cubit.dart';
import '../../features/tourist/features/profile/domain/usecases/update_profile_usecase.dart';
import '../../features/tourist/features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/tourist/features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/tourist/features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/tourist/features/auth/domain/usecases/check_email_usecas.dart';
import '../../features/tourist/features/auth/domain/usecases/google_login_usecase.dart';
import '../../features/tourist/features/auth/domain/usecases/logout_usecase.dart';
import '../../features/tourist/features/auth/domain/usecases/register_usecase.dart';
import '../../features/tourist/features/auth/domain/usecases/verify_password_usecase.dart';
import '../../features/tourist/features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/tourist/features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/tourist/features/auth/presentation/cubit/auth_cubit.dart';

// ============================================================
// Helper Auth Feature Imports
// ============================================================
import '../../features/helper/features/auth/data/datasources/helper_auth_remote_data_source.dart';
import '../../features/helper/features/auth/data/datasources/helper_local_data_source.dart';
import '../../features/helper/features/auth/data/repositories/helper_auth_repository_impl.dart';
import '../../features/helper/features/auth/domain/repositories/helper_auth_repository.dart';
import '../../features/helper/features/auth/domain/usecases/register_helper_usecase.dart';
import '../../features/helper/features/auth/domain/usecases/helper_login_usecase.dart';
import '../../features/helper/features/auth/domain/usecases/verify_helper_login_otp_usecase.dart';
import '../../features/helper/features/auth/domain/usecases/verify_helper_email_usecase.dart';
import '../../features/helper/features/auth/domain/usecases/resend_helper_login_otp_usecase.dart';
import '../../features/helper/features/auth/domain/usecases/resend_helper_code_usecase.dart';
import '../../features/helper/features/auth/domain/usecases/forgot_helper_password_usecase.dart';
import '../../features/helper/features/auth/domain/usecases/reset_helper_password_usecase.dart';
import '../../features/helper/features/auth/domain/usecases/helper_logout_usecase.dart';
import '../../features/helper/features/auth/presentation/cubit/helper_auth_cubit.dart';
import '../../features/helper/features/language_interview/data/datasources/interview_remote_data_source.dart';
import '../../features/helper/features/language_interview/data/repositories/interview_repository_impl.dart';
import '../../features/helper/features/language_interview/domain/repositories/interview_repository.dart';
import '../../features/helper/features/language_interview/domain/usecases/get_languages_usecase.dart';
import '../../features/helper/features/language_interview/domain/usecases/start_interview_usecase.dart';
import '../../features/helper/features/language_interview/domain/usecases/get_interview_usecase.dart';
import '../../features/helper/features/language_interview/domain/usecases/submit_answer_usecase.dart';
import '../../features/helper/features/language_interview/domain/usecases/submit_interview_usecase.dart';
import '../../features/helper/features/home/presentation/cubit/exams_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ============================================================
  // Features - Auth
  // ============================================================

  // Cubits
  sl.registerFactory(
        () => AuthCubit(
      checkEmailUseCase: sl(),
      verifyPasswordUseCase: sl(),
      registerUseCase: sl(),
      googleLoginUseCase: sl(),
      authRepository: sl(),
      forgotPasswordUseCase: sl(),
      resetPasswordUseCase: sl(),
      verifyCodeUseCase: sl(),
      resendVerificationCodeUseCase: sl(),
    ),
  );

  sl.registerFactory(
        () => ProfileCubit(sl<AuthRepository>()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CheckEmailUseCase(sl()));
  sl.registerLazySingleton(() => VerifyPasswordUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => VerifyCodeUseCase(sl()));
  sl.registerLazySingleton(() => GoogleLoginUseCase(sl()));
  sl.registerLazySingleton(() => GetCachedUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => ResendVerificationCodeUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(),
  );

  // ============================================================
  // Features - Helper Auth
  // ============================================================

  // Cubit
  sl.registerFactory(
    () => HelperAuthCubit(
      registerHelperUseCase: sl(),
      helperLoginUseCase: sl(),
      verifyHelperLoginOtpUseCase: sl(),
      verifyHelperEmailUseCase: sl(),
      resendHelperLoginOtpUseCase: sl(),
      resendHelperCodeUseCase: sl(),
      forgotHelperPasswordUseCase: sl(),
      resetHelperPasswordUseCase: sl(),
      helperLogoutUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => RegisterHelperUseCase(sl()));
  sl.registerLazySingleton(() => HelperLoginUseCase(sl()));
  sl.registerLazySingleton(() => VerifyHelperLoginOtpUseCase(sl()));
  sl.registerLazySingleton(() => VerifyHelperEmailUseCase(sl()));
  sl.registerLazySingleton(() => ResendHelperLoginOtpUseCase(sl()));
  sl.registerLazySingleton(() => ResendHelperCodeUseCase(sl()));
  sl.registerLazySingleton(() => ForgotHelperPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetHelperPasswordUseCase(sl()));
  sl.registerLazySingleton(() => HelperLogoutUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HelperAuthRepository>(
    () => HelperAuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<HelperAuthRemoteDataSource>(
    () => HelperAuthRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<HelperLocalDataSource>(
    () => HelperLocalDataSourceImpl(),
  );

  // ============================================================
  // Features - Google Maps
  // ============================================================

  // Cubits
  sl.registerFactory(
        () => MapCubit(
      getCurrentLocation: sl(),
      getRoute: sl(),
    ),
  );

  sl.registerFactory(
        () => SearchLocationCubit(
      searchLocations: sl(),
    ),
  );

  sl.registerFactory(
        () => TripCubit(
      locationRepository: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetCurrentLocation(sl()));
  sl.registerLazySingleton(() => SearchLocations(sl()));
  sl.registerLazySingleton(() => GetRoute(sl()));

  // Repositories
  sl.registerLazySingleton<LocationRepository>(
        () => LocationRepositoryImpl(dataSource: sl()),
  );

  sl.registerLazySingleton<RoutingRepository>(
        () => RoutingRepositoryImpl(dataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<LocationDataSource>(
        () => LocationDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<RoutingDataSource>(
        () => RoutingDataSourceImpl(client: sl()),
  );

  // ============================================================
  // Features - Language Interview
  // ============================================================

  // Cubit
  sl.registerLazySingleton(
    () => ExamsCubit(
      getLanguagesUseCase: sl(),
      startInterviewUseCase: sl(),
      getInterviewUseCase: sl(),
      submitAnswerUseCase: sl(),
      submitInterviewUseCase: sl(),
      repository: sl(),
      sharedPreferences: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetLanguagesUseCase(sl()));
  sl.registerLazySingleton(() => StartInterviewUseCase(sl()));
  sl.registerLazySingleton(() => GetInterviewUseCase(sl()));
  sl.registerLazySingleton(() => SubmitAnswerUseCase(sl()));
  sl.registerLazySingleton(() => SubmitInterviewUseCase(sl()));

  // Repository
  sl.registerLazySingleton<InterviewRepository>(
    () => InterviewRepositoryImpl(sl()),
  );

  // Data Sources
  sl.registerLazySingleton<InterviewRemoteDataSource>(
    () => InterviewRemoteDataSourceImpl(sl()),
  );

  // ============================================================
  // Core - External Dependencies
  // ============================================================

  // Dio (🌐 Auth API calls)
  sl.registerLazySingleton(() => _createDio());

  // HTTP Client (🌐 Maps API calls)
  sl.registerLazySingleton(() => http.Client());

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}

// ============================================================
// Helper Functions
// ============================================================

Dio _createDio() {
  final dio = Dio();

  dio.options = BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: Duration(milliseconds: ApiConfig.connectTimeout),
    receiveTimeout: Duration(milliseconds: ApiConfig.receiveTimeout),
    headers: ApiConfig.defaultHeaders,
    validateStatus: (status) {
      return status != null && status < 500;
    },
  );

  dio.interceptors.add(AuthInterceptor());

  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('🌐 DIO LOG: $obj'),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        print('REQUEST: ${options.method} ${options.uri}');
        print('DATA: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('RESPONSE [${response.statusCode}]: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ ERROR [${error.response?.statusCode}]: ${error.message}');
        print('🔗 URL: ${error.requestOptions.uri}');
        if (error.response?.data != null) {
          print('📄 ERROR DATA: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}