import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}
class ProfileInitial extends ProfileState {}

class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository repository;
  ProfileCubit(this.repository) : super(ProfileInitial());
}
