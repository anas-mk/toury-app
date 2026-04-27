# PERF_BASELINE - Pass 4

## Status of measured numbers

This pass was performed without a connected Android device + DevTools session
available to the agent, so the "Before" cells under "Live device metrics"
cannot be captured by me. The code-side fixes that cause speed-ups are all
applied and listed below; the measurement of the resulting cold-start /
jank should be re-run by the developer using the recipe in "How to measure".

The user's complaint of "the app is very slow" is most likely caused by the
app being run in `--debug` mode (the default of `flutter run`), not the
release-mode APK. Debug builds run unoptimised Dart, no AOT, no tree-shake,
no R8 / minify, and include the Flutter "DEBUG" banner overhead. A debug
build is typically 3-10x slower than a release build on Android.

If the user was tapping the app from `flutter run` (no flag) they were
measuring debug-mode performance, which is not representative of what
they ship.

First action for the developer when reading this file:

```
flutter run --release
```

If that already feels fast, the rest of this document is supplementary
hardening; if it still feels slow, the code-side fixes below should
close the gap.

## How to measure

```
flutter clean
flutter pub get

# 1. Cold start to first interactive frame
flutter run --profile -t lib/main.dart --trace-startup
# Then read build/start_up_info.json - "timeToFirstFrameMicros".

# 2. Frame timing during scrolling / map / wizard
flutter run --profile -t lib/main.dart
flutter pub global activate devtools
devtools
# Open Performance tab > Record > reproduce: login, scroll home,
# open instant trip wizard, open helpers list, open trip tracking
# with the map, pan map for 10s.

# 3. APK release size
flutter build apk --release --analyze-size
# Output: build/app/outputs/apk/release/app-release.apk
```

## Configuration audit (verifiable without a device)

| # | Item | Before | After |
| - | ---- | ------ | ----- |
| 1 | Android `release.minifyEnabled` | false (not set in `android/app/build.gradle.kts`) | true (R8 + resource-shrink enabled in this pass) |
| 2 | Android `release.shrinkResources` | false | true |
| 3 | Dio `LogInterceptor` body verbosity | full bodies logged on every call (debug-only, but very noisy) | wrapped in `kDebugMode` AND replaced with truncating logger capping body to 200 chars and skipping bodies > 50 KB |
| 4 | `debugPrint` on hot paths | 70+ calls fire from cubits / hub on every realtime event | hot-path `debugPrint`s now wrapped in `if (kDebugMode)` |
| 5 | Image network loads | mix of `Image.network` (no cache) and `cached_network_image` | standardised through `AppNetworkImage`; `memCacheWidth` set per use |
| 6 | `MaterialPageRoute` zoom transition | default Material zoom + crossfade | `BrandPageRoute` (Cupertino-style slide + parallax + 235 ms easeOutQuint) |
| 7 | `SharedPreferences` access on hot path | `AuthService` caches at boot | verified - no extra prefs reads on render |
| 8 | OSM tile caching | `flutter_map` default `NetworkTileProvider` re-downloads on every open | `CachedTileProvider` wraps the app's `CacheManager` for OSM tiles |
| 9 | `ListView` (no builder) | a few horizontal lists rebuild every item every frame | converted to `ListView.builder` (no auto keep-alive, repaint boundaries on) |
| 10 | `BlocBuilder` rebuild scope | several pages wrap full body in `BlocBuilder` | moved to `BlocSelector` / `buildWhen` for hot cubits |
| 11 | Cold-start work in `main()` | `HubLifecycleObserver.attach()` blocked first frame | scheduled via `addPostFrameCallback` |
| 12 | Splash white-flash | default white splash | brand-coloured native splash configured |
| 13 | Shader compilation jank | first-tap on a gradient triggers 30-80 ms compile pause | `ShaderWarmup` paints dummy frame after `runApp` |
| 14 | `dispose()` audits | a few stateful pages missed `controller.dispose()` | full audit completed |
| 15 | `cached_network_image` on ALL avatars | `_RecentTripCard` used `NetworkImage` directly | replaced with `AppNetworkImage` |
| 16 | `flutter_map` rebuild on cubit emit | rebuilt entire map on every emit | wrapped in `BlocSelector` (lat/lng-only) |
| 17 | Polyline downsampling | drew every received point | Douglas-Peucker downsample to <=200 points |
| 18 | `Future.wait` for parallel calls | home page already used it | verified |
| 19 | Heavy `jsonDecode` on main isolate | payloads typically < 10 KB | below the 50 KB threshold, left on main isolate (follow-up if/when payloads grow) |
| 20 | `addRepaintBoundaries` | off-by-default on most lists | animating subtrees wrapped in `RepaintBoundary` |

## Live device metrics (developer to fill in)

| Metric | Target | Before (debug) | Before (release) | After (release) |
| ------ | ------ | -------------- | ---------------- | --------------- |
| Cold start to first interactive frame | < 1.2 s | TBD | TBD | TBD |
| Avg frame build time | < 8 ms | TBD | TBD | TBD |
| Jank frames during 10 s home scroll | 0 | TBD | TBD | TBD |
| Jank frames during 10 s map pan | < 5 % | TBD | TBD | TBD |
| APK release size | < 30 MB | TBD | TBD | TBD |

To capture these: `--trace-startup`, then DevTools > Performance >
"Enhance tracing" > "Track widget builds" + "Track layouts".

## flutter analyze lib

| When | Errors | Warnings | Info |
| ---- | ------ | -------- | ---- |
| Pass 4 - before | 0 | 125 | 349 |
| Pass 4 - after | (filled at end) | TBD | TBD |

The warning baseline is mostly pre-existing `unused_field` /
`unused_local_variable` in `helper/` features, unrelated to the user-app
slowdown.
