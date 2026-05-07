import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection_container.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/cubit/localization_cubit.dart';
import 'core/router/app_router.dart';
import 'core/services/realtime/realtime_connection_issue_notifier.dart';
import 'core/services/signalr/booking_tracking_hub_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_state.dart';
import 'core/widgets/app_connection_banner.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      buildWhen: (prev, next) => prev != next,
      builder: (context, themeState) {
        return BlocBuilder<LocalizationCubit, Locale>(
          buildWhen: (prev, next) => prev != next,
          builder: (context, locale) {
            return MaterialApp.router(
              title: 'Tour Meta',
              themeMode: themeState.themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              locale: locale,
              debugShowCheckedModeBanner: false,
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: AppRouter.router,
              builder: (context, child) {
                return ListenableBuilder(
                  listenable: sl<RealtimeConnectionIssueNotifier>(),
                  builder: (context, _) {
                    final notifier = sl<RealtimeConnectionIssueNotifier>();
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (child != null) child,
                        if (notifier.showAuthBanner)
                          AppConnectionBanner(
                            message: notifier.bannerMessage,
                            onRetry: () {
                              notifier.clear();
                              unawaited(
                                sl<BookingTrackingHubService>().start(),
                              );
                            },
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
