import 'package:flutter/material.dart';

import 'app_color.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColor.primaryColor,
      background: AppColor.lightBackground,
      onPrimary: Colors.white, // لون النص داخل الزرار
      onBackground: AppColor.lightText,
    ),
    scaffoldBackgroundColor: AppColor.lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColor.primaryColor,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColor.lightText),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primaryColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColor.darkPrimary,
      background: AppColor.darkBackground,
      onPrimary: Colors.white,
      onBackground: AppColor.darkText,
    ),
    scaffoldBackgroundColor: AppColor.darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColor.darkBackground,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColor.darkText),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.darkPrimary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );
}




// class AppTheme {
//   static final ThemeData lightTheme = ThemeData(
//     brightness: Brightness.light,
//     primarySwatch: Colors.indigo,
//     primaryColor: Colors.indigo,
//     scaffoldBackgroundColor: Colors.white,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.indigo,
//       foregroundColor: Colors.white,
//     ),
//     textTheme: const TextTheme(
//       bodyLarge: TextStyle(color: Colors.black),
//       bodyMedium: TextStyle(color: Colors.black87),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.indigo,
//         foregroundColor: Colors.white,
//         textStyle: const TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.all(Radius.circular(12)),
//         ),
//       ),
//     ),
//   );
//
//   static final ThemeData darkTheme = ThemeData(
//     brightness: Brightness.dark,
//     primarySwatch: Colors.indigo,
//     primaryColor: Colors.indigo,
//     scaffoldBackgroundColor: Colors.black,
//     appBarTheme: const AppBarTheme(
//       backgroundColor: Colors.black,
//       foregroundColor: Colors.white,
//     ),
//     textTheme: const TextTheme(
//       bodyLarge: TextStyle(color: Colors.white),
//       bodyMedium: TextStyle(color: Colors.white70),
//     ),
//
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.indigo,
//         foregroundColor: Colors.white,
//         textStyle: const TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.all(Radius.circular(12)),
//         ),
//       ),
//     ),
//
//
//
//   );
// }
