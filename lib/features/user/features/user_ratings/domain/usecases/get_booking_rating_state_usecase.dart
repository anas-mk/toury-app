import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../repositories/rating_repository.dart';

class GetBookingRatingStateUseCase implements UseCase<Map<String, dynamic>, String> {
  final RatingRepository repository;

  GetBookingRatingStateUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(String bookingId) async {
    return await repository.getBookingRatingState(bookingId);
  }
}
