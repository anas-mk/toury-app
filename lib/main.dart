import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/localization/cubit/localization_cubit.dart';
import 'core/router/app_router.dart';
import 'core/services/notifications/messaging_service.dart';
import 'core/services/notifications/notification_router.dart';
import 'core/services/realtime/booking_realtime_event_bus.dart';
import 'core/services/realtime/hub_lifecycle_observer.dart';
import 'core/services/signalr/booking_tracking_hub_service.dart';
import 'core/services/realtime/realtime_logger.dart';
import 'core/theme/theme_cubit.dart';
import 'features/helper/features/auth/presentation/cubit/helper_auth_cubit.dart';
import 'features/tourist/features/auth/presentation/cubit/auth_cubit.dart';

/// Top-level handler so FCM background messages are processed even when the
/// Dart isolate has been killed. MUST be a top-level (or static) function —
/// Firebase requires a const-evaluable entry point with the `@pragma`
/// annotation below.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Background messages are also rendered by the OS via the FCM `notification`
  // payload; we just log here for diagnostics. Do NOT push routes from a
  // background isolate — the navigator isn't mounted there.
  debugPrint('🔔 [bg] FCM message: ${message.messageId} '
      'data=${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is best-effort: if the native config isn't deployed yet we still
  // want the rest of the app to launch. The MessagingService gracefully
  // becomes a no-op in that case.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ Firebase.initializeApp failed: $e');
  }

  await di.init();

  BookingRealtimeEventBus.instance
      .attach(di.sl<BookingTrackingHubService>());

  // Bind the GoRouter to the NotificationRouter so FCM taps and SignalR
  // navigation triggers can reach the same routes the rest of the app uses.
  NotificationRouter.instance.bind(
    AppRouter.router,
    navigatorKey: AppRouter.rootNavigatorKey,
  );
  RealtimeLogger.instance.log('Router', 'main.bind', 'GoRouter wired');

  // Pre-initialise local-notifications so a foreground push arriving on
  // the very first second after launch can still display its heads-up.
  unawaited(di.sl<MessagingService>().initialise());

  // Wake the SignalR connection back up whenever the OS resumes the app.
  di.sl<HubLifecycleObserver>().attach();

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDark') ?? false;

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(isDark: isDark)),
        BlocProvider(create: (_) => LocalizationCubit()),
        BlocProvider(
          create: (_) => di.sl<AuthCubit>()..checkAuthStatus(),
        ),
        BlocProvider(create: (_) => di.sl<HelperAuthCubit>()),
      ],
      child: const MyApp(),
    ),
  );
}

