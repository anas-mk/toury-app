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
        builder: (context, _) {
          // Tourist redesign is light-only; ThemeCubit is still listened to
          // in case it controls other branches (e.g. system overlay style).
          return BlocBuilder<LocalizationCubit, Locale>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, locale) {
              return MaterialApp.router(
                title: 'Tour Meta',
                // Phase 1 (Tourist UI redesign): the brief is light-only.
                // The dark theme block stays in `AppTheme` so a future flag
                // is trivial, but every screen renders against the brand
                // light palette regardless of the cubit's state.
                themeMode: ThemeMode.light,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                locale: locale,
                debugShowCheckedModeBanner: false,
                supportedLocales: const [
                  Locale('en'),
                  Locale('ar'),
                ],
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
                      final n = sl<RealtimeConnectionIssueNotifier>();
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          if (child != null) child,
                          if (n.showAuthBanner)
                            SafeArea(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Material(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.cloud_off_outlined,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            n.bannerMessage,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onErrorContainer,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            n.clear();
                                            unawaited(
                                              sl<BookingTrackingHubService>()
                                                  .start(),
                                            );
                                          },
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
      ),
    );
  }
}
