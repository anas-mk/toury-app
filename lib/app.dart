import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:toury/features/splash/presentation/pages/splash_page.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/cubit/localization_cubit.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ThemeCubit, ThemeMode>(listener: (_, __) {}),
        BlocListener<LocalizationCubit, Locale>(listener: (_, __) {}),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, themeMode) {
          return BlocBuilder<LocalizationCubit, Locale>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, locale) {
              final isDark = themeMode == ThemeMode.dark;

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: MaterialApp(
                  key: ValueKey(isDark),
                  title: 'Tour Meta',
                  themeMode: themeMode,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  locale: locale,
                  debugShowCheckedModeBanner: false,
                  supportedLocales: const [
                    Locale('en'),
                    Locale('ar'),
                  ],
                  localizationsDelegates: const [
                    AppLocalizations
                        .delegate,
                    GlobalMaterialLocalizations
                        .delegate,
                    GlobalWidgetsLocalizations
                        .delegate,
                    GlobalCupertinoLocalizations
                        .delegate,
                  ],
                  home: const SplashPage(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
