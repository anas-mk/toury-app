import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/auth_interceptor.dart';
import '../../core/services/auth_service.dart';
import '../../features/helper/features/language_interview/presentation/cubit/exams_cubit.dart';

// ============================================================
// Tourist Auth Feature Imports
// ============================================================
import '../../features/tourist/features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/tourist/features/auth/domain/repositories/auth_repository.dart';
import '../../features/tourist/features/auth/domain/usecases/get_cached_user_usecase.dart';
import '../../features/tourist/features/auth/domain/usecases/resend_verification_code_usecase.dart';
import '../../features/tourist/features/auth/domain/usecases/verify_code_usecase.dart';
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
import '../../features/tourist/features/user_booking/data/datasources/user_booking_remote_data_source.dart';
import '../../features/tourist/features/user_booking/data/repositories/user_booking_repository_impl.dart';
import '../../features/tourist/features/user_booking/domain/repositories/user_booking_repository.dart';
import '../../features/tourist/features/user_booking/domain/usecases/booking_actions_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/create_booking_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/get_booking_details_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/get_helper_profile_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/get_my_bookings_usecase.dart';
import '../../features/tourist/features/user_booking/domain/usecases/search_helpers_usecase.dart';
import '../../features/tourist/features/user_booking/presentation/cubits/search_helpers_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubits/instant_booking_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubits/scheduled_booking_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubits/booking_details_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubits/booking_status_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubits/my_bookings_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubits/cancel_booking_cubit.dart';
import '../../features/tourist/features/user_booking/presentation/cubits/alternatives_cubit.dart';

// ============================================================
// Tourist Payments Feature Imports
// ============================================================
import '../../features/tourist/features/payments/data/datasources/payment_remote_datasource.dart';
import '../../features/tourist/features/payments/data/repositories/payment_repository_impl.dart';
import '../../features/tourist/features/payments/domain/repositories/payment_repository.dart';
import '../../features/tourist/features/payments/domain/usecases/initiate_payment_usecase.dart';
import '../../features/tourist/features/payments/domain/usecases/get_payment_usecase.dart';
import '../../features/tourist/features/payments/domain/usecases/get_latest_payment_usecase.dart';
import '../../features/tourist/features/payments/domain/usecases/mock_payment_complete_usecase.dart';
import '../../features/tourist/features/payments/presentation/cubit/payment_cubit.dart';
import '../../features/tourist/features/user_invoices/data/datasources/invoice_remote_datasource.dart';
import '../../features/tourist/features/user_invoices/data/repositories/invoice_repository_impl.dart';
import '../../features/tourist/features/user_invoices/domain/repositories/invoice_repository.dart';
import '../../features/tourist/features/user_invoices/domain/usecases/get_invoices_usecase.dart' as user_inv;
import '../../features/tourist/features/user_invoices/domain/usecases/get_invoice_detail_usecase.dart' as user_inv;
import '../../features/tourist/features/user_invoices/domain/usecases/get_invoice_by_booking_usecase.dart' as user_inv;
import '../../features/tourist/features/user_invoices/domain/usecases/get_invoice_html_usecase.dart' as user_inv;
import '../../features/tourist/features/user_invoices/presentation/cubit/user_invoices_cubit.dart';
import '../../features/tourist/features/user_ratings/data/datasources/rating_remote_datasource.dart';
import '../../features/tourist/features/user_ratings/data/repositories/rating_repository_impl.dart';
import '../../features/tourist/features/user_ratings/domain/repositories/rating_repository.dart';
import '../../features/tourist/features/user_ratings/domain/usecases/get_booking_rating_state_usecase.dart' as user_rat;
import '../../features/tourist/features/user_ratings/domain/usecases/get_helper_rating_summary_usecase.dart' as user_rat;
import '../../features/tourist/features/user_ratings/domain/usecases/get_helper_ratings_usecase.dart' as user_rat;
import '../../features/tourist/features/user_ratings/domain/usecases/get_user_rating_summary_usecase.dart' as user_rat;
import '../../features/tourist/features/user_ratings/domain/usecases/rate_helper_usecase.dart' as user_rat;
import '../../features/tourist/features/user_chat/presentation/cubit/user_chat_cubit.dart';
import '../../features/tourist/features/user_booking_tracking/data/datasources/tracking_remote_datasource.dart';
import '../../features/tourist/features/user_booking_tracking/data/repositories/tracking_repository_impl.dart';
import '../../features/tourist/features/user_booking_tracking/domain/repositories/tracking_repository.dart';
import '../../features/tourist/features/user_booking_tracking/domain/usecases/get_latest_location_usecase.dart';
import '../../features/tourist/features/user_booking_tracking/domain/usecases/get_tracking_history_usecase.dart';
import '../../features/tourist/features/user_booking_tracking/presentation/cubit/tracking_cubit.dart';
import '../../core/services/signalr/booking_tracking_hub_service.dart';
import '../../features/tourist/features/user_ratings/presentation/cubit/user_ratings_cubit.dart';
import '../../features/tourist/features/user_chat/data/datasources/user_chat_remote_datasource.dart';
import '../../features/tourist/features/user_chat/data/repositories/user_chat_repository_impl.dart';
import '../../features/tourist/features/user_chat/domain/repositories/user_chat_repository.dart';
import '../../features/tourist/features/user_chat/domain/usecases/get_chat_conversation_usecase.dart';
import '../../features/tourist/features/user_chat/domain/usecases/get_chat_messages_usecase.dart';
import '../../features/tourist/features/user_chat/domain/usecases/listen_to_messages_usecase.dart';
import '../../features/tourist/features/user_chat/domain/usecases/mark_chat_as_read_usecase.dart';
import '../../features/tourist/features/user_chat/domain/usecases/send_chat_message_usecase.dart';

// ============================================================
// Helper Bookings Feature Imports
// ============================================================
import '../../features/helper/features/helper_bookings/data/datasources/helper_bookings_remote_data_source.dart';
import '../../features/helper/features/helper_bookings/data/repositories/helper_bookings_repository_impl.dart';
import '../../features/helper/features/helper_bookings/domain/repositories/helper_bookings_repository.dart';
import '../../features/helper/features/helper_bookings/domain/usecases/helper_bookings_usecases.dart';
import '../../features/helper/features/helper_bookings/presentation/cubit/helper_bookings_cubits.dart';

// ============================================================
// Helper Location Feature Imports
// ============================================================
import '../../features/helper/features/helper_location/data/datasources/helper_location_remote_data_source.dart';
import '../../features/helper/features/helper_location/data/repositories/helper_location_repository_impl.dart';
import '../../features/helper/features/helper_location/data/services/helper_location_signalr_service.dart';
import '../../features/helper/features/helper_location/data/services/helper_location_tracker.dart';
import '../../features/helper/features/helper_location/domain/repositories/helper_location_repository.dart';
import '../../features/helper/features/helper_location/domain/usecases/helper_location_usecases.dart';
import '../../features/helper/features/helper_location/presentation/cubit/helper_location_cubit.dart';
import '../../features/helper/features/helper_location/presentation/cubit/location_status_cubits.dart';

// ============================================================
// Helper Service Areas Feature Imports
// ============================================================
import '../../features/helper/features/helper_service_areas/data/datasources/service_areas_remote_data_source.dart';
import '../../features/helper/features/helper_service_areas/data/repositories/service_areas_repository_impl.dart';
import '../../features/helper/features/helper_service_areas/domain/repositories/service_areas_repository.dart';
import '../../features/helper/features/helper_service_areas/domain/usecases/service_area_usecases.dart';
import '../../features/helper/features/helper_service_areas/presentation/cubit/service_areas_cubit.dart';

import '../../features/helper/features/helper_invoices/data/datasources/helper_invoices_remote_data_source.dart';
import '../../features/helper/features/helper_invoices/data/repositories/helper_invoices_repository_impl.dart';
import '../../features/helper/features/helper_invoices/domain/repositories/helper_invoices_repository.dart';
import '../../features/helper/features/helper_invoices/domain/usecases/invoice_usecases.dart';
import '../../features/helper/features/helper_invoices/presentation/cubit/helper_invoices_cubit.dart';
import '../../features/helper/features/helper_ratings/data/datasources/helper_ratings_remote_data_source.dart';
import '../../features/helper/features/helper_ratings/data/repositories/helper_ratings_repository_impl.dart';
import '../../features/helper/features/helper_ratings/domain/repositories/helper_ratings_repository.dart';
import '../../features/helper/features/helper_ratings/domain/usecases/helper_rating_usecases.dart';
import '../../features/helper/features/helper_ratings/presentation/cubit/helper_ratings_cubits.dart';
import '../../features/helper/features/helper_chat/data/datasources/helper_chat_remote_data_source.dart';
import '../../features/helper/features/helper_chat/data/repositories/helper_chat_repository_impl.dart';
import '../../features/helper/features/helper_chat/data/services/helper_chat_signalr_service.dart';
import '../../features/helper/features/helper_chat/domain/repositories/helper_chat_repository.dart';
import '../../features/helper/features/helper_chat/domain/usecases/helper_chat_usecases.dart';
import '../../features/helper/features/helper_chat/presentation/cubit/helper_chat_cubit.dart';

// ============================================================
// Helper Booking Tracking Feature Imports
// ============================================================
import '../../features/helper/features/helper_booking_tracking/data/datasources/tracking_remote_datasource.dart';
import '../../features/helper/features/helper_booking_tracking/data/repositories/tracking_repository_impl.dart';
import '../../features/helper/features/helper_booking_tracking/domain/repositories/tracking_repository.dart';
import '../../features/helper/features/helper_booking_tracking/domain/usecases/get_latest_location_usecase.dart' as helper_track;
import '../../features/helper/features/helper_booking_tracking/domain/usecases/get_tracking_history_usecase.dart' as helper_track;
import '../../features/helper/features/helper_booking_tracking/presentation/cubit/helper_tracking_cubit.dart';

import '../../features/helper/features/helper_reports/data/repositories/helper_reports_repository_impl.dart';
import '../../features/helper/features/helper_reports/data/services/helper_reports_signalr_service.dart';
import '../../features/helper/features/helper_reports/domain/repositories/helper_reports_repository.dart';
import '../../features/helper/features/helper_reports/presentation/cubit/helper_reports_cubit.dart';
import '../../features/helper/features/helper_sos/data/services/helper_sos_service.dart';
import '../../features/helper/features/helper_sos/presentation/cubit/helper_sos_cubit.dart';
import '../config/api_config.dart';

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
    () => HelperLocalDataSourceImpl(sl()),
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
  // Features - User Booking
  // ============================================================

  // Cubits
  sl.registerFactory(() => SearchHelpersCubit(
    searchScheduledHelpersUseCase: sl(),
    searchInstantHelpersUseCase: sl(),
  ));
  sl.registerFactory(() => InstantBookingCubit(
    createInstantBookingUseCase: sl(),
    getBookingStatusUseCase: sl(),
  ));
  sl.registerFactory(() => ScheduledBookingCubit(
    createScheduledBookingUseCase: sl(),
  ));
  sl.registerFactory(() => BookingDetailsCubit(
    getBookingDetailsUseCase: sl(),
    getHelperProfileUseCase: sl(),
  ));
  sl.registerFactory(() => BookingStatusCubit(
    getBookingStatusUseCase: sl(),
    getMyBookingsUseCase: sl(),
    getBookingDetailsUseCase: sl(),
    hubService: sl(),
  ));
  sl.registerFactory(() => MyBookingsCubit(
    getMyBookingsUseCase: sl(),
  ));
  sl.registerFactory(() => CancelBookingCubit(
    cancelBookingUseCase: sl(),
  ));
  sl.registerFactory(() => AlternativesCubit(
    getAlternativesUseCase: sl(),
  ));

  // Use Cases
  sl.registerLazySingleton(() => SearchScheduledHelpersUseCase(sl()));
  sl.registerLazySingleton(() => SearchInstantHelpersUseCase(sl()));
  sl.registerLazySingleton(() => GetHelperProfileUseCase(sl()));
  sl.registerLazySingleton(() => CreateScheduledBookingUseCase(sl()));
  sl.registerLazySingleton(() => CreateInstantBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetMyBookingsUseCase(sl()));
  sl.registerLazySingleton(() => CancelBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetAlternativesUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingStatusUseCase(sl()));

  // Repository
  sl.registerLazySingleton<UserBookingRepository>(
    () => UserBookingRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton<UserBookingRemoteDataSource>(
    () => UserBookingRemoteDataSourceImpl(sl()),
  );

  // ============================================================
  // Features - Helper Bookings
  // ============================================================

  // Cubits — factory so each screen gets a fresh instance
  sl.registerFactory(() => HelperDashboardCubit(sl(), sl()));
  sl.registerFactory(() => HelperAvailabilityCubit(sl()));
  sl.registerFactory(() => IncomingRequestsCubit(sl()));
  sl.registerFactory(() => RequestDetailsCubit(sl()));
  sl.registerFactory(() => AcceptBookingCubit(sl()));
  sl.registerFactory(() => DeclineBookingCubit(sl()));
  sl.registerFactory(() => UpcomingBookingsCubit(sl()));
  sl.registerFactory(() => ActiveBookingCubit(sl(), sl()));
  sl.registerFactory(() => StartTripCubit(sl()));
  sl.registerFactory(() => EndTripCubit(sl()));
  sl.registerFactory(() => HelperHistoryCubit(sl()));
  sl.registerFactory(() => EarningsCubit(sl()));
  sl.registerFactory(() => HelperBookingDetailsCubit(sl()));

  // Use Cases
  sl.registerLazySingleton(() => GetHelperDashboardUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAvailabilityUseCase(sl()));
  sl.registerLazySingleton(() => GetIncomingRequestsUseCase(sl()));
  sl.registerLazySingleton(() => GetRequestDetailsUseCase(sl()));
  sl.registerLazySingleton(() => AcceptBookingUseCase(sl()));
  sl.registerLazySingleton(() => DeclineBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetUpcomingBookingsUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveBookingUseCase(sl()));
  sl.registerLazySingleton(() => StartTripUseCase(sl()));
  sl.registerLazySingleton(() => EndTripUseCase(sl()));
  sl.registerLazySingleton(() => GetHelperHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetEarningsUseCase(sl()));
  sl.registerLazySingleton(() => GetHelperBookingDetailsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HelperBookingsRepository>(
    () => HelperBookingsRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton<HelperBookingsRemoteDataSource>(
    () => HelperBookingsRemoteDataSourceImpl(sl()),
  );

  // ============================================================
  // Features - Helper Location
  // ============================================================

  // Cubits
  sl.registerLazySingleton(() => HelperLocationCubit(
    tracker: sl(),
    connectUseCase: sl(),
    disconnectUseCase: sl(),
    streamUseCase: sl(),
    updateUseCase: sl(),
    signalRStateStream: sl<HelperLocationRepository>().signalRStateStream.cast<SignalRConnectionState>(),
  ));
  sl.registerLazySingleton(() => LocationStatusCubit(getStatusUseCase: sl()));
  sl.registerLazySingleton(() => EligibilityCubit(getEligibilityUseCase: sl()));

  // Use Cases
  sl.registerLazySingleton(() => UpdateLocationUseCase(sl()));
  sl.registerLazySingleton(() => GetLocationStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetInstantEligibilityUseCase(sl()));
  sl.registerLazySingleton(() => StreamLocationUseCase(sl()));
  sl.registerLazySingleton(() => ConnectSignalRUseCase(sl()));
  sl.registerLazySingleton(() => DisconnectSignalRUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HelperLocationRepository>(
    () => HelperLocationRepositoryImpl(
      remoteDataSource: sl(),
      signalRService: sl(),
    ),
  );

  // Services
  sl.registerLazySingleton(() => HelperLocationSignalRService());
  sl.registerLazySingleton(() => HelperLocationTracker());

  // Data Source
  sl.registerLazySingleton<HelperLocationRemoteDataSource>(
    () => HelperLocationRemoteDataSourceImpl(sl()),
  );

  // ============================================================
  // Features - Helper Service Areas
  // ============================================================

  // Cubits
  sl.registerFactory(() => ServiceAreasCubit(
    getAreasUseCase: sl(),
    createAreaUseCase: sl(),
    updateAreaUseCase: sl(),
    deleteAreaUseCase: sl(),
  ));

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
  // Features - Helper Booking Tracking
  // ============================================================

  // Data sources
  sl.registerLazySingleton<HelperTrackingRemoteDataSource>(
    () => HelperTrackingRemoteDataSourceImpl(dio: sl()),
  );

  // Repositories
  sl.registerLazySingleton<HelperTrackingRepository>(
    () => HelperTrackingRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => helper_track.GetLatestLocationUseCase(sl()));
  sl.registerLazySingleton(() => helper_track.GetTrackingHistoryUseCase(sl()));

  // Cubits
  sl.registerFactory(
    () => HelperTrackingCubit(
      getLatestLocationUseCase: sl<helper_track.GetLatestLocationUseCase>(),
      getTrackingHistoryUseCase: sl<helper_track.GetTrackingHistoryUseCase>(),
      hubService: sl(),
      authService: sl(),
    ),
  );

  // ============================================================
  // Features - Helper Invoices
  // ============================================================

  // Cubit (factory — each page gets its own isolated state)
  sl.registerFactory(() => HelperInvoicesCubit(
    getInvoicesUseCase: sl(),
    getDetailUseCase: sl(),
    getByBookingUseCase: sl(),
    getSummaryUseCase: sl(),
    getHtmlUseCase: sl(),
  ));

  // Use Cases
  sl.registerLazySingleton(() => GetInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoiceDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoiceByBookingUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoiceSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoiceHtmlUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HelperInvoicesRepository>(
    () => HelperInvoicesRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton<HelperInvoicesRemoteDataSource>(
    () => HelperInvoicesRemoteDataSourceImpl(sl()),
  );

  // ============================================================
  // Features - Helper Ratings
  // ============================================================

  // Cubits
  sl.registerFactory(() => HelperRatingsCubit(
    getReceivedRatingsUseCase: sl(),
    getRatingsSummaryUseCase: sl(),
  ));
  sl.registerFactory(() => RateUserCubit(rateUserUseCase: sl()));
  sl.registerFactory(() => BookingRatingStateCubit(getBookingRatingStateUseCase: sl()));

  // Use Cases
  sl.registerLazySingleton(() => RateUserUseCase(sl()));
  sl.registerLazySingleton(() => GetBookingRatingStateUseCase(sl()));
  sl.registerLazySingleton(() => GetReceivedRatingsUseCase(sl()));
  sl.registerLazySingleton(() => GetRatingsSummaryUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HelperRatingsRepository>(
    () => HelperRatingsRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Source
  sl.registerLazySingleton<HelperRatingsRemoteDataSource>(
    () => HelperRatingsRemoteDataSourceImpl(sl()),
  );

  // ============================================================
  // Features - Helper Chat
  // ============================================================

  // Cubits
  sl.registerFactory(() => HelperChatCubit(
    getConversationUseCase: sl(),
    getMessagesUseCase: sl(),
    sendMessageUseCase: sl(),
    markReadUseCase: sl(),
    connectChatUseCase: sl(),
    signalRService: sl(),
  ));

  // Use Cases
  sl.registerLazySingleton(() => GetConversationUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => MarkReadUseCase(sl()));
  sl.registerLazySingleton(() => ConnectChatUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HelperChatRepository>(
    () => HelperChatRepositoryImpl(
      remoteDataSource: sl(),
      signalRService: sl(),
    ),
  );

  // Services
  sl.registerLazySingleton(() => HelperChatSignalRService());

  // Data Source
  sl.registerLazySingleton<HelperChatRemoteDataSource>(
    () => HelperChatRemoteDataSourceImpl(sl()),
  );

  // ============================================================
  // Features - Helper Reports
  // ============================================================

  // Cubits
  sl.registerFactory(() => HelperReportsCubit(
    getCachedReportsUseCase: sl(),
    syncReportsUseCase: sl(),
    resolutionStream: sl<HelperReportsRepository>().resolutionEvents,
  ));

  // Use Cases
  sl.registerLazySingleton(() => GetCachedReportsUseCase(sl()));
  sl.registerLazySingleton(() => SyncReportsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HelperReportsRepository>(
    () => HelperReportsRepositoryImpl(signalRService: sl()),
  );

  // Services
  sl.registerLazySingleton(() => HelperReportsSignalRService(null)); // Placeholder connection

  // ============================================================
  // Features - Helper SOS
  // ============================================================

  // Cubits
  sl.registerFactory(() => HelperSosCubit(sosService: sl()));

  // Services
  sl.registerLazySingleton(() => HelperSosService());

  // ============================================================
  // Tourist Payments Feature
  // ============================================================
  
  // Data sources
  sl.registerLazySingleton<PaymentRemoteDataSource>(
    () => PaymentRemoteDataSourceImpl(dio: sl()),
  );

  // Repositories
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => InitiatePaymentUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentUseCase(sl()));
  sl.registerLazySingleton(() => GetLatestPaymentUseCase(sl()));
  sl.registerLazySingleton(() => MockPaymentCompleteUseCase(sl()));

  // Cubits
  sl.registerFactory(
    () => PaymentCubit(
      initiatePaymentUseCase: sl(),
      getPaymentUseCase: sl(),
      getLatestPaymentUseCase: sl(),
      mockPaymentCompleteUseCase: sl(),
    ),
  );

  // ============================================================
  // User Invoices Feature
  // ============================================================

  // Data sources
  sl.registerLazySingleton<InvoiceRemoteDataSource>(
    () => InvoiceRemoteDataSourceImpl(dio: sl()),
  );

  // Repositories
  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => user_inv.GetInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => user_inv.GetInvoiceDetailUseCase(sl()));
  sl.registerLazySingleton(() => user_inv.GetInvoiceByBookingUseCase(sl()));
  sl.registerLazySingleton(() => user_inv.GetInvoiceHtmlUseCase(sl()));

  // Cubits
  sl.registerFactory(
    () => UserInvoicesCubit(
      getInvoicesUseCase: sl<user_inv.GetInvoicesUseCase>(),
      getInvoiceDetailUseCase: sl<user_inv.GetInvoiceDetailUseCase>(),
      getInvoiceByBookingUseCase: sl<user_inv.GetInvoiceByBookingUseCase>(),
      getInvoiceHtmlUseCase: sl<user_inv.GetInvoiceHtmlUseCase>(),
    ),
  );

  // ============================================================
  // User Ratings Feature
  // ============================================================

  // Data sources
  sl.registerLazySingleton<RatingRemoteDataSource>(
    () => RatingRemoteDataSourceImpl(dio: sl()),
  );

  // Repositories
  sl.registerLazySingleton<RatingRepository>(
    () => RatingRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => user_rat.RateHelperUseCase(sl()));
  sl.registerLazySingleton(() => user_rat.GetBookingRatingStateUseCase(sl()));
  sl.registerLazySingleton(() => user_rat.GetHelperRatingsUseCase(sl()));
  sl.registerLazySingleton(() => user_rat.GetHelperRatingSummaryUseCase(sl()));
  sl.registerLazySingleton(() => user_rat.GetUserRatingSummaryUseCase(sl()));

  // Cubits
  sl.registerFactory(
    () => UserRatingsCubit(
      rateHelperUseCase: sl<user_rat.RateHelperUseCase>(),
      getBookingRatingStateUseCase: sl<user_rat.GetBookingRatingStateUseCase>(),
      getHelperRatingsUseCase: sl<user_rat.GetHelperRatingsUseCase>(),
      getHelperRatingSummaryUseCase: sl<user_rat.GetHelperRatingSummaryUseCase>(),
      getUserRatingSummaryUseCase: sl<user_rat.GetUserRatingSummaryUseCase>(),
    ),
  );

  // ============================================================
  // User Chat Feature
  // ============================================================

  // Data sources
  sl.registerLazySingleton<UserChatRemoteDataSource>(
    () => UserChatRemoteDataSourceImpl(dio: sl()),
  );

  // Repositories
  sl.registerLazySingleton<UserChatRepository>(
    () => UserChatRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetChatConversationUseCase(sl()));
  sl.registerLazySingleton(() => GetChatMessagesUseCase(sl()));
  sl.registerLazySingleton(() => SendChatMessageUseCase(sl()));
  sl.registerLazySingleton(() => MarkChatAsReadUseCase(sl()));
  sl.registerLazySingleton(() => ListenToMessagesUseCase(sl()));

  // Cubits
  sl.registerFactory(
    () => UserChatCubit(
      getChatConversationUseCase: sl(),
      getChatMessagesUseCase: sl(),
      sendChatMessageUseCase: sl(),
      markChatAsReadUseCase: sl(),
      listenToMessagesUseCase: sl(),
    ),
  );

  // ============================================================
  // User Booking Tracking Feature
  // ============================================================

  // SignalR Service
  sl.registerLazySingleton(() => BookingTrackingHubService());

  // Data sources
  sl.registerLazySingleton<TrackingRemoteDataSource>(
    () => TrackingRemoteDataSourceImpl(dio: sl()),
  );

  // Repositories
  sl.registerLazySingleton<TrackingRepository>(
    () => TrackingRepositoryImpl(
      remoteDataSource: sl(),
      hubService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetLatestLocationUseCase(sl()));
  sl.registerLazySingleton(() => GetTrackingHistoryUseCase(sl()));

  // Cubits
  sl.registerFactory(
    () => TrackingCubit(
      getLatestLocationUseCase: sl(),
      getTrackingHistoryUseCase: sl(),
      repository: sl(),
      hubService: sl(),
      authService: sl(),
    ),
  );

  // ============================================================
  // Core - External Dependencies
  // ============================================================

  // 1️⃣  Dio — shared singleton used by ALL remote data sources.
  sl.registerLazySingleton(() => _createDio());


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
