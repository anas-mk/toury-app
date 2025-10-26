import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/splash/presentation/pages/splash_page.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/cubit/localization_cubit.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return BlocBuilder<LocalizationCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              title: 'Tour Meta',
              themeMode: themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              locale: locale,
              debugShowCheckedModeBanner: false,

              // Localization configuration
              supportedLocales: const [Locale('en'), Locale('ar')],

              localizationsDelegates: [
                AppLocalizations.delegate,
                // Add other delegates as needed
              ],

              home: const SplashPage(),
            );
          },
        );
      },
    );
  }
}
