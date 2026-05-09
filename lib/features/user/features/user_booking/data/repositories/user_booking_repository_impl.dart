import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/booking_detail_entity.dart';
import '../../domain/entities/helper_booking_entity.dart';
import '../../domain/entities/search_params.dart';
import '../../domain/repositories/user_booking_repository.dart';
import '../datasources/user_booking_remote_data_source.dart';
import '../models/paged_response_model.dart';

class UserBookingRepositoryImpl implements UserBookingRepository {
  final UserBookingRemoteDataSource remoteDataSource;

  UserBookingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ({int availableCount, List<HelperBookingEntity> helpers})>> searchScheduledHelpers(ScheduledSearchParams params) async {
    try {
      final result = await remoteDataSource.searchScheduledHelpers(params);
      return Right((availableCount: result.availableCount, helpers: result.helpers));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<HelperBookingEntity>>> searchInstantHelpers(InstantSearchParams params) async {
    try {
      final result = await remoteDataSource.searchInstantHelpers(params);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HelperBookingEntity>> getHelperProfile(String helperId) async {
    try {
      final result = await remoteDataSource.getHelperProfile(helperId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingDetailEntity>> createScheduledBooking(Map<String, dynamic> bookingData) async {
    try {
      final result = await remoteDataSource.createScheduledBooking(bookingData);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingDetailEntity>> createInstantBooking(Map<String, dynamic> bookingData) async {
    try {
      final result = await remoteDataSource.createInstantBooking(bookingData);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingDetailEntity>> getBookingDetails(String bookingId) async {
    try {
      final result = await remoteDataSource.getBookingDetails(bookingId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResponse<BookingDetailEntity>>> getMyBookings({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? type,
  }) async {
    try {
      final result = await remoteDataSource.getMyBookings(
        page: page,
        pageSize: pageSize,
        status: status,
        type: type,
      );
      return Right(result as PagedResponse<BookingDetailEntity>);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking(String bookingId, String reason) async {
    try {
      await remoteDataSource.cancelBooking(bookingId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<HelperBookingEntity>>> getAlternatives(String bookingId) async {
    try {
      final result = await remoteDataSource.getAlternatives(bookingId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getBookingStatus(String bookingId) async {
    try {
      final result = await remoteDataSource.getBookingStatus(bookingId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
