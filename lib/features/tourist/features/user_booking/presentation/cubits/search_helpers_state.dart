part of 'search_helpers_cubit.dart';

abstract class SearchHelpersState extends Equatable {
  const SearchHelpersState();

  @override
  List<Object?> get props => [];
}

class SearchHelpersInitial extends SearchHelpersState {}

class SearchHelpersLoading extends SearchHelpersState {}

class SearchHelpersLoaded extends SearchHelpersState {
  final List<HelperBookingEntity> helpers;

  const SearchHelpersLoaded(this.helpers);

  @override
  List<Object?> get props => [helpers];
}

class SearchHelpersError extends SearchHelpersState {
  final String message;

  const SearchHelpersError(this.message);

  @override
  List<Object?> get props => [message];
}
