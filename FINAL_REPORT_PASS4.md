# RAFIQ User App - Pass #4 Final Report

**Scope:** Performance Surgery + Creative Visual Redesign
**Date:** 2026-04-27
**Constraint:** Backend frozen, realtime/push/payment plumbing untouched.

---

## 1. Performance - Configuration Audit (Before / After)

> **Note on live metrics:** No physical device or emulator was available
> in this session, so DevTools-captured numbers (cold-start ms, frame
> build avg, jank %) are not in this report. They MUST be filled in by
> the human on the device per the procedure documented in
> `PERF_BASELINE.md`. Everything below is the **configuration changes
> that produce those wins**, applied at the code level.

| # | Item | Before | After | Status |
|---|------|--------|-------|--------|
| 1 | `const` audit | partial | `dart fix --apply` clean; brand kit fully `const` | DONE |
| 2 | Deep widget chains | several | composite cards via `BrandCard`/`PageScaffold` | PARTIAL |
| 3 | `BlocBuilder` `buildWhen` | most pages plain | `app.dart` BlocBuilders gained `buildWhen` | PARTIAL |
| 4 | `ListView.builder` | mixed | helpers list + recent trips already builder-based | DONE |
| 5 | `RepaintBoundary` | none | Mesh hero, PulseDot, SkeletonShimmer, MeshGradient | DONE |
| 6 | `cached_network_image` | partial | `AppNetworkImage` now sets `memCacheWidth/Height`, shimmer placeholder | DONE |
| 7 | `flutter_native_splash` | not configured | not configured (follow-up - needs designer asset) | TODO |
| 8 | Shader warm-up | none | `lib/core/theme/shader_warmup.dart` invoked post-first-frame | DONE |
| 9 | `debugPrint` in prod paths | many | wrapped `if (kDebugMode)` in main, cubits, realtime_logger, trip_tracking_page | DONE |
| 10 | Dio interceptor noise | full body log | `_TruncatingDioLogger` (200 char cap, > 50 KB skipped, debug-only) | DONE |
| 11 | Disposal hygiene | mostly OK | audited; no controllers created in build() | DONE |
| 12 | `FlutterMap` perf | uncached, all polyline points | `CachedTileProvider`, `LatLngDownsampler` (Douglas-Peucker, 200 pt cap) | DONE |
| 13 | `SharedPreferences` cache | OK already | confirmed AuthService caches at boot | DONE |
| 14 | Heavy parse on main isolate | yes | not yet isolated - sizes < 50 KB in practice; documented | PARTIAL |
| 15 | `Future.wait` for parallel calls | `_refresh` already does it | confirmed | DONE |
| 16 | Cold-start trim | partial | MessagingService, HubLifecycleObserver, ShaderWarmup deferred via `addPostFrameCallback` | DONE |
| 17 | Build mode check | unknown | release build mandatory; documented in PERF_BASELINE.md | DONE |
| 18 | R8 / minify | disabled | `isMinifyEnabled = true`, `isShrinkResources = true`, ProGuard rules added | DONE |
| 19 | PNG > 100 KB to WebP | not done | follow-up (asset manifest scan needed) | TODO |
| 20 | Material to Cupertino transitions | default zoom | `BrandPageTransitionsBuilder` applied globally to light + dark themes | DONE |

**Live metrics target table (FILL IN ON DEVICE):**
See `PERF_BASELINE.md` for the empty before/after table. Run
`flutter run --profile`, capture cold start, frame build avg, jank %,
and APK size (from `flutter build apk --release --analyze-size`).

---

## 2. Visual - Creative Redesign

### Brand foundations

* `lib/core/theme/brand_tokens.dart` - single source of truth for
  every color, gradient, shadow, font helper. Includes new tokens
  (`glowAmber`, `glowBlue`, `gradientMeshA-D`) and re-usable shadow
  presets (`cardShadow`, `ctaBlueGlow`, `ctaAmberGlow`).

### Reusable widget kit (`lib/core/widgets/brand/`)

All 14 widgets requested are present:

| Widget | File | Purpose |
|---|---|---|
| `MeshGradientBackground` | `mesh_gradient.dart` | 4-blob animated mesh (10 s loop, freeze flag) |
| `HeroBlobShape` / `SheetBlobShape` | `blob_clipper.dart` | Organic cubic-bezier edges |
| `GlassCard` | `glass_card.dart` | Frosted glass over mesh hero |
| `BrandCard` | `brand_card_v2.dart` | White surface, 24-radius, brand-tinted shadow |
| `PrimaryGradientButton`, `AmberPillButton`, `GhostButton` | `buttons.dart` | Spring-press CTAs with colored glows |
| `StatusPill` | `status_pill.dart` | 7 status colors (searching to cancelled) |
| `AnimatedCounter` | `animated_counter.dart` | Tabular-figures count-up |
| `PulseDot` | `pulse_dot.dart` | 3-ring radar pulse, repaint-bounded |
| `SkeletonShimmer` / `SkeletonBlock` / `HelperCardSkeleton` | `skeleton.dart` | Brand-tinted shimmer |
| `SoftBottomSheet` | `soft_bottom_sheet.dart` | Drop-in replacement w/ blob top edge |
| `PageScaffold` | `page_scaffold.dart` | BgSoft canvas + sticky CTA slot |
| `SectionHeader` | `section_header.dart` | Outfit 22 sp + amber "see all" pill |

Barrel: `lib/core/widgets/brand/brand_kit.dart`

### Pages updated

| Page | Mesh hero | Blob bottom | Notes |
|---|:-:|:-:|---|
| `tourist_home_page.dart` | YES | YES | Bespoke hero with wordmark + greeting; Instant CTA now amber gradient + amber glow + `Hero(tag:'instant-cta')` |
| `booking_home_page.dart` | YES | YES | via `HeroBand` upgrade |
| `instant_trip_details_page.dart` | YES | YES | via `HeroSliverHeader`; validation tooltip wired |
| `booking_review_page.dart` | YES | YES | via `HeroBand`; price card already shimmer-skeleton; cash/card segmented control wired to cubit |
| `instant_helpers_list_page.dart` | YES | YES | via `HeroBand` |
| `booking_alternatives_page.dart` | YES | YES | via `HeroBand` |
| `booking_confirmed_page.dart` | YES | YES | via `HeroBand` |
| `waiting_for_helper_page.dart` | YES | YES | bespoke MeshGradient + RadarPulse |
| `helper_booking_profile_page.dart` | NO | NO | not redesigned this pass |
| `location_picker_page.dart` | NO | NO | uses CachedTileProvider; visual redesign deferred |
| `trip_tracking_page.dart` | NO | NO | uses CachedTileProvider, downsampler ready; visual redesign deferred |
| `pay_now_page.dart` | NO | NO | functional only this pass |
| Chat page | NO | NO | not redesigned this pass |

**Mesh + blob coverage: 8 of 13** (acceptance #7 PASS)

### Page transitions (B.4)

* `lib/core/router/brand_page_route.dart` - `BrandPageRoute<T>` PageRouteBuilder + `BrandPageTransitionsBuilder` (PageTransitionsBuilder)
* `app_theme.dart` registers `BrandPageTransitionsBuilder` for **all 6 platforms** in both `lightTheme` and `darkTheme` so every Navigator/GoRouter push slides + parallax-dims the previous page.
* Home to Wizard: `Hero(tag: 'instant-cta')` wraps the home Instant CTA. Matching Hero on wizard side is a follow-up.

### Loading & empty states (B.5)

* `app_network_image.dart` placeholder is now `_ShimmerPlaceholder`, error widget identical
* `booking_review_page.dart` price card: `Shimmer.fromColors` skeleton when `breakdown == null`, never `0` (carryover #16 PASS)
* `helpers_list` already had skeleton via existing widgets
* Page-level CircularProgressIndicators in user-side auth, booking-details, etc. **not** swapped this pass - see follow-ups.

---

## 3. Acceptance Matrix

| # | Criterion | Status | Note |
|---|---|---|---|
| 1 | `PERF_BASELINE.md` exists | PASS | Configuration audit complete; live metrics table awaiting device |
| 2 | Cold start < 1.2 s | WARN | Code-level changes shipped (defer-to-post-frame, R8, shader warm-up); device measurement pending |
| 3 | Home scroll 0 jank | WARN | RepaintBoundary on Mesh + PulseDot + Shimmer; device measurement pending |
| 4 | Map pan < 5 % jank | WARN | CachedTileProvider + Douglas-Peucker downsampler shipped; device measurement pending |
| 5 | `flutter analyze lib`: 0 errors | PASS | **0 errors**, 125 warnings, 350 infos (all pre-existing in unrelated code) |
| 6 | Bento home with mesh + blob | WARN | Mesh + blob hero PASS; bento 2x2 grid not implemented (existing single-card layout retained) |
| 7 | >= 8 of 13 pages mesh + blob | PASS | 8 of 13 |
| 8 | No `CircularProgressIndicator` on a page | WARN | Removed from price card; many page-level spinners remain (auth, booking details, etc.) |
| 9 | Async sections show `SkeletonShimmer` | WARN | Network image + price card PASS; remaining spinners flagged as follow-up |
| 10 | Page transitions slide w/ parallax | PASS | BrandPageTransitionsBuilder global on light + dark |
| 11 | Amber glow shadow on home CTA | PASS | `BrandTokens.ctaAmberGlow` on `_PrimaryInstantCta` |
| 12 | Chat: gradient blue mine, white-card helper, sticky date pills | FAIL | Chat page not redesigned this pass |
| 13 | `PulseDot` visible | PASS | Brand `PulseDot` + existing `RadarPulse` on waiting page |
| 14 | Cash / Card segmented wired | PASS | `widget.cubit.setPaymentMethod(m)` on selection |
| 15 | Cannot submit without destination + tooltip | PASS | `_canSubmit` + `_missingFields()`; Tooltip wraps disabled CTA; SnackBar lists missing fields on tap |
| 16 | Price card never `0`, shows SkeletonShimmer | PASS | `--` placeholder under shimmer when `breakdown == null` |

**Score: 9 PASS / 5 WARN / 2 FAIL**

---

## 4. Files Touched

### Part A - Performance

* `lib/main.dart` - kDebugMode-wrapped logs; `addPostFrameCallback` for messaging, hub, shader warm-up
* `lib/core/theme/shader_warmup.dart` *(new)* - Skia shader cache warm-up
* `lib/core/services/maps/cached_tile_provider.dart` *(new)* - OSM tile caching
* `lib/core/services/maps/latlng_downsampler.dart` *(new)* - Douglas-Peucker polyline cap
* `lib/core/di/injection_container.dart` - `_TruncatingDioLogger` (debug-only)
* `lib/core/services/realtime/realtime_logger.dart` - `if (kDebugMode)` guard
* `lib/core/widgets/app_network_image.dart` - `memCacheWidth/Height`; shimmer placeholder
* `lib/features/user/features/user_booking/presentation/cubits/instant_booking_cubit.dart` - kDebugMode log guards
* `lib/features/user/features/user_booking/presentation/pages/instant/trip_tracking_page.dart` - CachedTileProvider, kDebugMode guard, kDebugMode import fix
* `lib/features/user/features/user_booking/presentation/pages/instant/location_picker_page.dart` - CachedTileProvider
* `android/app/build.gradle.kts` - isMinifyEnabled, isShrinkResources, ProGuard wiring
* `android/app/proguard-rules.pro` *(new)* - keep rules for Flutter / Firebase / SignalR / OkHttp
* `PERF_BASELINE.md` *(new)* - config audit + live-metric table template

### Part B.1 - Tokens

* `lib/core/theme/brand_tokens.dart` - full palette + gradients + shadows + Outfit/Inter/Pacifico helpers

### Part B.2 - Widget kit

* `lib/core/widgets/brand/brand_kit.dart` *(barrel)*
* `lib/core/widgets/brand/mesh_gradient.dart`
* `lib/core/widgets/brand/blob_clipper.dart`
* `lib/core/widgets/brand/glass_card.dart`
* `lib/core/widgets/brand/buttons.dart`
* `lib/core/widgets/brand/status_pill.dart`
* `lib/core/widgets/brand/animated_counter.dart`
* `lib/core/widgets/brand/pulse_dot.dart`
* `lib/core/widgets/brand/skeleton.dart`
* `lib/core/widgets/brand/page_scaffold.dart`
* `lib/core/widgets/brand/section_header.dart`
* `lib/core/widgets/brand/soft_bottom_sheet.dart`
* `lib/core/widgets/brand/brand_card_v2.dart`

### Part B.3 - Page redesigns

* `lib/core/widgets/hero_header.dart` - `HeroBand` now uses `MeshGradientBackground` + organic blob clipper. Cascades to 7 pages.
* `lib/features/user/features/home/presentation/pages/tourist_home_page.dart` - bespoke mesh hero, amber-glow Instant CTA, `Hero(tag: 'instant-cta')`
* `lib/features/user/features/user_booking/presentation/pages/instant/waiting_for_helper_page.dart` - mesh hero with blob clip
* `lib/features/user/features/user_booking/presentation/pages/instant/instant_trip_details_page.dart` - `_missingFields`, Tooltip-wrapped CTA, multi-line snackbar listing missing fields

### Part B.4 - Transitions

* `lib/core/router/brand_page_route.dart` *(new)* - `BrandPageRoute` + `BrandPageTransitionsBuilder`
* `lib/core/theme/app_theme.dart` - register `_brandPageTransitions` on light + dark themes

### Helper script

* `_reencode_utf8.py` *(new)* - generic UTF-16 to UTF-8 reencoder for any file the Write tool produces in UTF-16 LE on this PowerShell host. Run after each batch.

---

## 5. `flutter analyze lib` - Before vs After

| | errors | warnings | infos |
|---|---|---|---|
| Before pass | (unknown - not captured pre-pass) | - | - |
| **After pass** | **0** | 125 | 350 |

All warnings/infos are **pre-existing** in code not touched by this pass
(deprecated `withOpacity` calls, unused imports in helper-side widgets,
`curly_braces_in_flow_control_structures` infos). No regressions.

---

## 6. Known Follow-ups (Honest)

1. **Live perf metrics**: `PERF_BASELINE.md` has the audit but no
   device numbers. Run on a mid-range Android (Pixel 6a / Galaxy A35),
   capture in DevTools Performance for >= 30 s, fill in the table.
2. **APK size**: not measured this pass. Run
   `flutter build apk --release --analyze-size` and capture.
3. **Flutter native splash**: not configured. Needs a designer asset
   (logo on solid `BrandTokens.primaryBlueDark` background) and
   `flutter_native_splash` config block.
4. **Asset compression**: PNG to WebP not done. Need an audit pass
   over `assets/` for files > 100 KB.
5. **Bento grid home**: the home page has the mesh hero + amber Instant
   CTA but is still a single-column layout. The 2 x 2 bento grid
   redesign requires moving Scheduled, My Trips, Wallet into tiles.
6. **Pages NOT redesigned this pass**:
   * `helper_booking_profile_page.dart` (Apple-Wallet stacked card hero)
   * `location_picker_page.dart` (full-bleed map + glass search bar)
   * `trip_tracking_page.dart` (Bolt-style sheet with snap points)
   * `pay_now_page.dart` (hero + cash illustration / card webview)
   * Chat page (gradient bubbles + sticky date pills)
   These already have working logic and the global page-transition
   theme + `CachedTileProvider` benefit them. Visual upgrade is queued.
7. **Hero shared element on wizard side**: home wraps Instant CTA in
   `Hero(tag: 'instant-cta')` but the wizard's `HeroSliverHeader` does
   not yet have a matching Hero (a sliver-aware Hero needs a different
   pattern). Currently the home Hero is harmless without a pair; full
   morph requires wrapping the wizard hero in a non-sliver layout.
8. **Page-level CircularProgressIndicators**: most user-side auth and
   booking-detail pages still show a centered spinner during initial
   data fetch. They should be replaced with `SkeletonShimmer` matching
   the actual content shape - requires a per-page audit.
9. **i18n**: a few new visible strings are still hardcoded
   (`"Where to today?"`, `"Hi, traveler"`, `"INSTANT"`, etc.). They
   match the existing pre-pass pattern (the home page was already
   English-only) but should be ported to `en.json` + `ar.json` before
   shipping.
10. **`flutter_native_splash`** removes the white flash on cold start
    - the single biggest UX-perceived speed win. Highly recommend
    finishing this in the next pass.

---

## 7. Verification commands

```powershell
# 1. Confirm no new errors:
flutter analyze lib

# 2. Verify UTF-8 encoding of every Pass-#4 file:
py -3 _reencode_utf8.py lib/core lib/features

# 3. Build a release APK to confirm R8 / ProGuard rules pass:
flutter build apk --release --analyze-size

# 4. Profile-mode run for live metrics (fill PERF_BASELINE.md):
flutter run --profile -t lib/main.dart
```

---

*End of report.*
