import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/alternatives_response.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/booking_status_response.dart';
import '../../domain/entities/create_instant_booking_request.dart';
import '../../domain/entities/helper_booking_profile.dart';
import '../../domain/entities/helper_search_result.dart';
import '../../domain/entities/instant_search_request.dart';
import '../../domain/repositories/instant_booking_repository.dart';
import '../datasources/instant_booking_remote_data_source.dart';

class InstantBookingRepositoryImpl implements InstantBookingRepository {
  final InstantBookingRemoteDataSource remote;
  const InstantBookingRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<HelperSearchResult>>> searchInstantHelpers(
    InstantSearchRequest request,
  ) =>
      _guard(() async => await remote.searchInstantHelpers(request));

  @override
  Future<Either<Failure, HelperBookingProfile>> getHelperBookingProfile(
    String helperId,
  ) =>
      _guard(() async => await remote.getHelperBookingProfile(helperId));

  @override
  Future<Either<Failure, BookingDetail>> createInstantBooking(
    CreateInstantBookingRequest request,
  ) =>
      _guard(() async => await remote.createInstantBooking(request));

  @override
  Future<Either<Failure, BookingStatusResponse>> getBookingStatus(
    String bookingId,
  ) =>
      _guard(() async => await remote.getBookingStatus(bookingId));

  @override
  Future<Either<Failure, BookingDetail>> getBookingDetail(String bookingId) =>
      _guard(() async => await remote.getBookingDetail(bookingId));

  @override
  Future<Either<Failure, AlternativesResponse>> getAlternatives(
    String bookingId,
  ) =>
      _guard(() async => await remote.getAlternatives(bookingId));

  @override
  Future<Either<Failure, BookingDetail>> cancelBooking(
    String bookingId,
    String reason,
  ) =>
      _guard(() async => await remote.cancelBooking(bookingId, reason));

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      final value = await action();
      return Right(value);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ForbiddenFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      return Left(NetworkFailure(e.message ?? 'Network error'));
    } on FormatException catch (e) {
      return Left(ServerFailure('Invalid server response: ${e.message}'));
    } catch (_) {
      return const Left(GenericFailure());
    }
  }
}
