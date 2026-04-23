import 'package:dartz/dartz.dart';
import 'package:toury/features/tourist/features/user_booking/domain/entities/alternative_helper_entity.dart';
import 'package:toury/features/tourist/features/user_booking/domain/entities/booking_status_entity.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/network/api_response.dart';
import '../../data/datasources/user_booking_service.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/helper_entity.dart';
import '../../domain/repositories/user_booking_repository.dart';


class UserBookingRepositoryImpl implements UserBookingRepository {
  final UserBookingService remoteDataSource;

  UserBookingRepositoryImpl({required this.remoteDataSource});

  Failure _handleException(dynamic exception) {
    if (exception is TimeoutException) {
      return const TimeoutFailure();
    } else if (exception is UnauthorizedException) {
      return const UnauthorizedFailure();
    } else if (exception is ForbiddenException) {
      return const ForbiddenFailure();
    } else if (exception is ServerException) {
      return ServerFailure(exception.message);
    }
    return ServerFailure(exception.toString());
  }

  @override
  Future<Either<Failure, List<HelperEntity>>> searchScheduledHelpers({
    required String destination,
    required DateTime date,
    required String language,
    required bool needArabic,
    required int durationInMinutes,
  }) async {
    try {
      final result = await remoteDataSource.searchScheduledHelpers(
        destination: destination,
        date: date,
        language: language,
        needArabic: needArabic,
        durationInMinutes: durationInMinutes,
      );
      return Right(result);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<HelperEntity>>> searchInstantHelpers({
    required String pickupLocation,
    required double lat,
    required double lng,
  }) async {
    try {
      final result = await remoteDataSource.searchInstantHelpers(
        pickupLocation: pickupLocation,
        lat: lat,
        lng: lng,
      );
      return Right(result);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, HelperEntity>> getHelperProfile(String helperId) async {
    try {
      final result = await remoteDataSource.getHelperProfile(helperId);
      return Right(result);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> createScheduledBooking() async {
    try {
      final result = await remoteDataSource.createScheduledBooking();
      return Right(result);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> createInstantBooking() async {
    try {
      final result = await remoteDataSource.createInstantBooking();
      return Right(result);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingDetails(String bookingId) async {
    try {
      final result = await remoteDataSource.getBookingDetails(bookingId);
      return Right(result);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, PaginatedResponse<BookingEntity>>> getMyBookings({
    String? status,
    String? type,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final result = await remoteDataSource.getMyBookings(
        status: status,
        type: type,
        page: page,
        pageSize: pageSize,
      );
      
      // Map PaginatedResponse<BookingModel> to PaginatedResponse<BookingEntity>
      final entityResponse = PaginatedResponse<BookingEntity>(
        items: result.items, // BookingModel is a BookingEntity
        totalCount: result.totalCount,
        page: result.page,
        pageSize: result.pageSize,
      );
      
      return Right(entityResponse);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(String bookingId, String reason) async {
    try {
      await remoteDataSource.cancelBooking(bookingId, reason);
      return const Right(null);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<AlternativeHelperEntity>>> getAlternatives(String bookingId) async {
    try {
      final result = await remoteDataSource.getAlternatives(bookingId);
      return Right(result);
    } catch (e) {
      return Left(_handleException(e));
    }
  }

  @override
  Future<Either<Failure, BookingStatusEntity>> getBookingStatus(String bookingId) async {
    try {
      final result = await remoteDataSource.getBookingStatus(bookingId);
      return Right(result);
    } catch (e) {
      return Left(_handleException(e));
    }
  }
}
