import 'package:equatable/equatable.dart';

import '../../domain/entities/location.dart';

/// Search Location State - حالات البحث عن الأماكن
abstract class SearchLocationState extends Equatable {
  const SearchLocationState();

  @override
  List<Object?> get props => [];
}

/// الحالة الأولية
class SearchLocationInitial extends SearchLocationState {}

/// Loading - جاري البحث
class SearchLocationLoading extends SearchLocationState {}

/// تم تحميل نتائج البحث
class SearchLocationLoaded extends SearchLocationState {
  final List<Location> locations;

  const SearchLocationLoaded(this.locations);

  @override
  List<Object?> get props => [locations];
}

/// Empty - لا توجد نتائج
class SearchLocationEmpty extends SearchLocationState {
  final String query;

  const SearchLocationEmpty(this.query);

  @override
  List<Object?> get props => [query];
}

/// Error - حدث خطأ
class SearchLocationError extends SearchLocationState {
  final String message;

  const SearchLocationError(this.message);

  @override
  List<Object?> get props => [message];
}