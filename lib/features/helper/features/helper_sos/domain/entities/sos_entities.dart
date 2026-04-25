import 'package:equatable/equatable.dart';

class SosContact extends Equatable {
  final String name;
  final String phone;
  final String relation;

  const SosContact({required this.name, required this.phone, required this.relation});

  @override
  List<Object?> get props => [name, phone, relation];
}
