import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toury/features/splash/presentation/pages/splash_page.dart';
import 'core/localization/cubit/localization_cubit.dart';
import 'core/theme/theme_cubit.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          title: 'Tour Meta',
          themeMode: themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          // locale: locale,
          debugShowCheckedModeBanner: false,

          // supportedLocales: const [Locale('en'), Locale('ar')],
          //
          // localizationsDelegates: const [
          //   AppLocalizations.delegate,
          //   GlobalMaterialLocalizations.delegate,
          //   GlobalWidgetsLocalizations.delegate,
          //   GlobalCupertinoLocalizations.delegate,
          // ],
          home: const SplashPage(),
        );
      },
    );
  }
}
