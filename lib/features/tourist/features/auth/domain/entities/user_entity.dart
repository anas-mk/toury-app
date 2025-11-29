import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final dynamic id;
  final String email;
  final String userName;
  final String phoneNumber;
  final String gender;
  final DateTime? birthDate;
  final String country;
  final bool? isVerified;
  final String? type;
  final String? token;
  final String? profileImageUrl;

  const UserEntity({
    required this.id,
    required this.email,
    required this.userName,
    required this.phoneNumber,
    required this.gender,
    required this.birthDate,
    required this.country,
    this.isVerified,
    this.type,
    this.token,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    userName,
    phoneNumber,
    gender,
    birthDate,
    country,
    isVerified,
    type,
    token,
    profileImageUrl,
  ];
}