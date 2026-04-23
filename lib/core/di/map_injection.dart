import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
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

import '../../features/tourist/features/user_booking/data/datasources/user_booking_service.dart';
import '../../features/tourist/features/user_booking/data/datasources/user_booking_service_impl.dart';
import '../../features/tourist/features/user_booking/data/repositories/user_booking_repository_impl.dart';
import '../../features/tourist/features/user_booking/domain/repositories/user_booking_repository.dart';

final sl = GetIt.instance;

/// تسجيل جميع الـ Dependencies
Future<void> initMapDependencies() async {
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
  // Features - Tourist User Booking
  // ============================================================
  sl.registerLazySingleton<UserBookingRepository>(
        () => UserBookingRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<UserBookingService>(
        () => UserBookingServiceImpl(dio: sl()),
  );

  // ============================================================
  // External
  // ============================================================
  sl.registerLazySingleton(() => http.Client());
}