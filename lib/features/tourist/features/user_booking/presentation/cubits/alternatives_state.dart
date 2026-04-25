part of 'alternatives_cubit.dart';

abstract class AlternativesState extends Equatable {
  const AlternativesState();

  @override
  List<Object?> get props => [];
}

class AlternativesInitial extends AlternativesState {}

class AlternativesLoading extends AlternativesState {}

class AlternativesLoaded extends AlternativesState {
  final List<HelperBookingEntity> helpers;

  const AlternativesLoaded(this.helpers);

  @override
  List<Object?> get props => [helpers];
}

class AlternativesError extends AlternativesState {
  final String message;

  const AlternativesError(this.message);

  @override
  List<Object?> get props => [message];
}
