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
    super.isVerified,
    super.type,
    super.token,
    super.profileImageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      userName: json['userName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      gender: json['gender'] ?? '',
      birthDate: json['birthDate'] != null && json['birthDate'] != ''
          ? DateTime.tryParse(json['birthDate'])
          : null,
      country: json['country'] ?? '',
      isVerified: json['isVerified'] ?? false,
      type: json['type'] ?? '',
      token: json['token'],
      profileImageUrl: json['profileImageUrl'] ??
          'https://i.pinimg.com/736x/e8/7a/b0/e87ab0a15b2b65662020e614f7e05ef1.jpg',
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
    'isVerified': isVerified,
    'type': type,
    'token': token,
    'profileImageUrl': profileImageUrl,
  };
}
