import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {

  static const String defaultProfileImage =
      'https://i.pinimg.com/736x/e8/7a/b0/e87ab0a15b2b65662020e614f7e05ef1.jpg';

  static const String baseUrl = 'http://tourestaapi.runasp.net';

  const UserModel({
    required super.id,
    required super.userId,
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
    String? profileImageUrl = json['profileImageUrl'];

    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      if (profileImageUrl.startsWith('/')) {
        profileImageUrl = '$baseUrl$profileImageUrl';
      }
      else if (profileImageUrl.contains('default.png')) {
        profileImageUrl = defaultProfileImage;
      }
    } else {
      profileImageUrl = defaultProfileImage;
    }

    return UserModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
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
      profileImageUrl: profileImageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'userId': userId,
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

  UserModel copyWith({
    dynamic id,
    String? userId,
    String? email,
    String? userName,
    String? phoneNumber,
    String? gender,
    DateTime? birthDate,
    String? country,
    bool? isVerified,
    String? type,
    String? token,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      country: country ?? this.country,
      isVerified: isVerified ?? this.isVerified,
      type: type ?? this.type,
      token: token ?? this.token,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}