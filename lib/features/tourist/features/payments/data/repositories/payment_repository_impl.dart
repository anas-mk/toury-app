import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, PaymentEntity>> initiatePayment(String bookingId, String method) async {
    try {
      final payment = await remoteDataSource.initiatePayment(bookingId, method);
      return Right(payment);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentEntity>> getPayment(String paymentId) async {
    try {
      final payment = await remoteDataSource.getPayment(paymentId);
      return Right(payment);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PaymentEntity>> getLatestPayment(String bookingId) async {
    try {
      final payment = await remoteDataSource.getLatestPayment(bookingId);
      return Right(payment);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> mockPaymentComplete(String paymentId, String action) async {
    try {
      await remoteDataSource.mockPaymentComplete(paymentId, action);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
