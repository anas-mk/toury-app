import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/theme_cubit.dart';
import 'core/localization/cubit/localization_cubit.dart';
import 'features/tourist/features/auth/presentation/cubit/auth_cubit.dart';
import 'features/tourist/features/home/presentation/cubit/bottom_nav_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDark') ?? false;

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(isDark: isDark)),
        BlocProvider(create: (_) => LocalizationCubit()),
        BlocProvider(create: (_) => BottomNavCubit()),
        BlocProvider(
          create: (_) => di.sl<AuthCubit>()
            ..checkAuthStatus(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}