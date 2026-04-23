import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/services/auth_service.dart';
import '../../features/helper/features/language_interview/presentation/cubit/exams_cubit.dart';
import '../config/api_config.dart';

// ============================================================
// Tourist Auth Feature Imports
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
// Tourist User Booking Feature Imports
// ============================================================
import '../../features/tourist/features/user_booking/data/datasources/user_booking_service.dart';
import '../../features/tourist/features/user_booking/data/datasources/user_booking_service_impl.dart';
import '../../features/tourist/features/user_booking/data/repositories/user_booking_repository_impl.dart';
import '../../features/tourist/features/user_booking/domain/repositories/user_booking_repository.dart';
import '../../features/tourist/features/user_booking/domain/usecases/cancel_booking_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/create_instant_booking_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/create_scheduled_booking_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/get_alternatives_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/get_booking_details_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/get_booking_status_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/get_helper_profile_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/get_my_bookings_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/search_instant_helpers_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/search_scheduled_helpers_usecase.dart';
import '../../features/tourist/features/user_booking/presentation/cubit/search_helpers_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubit/helpers_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubit/booking_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubit/my_bookings_cubit.dart';

// ============================================================
// Helper Auth Feature Imports
// ============================================================
import '../../features/helper/features/auth/data/datasources/helper_auth_remote_data_source.dart';
import '../../features/tourist/features/user_booking/presentation/cubit/chat_cubit.dart';
import '../../features/tourist/features/user_booking/domain/usecases/get_chat_info_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/get_messages_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/send_message_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/mark_as_read_usecase.dart';
import '../../features/tourist/features/user_booking/domain/repositories/chat_repository.dart';
import '../../features/tourist/features/user_booking/data/repositories/chat_repository_impl.dart';
import '../../features/tourist/features/user_booking/data/datasources/chat_service.dart';
import '../../features/tourist/features/user_booking/data/datasources/chat_service_impl.dart';
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
import '../../features/helper/features/helper_bookings/presentation/cubit/helper_bookings_cubit.dart';
import '../../features/helper/features/helper_bookings/domain/usecases/helper_bookings_usecases.dart';
import '../../features/helper/features/helper_bookings/domain/repositories/helper_bookings_repository.dart';
import '../../features/helper/features/helper_bookings/data/repositories/helper_bookings_repository_impl.dart';
import '../../features/helper/features/helper_bookings/data/datasources/helper_bookings_service.dart';
import '../../features/helper/features/helper_bookings/data/datasources/helper_bookings_service_impl.dart';
import '../../features/helper/features/ratings/presentation/cubit/helper_ratings_cubit.dart';
import '../../features/helper/features/ratings/domain/usecases/rating_usecases.dart';
import '../../features/helper/features/ratings/data/repositories/helper_ratings_repository_impl.dart';
import '../../features/helper/features/ratings/data/datasources/helper_ratings_service.dart';
import '../../features/helper/features/location/presentation/cubit/helper_location_cubit.dart';
import '../../features/helper/features/location/domain/usecases/location_usecases.dart';
import '../../features/helper/features/location/data/repositories/helper_location_repository_impl.dart';
import '../../features/helper/features/location/data/datasources/helper_location_service.dart';
import '../../features/helper/features/chat/presentation/cubit/helper_chat_cubit.dart';
import '../../features/helper/features/chat/domain/usecases/helper_chat_usecases.dart';
import '../../features/helper/features/chat/data/repositories/helper_chat_repository_impl.dart';
import '../../features/helper/features/chat/data/datasources/helper_chat_service.dart';
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

// ============================================================
// Helper Profile Feature Imports
// ============================================================
import '../../features/helper/features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/helper/features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/helper/features/profile/domain/repositories/profile_repository.dart';
import '../../features/helper/features/profile/domain/usecases/get_profile_usecase.dart';
import '../../features/helper/features/profile/domain/usecases/get_status_usecase.dart';
import '../../features/helper/features/profile/domain/usecases/check_eligibility_usecase.dart';
import '../../features/helper/features/profile/domain/usecases/update_basic_info_usecase.dart';
import '../../features/helper/features/profile/domain/usecases/upload_profile_image_usecase.dart';
import '../../features/helper/features/profile/domain/usecases/upload_selfie_usecase.dart';
import '../../features/helper/features/profile/domain/usecases/upload_documents_usecase.dart';
import '../../features/helper/features/profile/domain/usecases/add_car_usecase.dart';
import '../../features/helper/features/profile/domain/usecases/delete_car_usecase.dart';
import '../../features/helper/features/profile/domain/usecases/add_certificate_usecase.dart';
import '../../features/helper/features/profile/domain/usecases/delete_certificate_usecase.dart';
import '../../features/helper/features/profile/presentation/cubit/profile_cubit.dart' as helper_profile;
import '../../features/helper/features/service_areas/data/datasources/service_areas_remote_data_source.dart';
import '../../features/helper/features/service_areas/data/repositories/service_areas_repository_impl.dart';
import '../../features/helper/features/service_areas/domain/repositories/service_areas_repository.dart';
import '../../features/helper/features/service_areas/domain/usecases/create_service_area_usecase.dart';
import '../../features/helper/features/service_areas/domain/usecases/delete_service_area_usecase.dart';
import '../../features/helper/features/service_areas/domain/usecases/get_service_areas_usecase.dart';
import '../../features/helper/features/service_areas/domain/usecases/update_service_area_usecase.dart';
import '../../features/helper/features/service_areas/presentation/cubit/helper_service_areas_cubit.dart';

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
        () => AuthLocalDataSourceImpl(sl()),
  );

  // ============================================================
  // Features - Tourist User Booking
  // ============================================================

  // Cubits
  sl.registerFactory(
    () => SearchHelpersCubit(
      searchScheduled: sl(),
      searchInstant: sl(),
      mapCubit: sl(),
    ),
  );

  sl.registerFactory(
    () => HelpersCubit(
      getProfile: sl(),
      getAlternativesUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => BookingCubit(
      createScheduled: sl(),
      createInstant: sl(),
      getDetails: sl(),
      cancelUseCase: sl(),
      getStatusUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => MyBookingsCubit(
      getMyBookings: sl(),
    ),
  );

  sl.registerFactory(
    () => ChatCubit(
      getChatInfoUseCase: sl(),
      getMessagesUseCase: sl(),
      sendMessageUseCase: sl(),
      markAsReadUseCase: sl(),
    ),
  );

  // Data Sources (Service)
  sl.registerLazySingleton<UserBookingService>(
        () => UserBookingServiceImpl(dio: sl()),
  );

  sl.registerLazySingleton<ChatService>(
    () => ChatServiceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<UserBookingRepository>(
        () => UserBookingRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => SearchScheduledHelpersUseCase(sl()));
  sl.registerLazySingleton(() => SearchInstantHelpersUseCase(sl()));
  sl.registerLazySingleton(() => GetHelperProfileUseCase(sl()));
  sl.registerLazySingleton(() => CreateScheduledBookingUseCase(sl()));
  sl.registerLazySingleton(() => CreateInstantBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetMyBookingsUseCase(sl()));
  sl.registerLazySingleton(() => CancelBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetAlternativesUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingStatusUseCase(sl()));

  // Chat Use Cases
  sl.registerLazySingleton(() => GetChatInfoUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));

  // ============================================================
  // Features - Helper Auth
  // ============================================================

  // Cubit
  sl.registerFactory(
    () => HelperRatingsCubit(
      submitRatingUseCase: sl(),
      getStatusUseCase: sl(),
      getReceivedUseCase: sl(),
      getSummaryUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => HelperLocationCubit(
      sendLocationUseCase: sl(),
      getStatusUseCase: sl(),
      getEligibilityUseCase: sl(),
      connectUseCase: sl(),
      disconnectUseCase: sl(),
      connectionStateUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => HelperChatCubit(
      getChatInfoUseCase: sl(),
      getMessagesUseCase: sl(),
      sendMessageUseCase: sl(),
      markAsReadUseCase: sl(),
    ),
  );

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

  sl.registerFactory(
    () => HelperBookingsCubit(
      getRequestsUseCase: sl(),
      acceptBookingUseCase: sl(),
      getUpcomingBookingsUseCase: sl(),
      startTripUseCase: sl(),
      endTripUseCase: sl(),
      getActiveBookingUseCase: sl(),
      getHistoryUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetRequestsUseCase(sl()));
  sl.registerLazySingleton(() => AcceptBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetUpcomingBookingsUseCase(sl()));
  sl.registerLazySingleton(() => StartTripUseCase(sl()));
  sl.registerLazySingleton(() => EndTripUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetHistoryUseCase(sl()));

  sl.registerLazySingleton(() => GetHelperChatInfoUseCase(sl()));
  sl.registerLazySingleton(() => GetHelperMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendHelperMessageUseCase(sl()));
  sl.registerLazySingleton(() => MarkHelperMessagesReadUseCase(sl()));

  sl.registerLazySingleton(() => SendLocationUseCase(sl()));
  sl.registerLazySingleton(() => GetLocationStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetInstantEligibilityUseCase(sl()));
  sl.registerLazySingleton(() => ConnectLocationHubUseCase(sl()));
  sl.registerLazySingleton(() => DisconnectLocationHubUseCase(sl()));
  sl.registerLazySingleton(() => GetLocationConnectionStateUseCase(sl()));

  sl.registerLazySingleton(() => SubmitUserRatingUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingRatingStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetReceivedRatingsUseCase(sl()));
  sl.registerLazySingleton(() => GetRatingsSummaryUseCase(sl()));

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
  sl.registerLazySingleton<HelperBookingsRepository>(
    () => HelperBookingsRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<HelperChatRepository>(
    () => HelperChatRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<HelperLocationRepository>(
    () => HelperLocationRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<HelperRatingsRepository>(
    () => HelperRatingsRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<HelperAuthRepository>(
    () => HelperAuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<HelperBookingsService>(
    () => HelperBookingsServiceImpl(sl()),
  );

  sl.registerLazySingleton<HelperChatService>(
    () => HelperChatServiceImpl(sl()),
  );

  sl.registerLazySingleton<HelperLocationService>(
    () => HelperLocationServiceImpl(dio: sl(), authService: sl()),
  );

  sl.registerLazySingleton<HelperRatingsService>(
    () => HelperRatingsServiceImpl(sl()),
  );

  sl.registerLazySingleton<HelperAuthRemoteDataSource>(
    () => HelperAuthRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<HelperLocalDataSource>(
    () => HelperLocalDataSourceImpl(sl()),
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
  // Features - Helper Profile
  // ============================================================

  // Cubit — factory so each screen gets a fresh instance with its own state.
  sl.registerFactory(
    () => helper_profile.ProfileCubit(
      getProfileUseCase: sl(),
      getStatusUseCase: sl(),
      checkEligibilityUseCase: sl(),
      updateBasicInfoUseCase: sl(),
      uploadProfileImageUseCase: sl(),
      uploadSelfieUseCase: sl(),
      uploadDocumentsUseCase: sl(),
      addCarUseCase: sl(),
      deleteCarUseCase: sl(),
      addCertificateUseCase: sl(),
      deleteCertificateUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetProfileUseCase(sl()));
  sl.registerLazySingleton(() => GetStatusUseCase(sl()));
  sl.registerLazySingleton(() => CheckEligibilityUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBasicInfoUseCase(sl()));
  sl.registerLazySingleton(() => UploadProfileImageUseCase(sl()));
  sl.registerLazySingleton(() => UploadSelfieUseCase(sl()));
  sl.registerLazySingleton(() => UploadDocumentsUseCase(sl()));
  sl.registerLazySingleton(() => AddCarUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCarUseCase(sl()));
  sl.registerLazySingleton(() => AddCertificateUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCertificateUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl()),
  );

  // ============================================================
  // Features - Helper Service Areas
  // ============================================================

  // Cubit
  sl.registerFactory(
    () => HelperServiceAreasCubit(
      getServiceAreasUseCase: sl(),
      createServiceAreaUseCase: sl(),
      updateServiceAreaUseCase: sl(),
      deleteServiceAreaUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetServiceAreasUseCase(sl()));
  sl.registerLazySingleton(() => CreateServiceAreaUseCase(sl()));
  sl.registerLazySingleton(() => UpdateServiceAreaUseCase(sl()));
  sl.registerLazySingleton(() => DeleteServiceAreaUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ServiceAreasRepository>(
    () => ServiceAreasRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton<ServiceAreasRemoteDataSource>(
    () => ServiceAreasRemoteDataSourceImpl(sl()),
  );

  // ============================================================
  // Core - External Dependencies
  // ============================================================

  // 1️⃣  Dio — shared singleton used by ALL remote data sources.
  sl.registerLazySingleton(() => _createDio());

  // 2️⃣  HTTP Client — used by Maps API (non-Dio).
  sl.registerLazySingleton(() => http.Client());

  // 3️⃣  SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // 4️⃣  AuthService
  sl.registerLazySingleton(() => AuthService(sl()));
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

  // ── 401 / 403 global handler + token attachment ──────────────────────────
  dio.interceptors.add(AuthInterceptor());

  // ── Debug-only request/response logger ───────────────────────────────────
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('🌐 DIO: $obj'), // ignore: avoid_print
      ),
    );
  }

  return dio;
}