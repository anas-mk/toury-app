import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.userName,
    required super.phoneNumber,
    required super.gender,
    required super.birthDate,
    required super.country,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      userName: json['userName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      gender: json['gender'] ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.tryParse(json['birthDate'])
          : null,
      country: json['country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'userName': userName,
    'phoneNumber': phoneNumber,
    'gender': gender,
    'birthDate': birthDate?.toIso8601String(),
    'country': country,
  };
}
