class UserEntity {
  final String id;
  final String email;
  final String userName;
  final String phoneNumber;
  final String gender;
  final DateTime? birthDate;
  final String country;

  const UserEntity({
    required this.id,
    required this.email,
    required this.userName,
    required this.phoneNumber,
    required this.gender,
    required this.birthDate,
    required this.country,
  });

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
