import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/config/api_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/localization/cubit/localization_cubit.dart';
import 'core/router/app_router.dart';
import 'core/services/notifications/messaging_service.dart';
import 'core/services/notifications/notification_router.dart';
import 'core/services/realtime/app_realtime_cubit.dart';
import 'core/services/realtime/booking_realtime_event_bus.dart';
import 'core/services/realtime/hub_lifecycle_observer.dart';
import 'features/tourist/features/user_chat/presentation/unread_chat_tracker.dart';
import 'features/tourist/features/user_ratings/presentation/widgets/mandatory_rating_overlay.dart';
import 'core/services/signalr/booking_tracking_hub_service.dart';
import 'core/services/realtime/realtime_logger.dart';
import 'core/theme/shader_warmup.dart';
import 'core/theme/theme_cubit.dart';
import 'features/helper/features/auth/presentation/cubit/helper_auth_cubit.dart';
import 'features/tourist/features/auth/presentation/cubit/auth_cubit.dart';
import 'firebase_options.dart';


/// Top-level handler so FCM background messages are processed even when the
/// Dart isolate has been killed. MUST be a top-level (or static) function —
/// Firebase requires a const-evaluable entry point with the `@pragma`
/// annotation below.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Background messages are also rendered by the OS via the FCM `notification`
  // payload; we just log here for diagnostics. Do NOT push routes from a
  // background isolate — the navigator isn't mounted there.
  if (kDebugMode) {
    debugPrint('🔔 [bg] FCM message: ${message.messageId} '
        'data=${message.data}');
  }
}

/// True only when [Firebase.initializeApp] succeeded. Other modules
/// (e.g. [MessagingService.start]) check this so they don't blow up trying to
/// touch FirebaseMessaging when there's no native config on device.
bool firebaseReady = false;
bool _backgroundHandlerRegistered = false;

/// Bootstrap-owned subscription for `onMessageOpenedApp`. Held at the
/// top level so it's installed BEFORE any auth state — this is the
/// background-tap path (app was alive but not visible). It lives for the
/// app's lifetime; `MessagingService.start()` re-subscribes too, but
/// having one here means the navigation works even before the user
/// has logged in (relevant for the public splash → tap → deep-link race).
StreamSubscription<RemoteMessage>? _bootstrapOnMessageOpenedAppSub;

/// Step 5 diagnostic: prove the SDK can mint a token at all. Logs the
/// suffix only — never the full token to chat/console (the token alone
/// is enough to receive pushes addressed to this device).
/// Not called in any production code path; only fired once after init.
Future<void> _logFcmTokenOnce() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      RealtimeLogger.instance.log(
        'FCM',
        'token.diag',
        'getToken() returned null/empty — Play Services may be missing or '
            'the Firebase project is misconfigured',
        isError: true,
      );
      return;
    }
    final tail = token.length <= 12 ? token : token.substring(token.length - 12);
    RealtimeLogger.instance.log(
      'FCM',
      'token.diag',
      'getToken() ok len=${token.length} tail=…$tail',
    );
  } catch (e) {
    RealtimeLogger.instance.log(
      'FCM',
      'token.diag.error',
      '$e',
      isError: true,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge system bars. Without this Android draws a solid
  // dark band behind the status bar even when an `AnnotatedRegion`
  // sets `statusBarColor: transparent` — that's what was leaving the
  // black bar on top of full-bleed pages like the live-track map.
  //
  // We pair it with a global SystemUiOverlayStyle baseline (light
  // surface, dark icons) so any page that doesn't override via
  // `AnnotatedRegion` still gets sensible defaults instead of
  // inheriting whatever Android ROM picked.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Load brand fonts before the first frame so the RAFIQ wordmark is correct.
  try {
    final loader = FontLoader('PermanentMarker')
      ..addFont(rootBundle.load('fonts/PermanentMarker-Regular.ttf'));
    await loader.load();
  } catch (_) {}

  // Mapbox SDK 2.x requires the token to be set globally before any MapWidget
  // is instantiated. ResourceOptions was removed in v2.
  // Only set programmatically when the dart-define was actually provided;
  // otherwise the empty string would override the mapbox_access_token
  // string resource in android/app/src/main/res/values/strings.xml.
  if (ApiConfig.mapboxToken.isNotEmpty) {
    MapboxOptions.setAccessToken(ApiConfig.mapboxToken);
  }

  // Firebase is best-effort: if the native config isn't deployed yet we still
  // want the rest of the app to launch. The MessagingService gracefully
  // becomes a no-op in that case.
  //
  // We pass `options: DefaultFirebaseOptions.currentPlatform` (generated by
  // `flutterfire configure`) so init does NOT depend on the Android Gradle
  // plugin baking google-services.json into the build — both paths now agree
  // on the same `rafiq-gp26` project.
  try {
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (!_backgroundHandlerRegistered) {
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      _backgroundHandlerRegistered = true;
    }
    firebaseReady = true;
    RealtimeLogger.instance.log(
      'FCM',
      'firebase.init.ok',
      'app=${app.name} project=${app.options.projectId}',
    );
    // One-shot diagnostic: confirm the SDK can actually mint a token.
    // Fire-and-forget so we don't block bootstrap; the result lands in
    // the RealtimeLogger ring buffer and the console.
    unawaited(_logFcmTokenOnce());

    // Cold-start tap (app was killed): if the user opened the app by
    // tapping a notification, FirebaseMessaging holds the message until
    // we ask for it. We CANNOT route now — neither the GoRouter nor the
    // navigator key are bound yet — so we stash the data into the
    // NotificationRouter's pending buffer. It's drained later by
    // app_router.dart's redirect callback once auth has resolved and a
    // real route is being entered.
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final stringData = <String, dynamic>{
          for (final entry in initialMessage.data.entries)
            entry.key: entry.value?.toString(),
        };
        NotificationRouter.instance.setPendingDeepLink(stringData);
      }
    } catch (e) {
      RealtimeLogger.instance.log(
        'FCM',
        'getInitialMessage.error',
        '$e',
        isError: true,
      );
    }

    // Background tap (app was alive but not visible): subscribe at
    // bootstrap so a tap that arrives before the user has logged in
    // — and therefore before MessagingService.start() runs — still
    // routes correctly. The router itself is bound just below this
    // block; if a tap somehow fires in the ~milliseconds between
    // here and `NotificationRouter.bind`, `routeFromData` falls back
    // to setPendingDeepLink via the router's bind-not-ready guard.
    _bootstrapOnMessageOpenedAppSub?.cancel();
    _bootstrapOnMessageOpenedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final stringData = <String, dynamic>{
        for (final entry in message.data.entries)
          entry.key: entry.value?.toString(),
      };
      RealtimeLogger.instance.log(
        'FCM',
        'onMessageOpenedApp',
        'type=${stringData['notificationType']}',
        eventId: stringData['eventId']?.toString(),
      );
      NotificationRouter.instance
          .routeFromData(stringData, reason: 'fcm-bg-tap');
    });
  } catch (e, st) {
    firebaseReady = false;
    // Log unconditionally (not only in debug) — a silent failure here is
    // exactly what bit us last run.
    RealtimeLogger.instance.log(
      'FCM',
      'firebase.init.fail',
      '$e',
      isError: true,
    );
    debugPrint(
      '⚠️ Firebase.initializeApp failed: $e\n$st\n'
      '   → google-services.json (Android) / GoogleService-Info.plist (iOS) '
      'is missing or the Google Services Gradle plugin is not applied. '
      'FCM push notifications will be disabled until that is done.',
    );
  }

  await di.init();

  BookingRealtimeEventBus.instance
      .attach(di.sl<BookingTrackingHubService>());
  BookingRealtimeEventBus.instance.onEventPublished =
      (e) => di.sl<MessagingService>().maybeInAppBannerFromBusEvent(e);

  // Phase 3: attach the app-wide realtime orchestrator. It subscribes to
  // the same bus and propagates relevant events to currently-mounted
  // page cubits via their existing public refresh APIs.
  di.sl<AppRealtimeCubit>().attach();

  // App-wide unread-chat counter. Listens to `chatMessageStream`
  // for the entire session so chat icons on the live-track map and
  // the booking-confirmed page can render an unread badge — even
  // before the user opens the chat page itself.
  UnreadChatTracker.attach(di.sl<BookingTrackingHubService>());

  // Bind the GoRouter to the NotificationRouter so FCM taps and SignalR
  // navigation triggers can reach the same routes the rest of the app uses.
  NotificationRouter.instance.bind(
    AppRouter.router,
    navigatorKey: AppRouter.rootNavigatorKey,
  );
  RealtimeLogger.instance.log('Router', 'main.bind', 'GoRouter wired');

  // Phase 4: bind the global mandatory rating overlay. Listens to the
  // pending-ratings tracker and re-shows on cold start if anything is
  // pending.
  MandatoryRatingOverlay.bind(AppRouter.rootNavigatorKey);

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

  // Pass #4 perf: defer non-critical work to AFTER the first frame so we don't
  // delay the time-to-interactive on cold start.
  SchedulerBinding.instance.addPostFrameCallback((_) {
    // 1) Foreground push channel (heads-up notifications)
    unawaited(di.sl<MessagingService>().initialise());
    // 2) Wake SignalR back up whenever the OS resumes the app
    di.sl<HubLifecycleObserver>().attach();
    // 3) Compile every gradient/shadow shader on a hidden offscreen surface
    //    so the user never sees the 30-80ms first-tap shader compile pause.
    ShaderWarmup.warmUp();
  });
}
