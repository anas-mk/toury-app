import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../../../../core/usecase/usecase.dart';
import '../entities/location.dart';
import '../repositories/location_repository.dart';

/// Use Case - البحث عن مواقع
class SearchLocations implements UseCase<List<Location>, SearchParams> {
  final LocationRepository repository;

  SearchLocations(this.repository);

  @override
  Future<Either<Failure, List<Location>>> call(SearchParams params) async {
    return await repository.searchLocations(params.query);
  }
}

class SearchParams extends Equatable {
  final String query;

  const SearchParams({required this.query});

  @override
  List<Object?> get props => [query];
}