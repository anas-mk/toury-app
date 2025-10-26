// import 'package:flutter_test/flutter_test.dart';
// import 'package:dartz/dartz.dart';
// import 'package:toury/core/errors/failures.dart';
// import 'package:toury/features/tourist/features/auth/domain/usecases/google_login_usecase.dart';
// import 'package:toury/features/tourist/features/auth/domain/repositories/auth_repository.dart';
// import 'package:toury/features/tourist/features/auth/domain/usecases/verify_google_code_usecase.dart';
//
// class MockAuthRepository extends Mock implements AuthRepository {}
//
// void main() {
//   late MockAuthRepository mockRepository;
//   late GoogleLoginUseCase googleLoginUseCase;
//   late VerifyGoogleCodeUseCase verifyGoogleCodeUseCase;
//
//   setUp(() {
//     mockRepository = MockAuthRepository();
//     googleLoginUseCase = GoogleLoginUseCase(mockRepository);
//     verifyGoogleCodeUseCase = VerifyGoogleCodeUseCase(mockRepository);
//   });
//
//   group('Google Authentication Tests', () {
//     test('should return success when Google login is successful', () async {
//       // Arrange
//       const email = 'test@example.com';
//       const expectedResult = {
//         'message': 'Login successful',
//         'action': 'login_success',
//         'user': {'id': '123', 'email': email, 'userName': 'Test User'},
//       };
//       when(
//         mockRepository.googleLogin(email),
//       ).thenAnswer((_) async => Right(expectedResult));
//
//       // Act
//       final result = await googleLoginUseCase(email);
//
//       // Assert
//       expect(result, Right(expectedResult));
//     });
//
//     test('should return failure when Google login fails', () async {
//       // Arrange
//       const email = 'test@example.com';
//       const failure = ServerFailure('Login failed');
//
//
//       // Act
//       final result = await googleLoginUseCase(email);
//
//       // Assert
//       expect(result, Left(failure));
//     });
//
//     test('should return success when Google register sends OTP', () async {
//       // Arrange
//       const googleId = 'google123';
//       const name = 'Test User';
//       const email = 'test@example.com';
//       const expectedResult = {
//         'message': 'OTP sent to your email',
//         'action': 'code_sent',
//       };
//       when(
//         mockRepository.googleRegister(
//           googleId: googleId,
//           name: name,
//           email: email,
//         ),
//       ).thenAnswer((_) async => Right(expectedResult));
//
//       // Act
//       final result = await googleRegisterUseCase(
//         googleId: googleId,
//         name: name,
//         email: email,
//       );
//
//       // Assert
//       expect(result, Right(expectedResult));
//       verify(
//         mockRepository.googleRegister(
//           googleId: googleId,
//           name: name,
//           email: email,
//         ),
//       );
//       verifyNoMoreInteractions(mockRepository);
//     });
//
//     test(
//       'should return success when Google code verification is successful',
//       () async {
//         // Arrange
//         const email = 'test@example.com';
//         const code = '123456';
//         const expectedUser = {
//           'id': '123',
//           'email': email,
//           'userName': 'Test User',
//           'phoneNumber': '1234567890',
//           'gender': 'Male',
//           'birthDate': '1990-01-01',
//           'country': 'US',
//         };
//         when(
//           mockRepository.verifyGoogleCode(email: email, code: code),
//         ).thenAnswer((_) async => Right(expectedUser));
//
//         // Act
//         final result = await verifyGoogleCodeUseCase(email: email, code: code);
//
//         // Assert
//         expect(result, Right(expectedUser));
//         verify(mockRepository.verifyGoogleCode(email: email, code: code));
//         verifyNoMoreInteractions(mockRepository);
//       },
//     );
//
//     test('should return validation failure when email is empty', () async {
//       // Act
//       final result = await googleLoginUseCase('');
//
//       // Assert
//       expect(result, Left(ValidationFailure('Email is required')));
//       verifyNoMoreInteractions(mockRepository);
//     });
//
//     test('should return validation failure when Google ID is empty', () async {
//       // Act
//       final result = await googleRegisterUseCase(
//         googleId: '',
//         name: 'Test User',
//         email: 'test@example.com',
//       );
//
//       // Assert
//       expect(result, Left(ValidationFailure('GoogleId is required')));
//       verifyNoMoreInteractions(mockRepository);
//     });
//
//     test(
//       'should return validation failure when verification code is empty',
//       () async {
//         // Act
//         final result = await verifyGoogleCodeUseCase(
//           email: 'test@example.com',
//           code: '',
//         );
//
//         // Assert
//         expect(
//           result,
//           Left(ValidationFailure('Verification code is required')),
//         );
//         verifyNoMoreInteractions(mockRepository);
//       },
//     );
//   });
// }
//
