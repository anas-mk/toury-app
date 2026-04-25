import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/exceptions.dart';
import '../../../../../../core/errors/failures.dart';
import '../../domain/entities/invoice_entity.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../datasources/invoice_remote_datasource.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;

  InvoiceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getInvoices({int page = 1, int pageSize = 20}) async {
    try {
      final invoices = await remoteDataSource.getInvoices(page: page, pageSize: pageSize);
      return Right(invoices);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InvoiceEntity>> getInvoiceDetail(String invoiceId) async {
    try {
      final invoice = await remoteDataSource.getInvoiceDetail(invoiceId);
      return Right(invoice);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InvoiceEntity>> getInvoiceByBooking(String bookingId) async {
    try {
      final invoice = await remoteDataSource.getInvoiceByBooking(bookingId);
      return Right(invoice);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getInvoiceHtml(String invoiceId) async {
    try {
      final html = await remoteDataSource.getInvoiceHtml(invoiceId);
      return Right(html);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
