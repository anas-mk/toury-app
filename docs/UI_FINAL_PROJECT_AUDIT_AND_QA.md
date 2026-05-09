# Toury UI refactor — final audit, QA snapshot, and stabilization (2026)

This document captures the **project-wide state** after the major presentation refactor program, the **last stabilization pass** applied in-tree, and **recommended follow-ups**. It is descriptive, not a runnable spec.

---

## 1. Executive summary

- **Architecture direction**: Feature-first Flutter app with a growing **core design system** (`AppColors`, `AppSpacing`, `AppRadius`, `AppSize`, shared widgets such as `AppScaffold`, `AppEmptyState`, `AppErrorState`, `AppDialog`, `AppSnackbar`, map/tracking chrome).
- **Safety contract maintained across phases**: **No intentional changes** to HTTP APIs, repositories, **Cubit/Bloc business logic**, SignalR contracts, or route **path names** where migration was presentation-only.
- **Analyzer**: `dart analyze lib` completes with **errors: 0**. Latest full run: **321 issues** total (**66 warnings**, **255 infos**). Remaining output is mostly **info**-level hints (e.g. deprecated Mapbox `cameraOptions`, `withOpacity` on `Color`, `avoid_print` in data sources) plus a **warning** cluster (see section 7).
- **Legacy surface area**: `BrandTokens` and `AppTheme.space* / radius*` remain in many files by design; eliminating them entirely would be a multi-sprint mechanical migration, not a stabilization task.

### 1.1 Ship artifact (this pass)

| Item | Change |
|------|--------|
| **Traveler login** | Subtitle / hint text uses `Color.withValues(alpha: …)` instead of deprecated `withOpacity` on theme colors (aligns with splash / role selection). |
| **Audit document** | Source of truth for this report: `docs/UI_FINAL_PROJECT_AUDIT_AND_QA.md` (UTF-8). |

---

## 2. Completed refactor themes (cumulative)

Across the refactor program (not only the last commit), the codebase moved toward:

| Area | Outcomes |
|------|----------|
| **Scaffold / surfaces** | Widespread adoption of `AppScaffold` where screens needed theme-aware backgrounds; booking, chat, invoices, tracking, and account entry points aligned. |
| **State UI** | Consolidation on `AppLoading`, `AppEmptyState`, `AppErrorState` for list/page empty and error paths where touched. |
| **Navigation** | Compatibility-safe `go_router` usage; named routes preserved for deep links (`booking-details`, etc.). |
| **User booking + chat** | `AppSpacing`/`AppColors`, list performance (`addAutomaticKeepAlives: false` where applied), UTF-8 correctness for new Dart files on Windows. |
| **Map / tracking** | Shared `map_tracking_chrome.dart`; **ValueNotifier** + **ValueListenableBuilder** for high-rate location UI; **BlocSelector** on booking identity; **RepaintBoundary** on maps; responsive **DraggableScrollableSheet** fractions. |
| **Invoices / helpers** | Presentation-only alignment with design tokens (per prior phase). |
| **Final polish slice (this stabilization pass)** | Splash + role selection → `AppScaffold` + `AppSpacing`/`AppRadius` + `Color.withValues`; removed dead `translate(...) ??` fallbacks where `translate` is non-nullable; traveler **login** shell + horizontal rhythm + **`withValues`** on secondary text; **account settings** logout → `AppDialog.confirm`; **analyzer error** fix (`AppSpinner.large` misuse); removed unused **go_router** import in helper `home_view`. |

---

## 3. Design system — current state

**Single sources of truth**

- **Semantics / dark mode**: `AppColors.of(context)` (`lib/core/theme/app_color.dart`).
- **Layout numbers**: `AppSpacing`, `AppRadius`, `AppSize`, `AppDurations` (`lib/core/theme/app_dimens.dart`).
- **Legacy**: `AppTheme.space*` / `AppTheme.radius*` remain **supported** for backward compatibility; migration to `AppDimens` is incremental.
- **Brand**: `BrandTokens`, `BrandTypography`, and brand widgets (`core/widgets/brand/*`) remain valid for RAFIQ-specific marketing density and gradients.

**Shared UX primitives**

- **Dialogs**: `AppDialog.confirm` / `AppDialog.info` (`app_dialog.dart`).
- **Snackbars**: `AppSnackbar` + tones (`app_snackbar.dart`).
- **Loading**: `AppSpinner`, `AppLoading`, `AppSkeleton*` (`app_loading.dart`).
- **Map chrome**: `MapRouteInfoChip`, `MapFloatingGlassButton`, `MapTrackingSheetSurface`, `MapTrackingDragHandle`, `MapTrackingLayout` (`map_tracking_chrome.dart`).

---

## 4. Remaining legacy UI patterns

| Pattern | Notes |
|---------|------|
| **Raw `BrandTokens.*` / static `AppColor.*` in widgets** | Common on large booking and home flows; gradual replacement with `AppColors.of(context)` improves dark mode without touching logic. |
| **`AppTheme.space*` / `AppTheme.radius*`** | Still appear in auth, helper profile widgets, booking subflows, hero header, router (see grep metrics below). |
| **`ScaffoldMessenger` + raw `SnackBar`** | Mostly in **auth** and some booking/rating/helpers flows; migrating to `AppSnackbar` unifies margin, shape, and tone. |
| **`showDialog` + `AlertDialog`** | Some screens still use hand-rolled dialogs; prefer `AppDialog` for confirmation consistency. |
| **`showModalBottomSheet` variance** | Mix of transparent backgrounds, ad-hoc padding, and `SoftBottomSheet` / `custom_bottom_sheet` helpers — opportunity for one thin wrapper enforcing `surfaceElevated`, handle, and padding. |
| **`withOpacity` on `Color`** | Lint-friendly migration is `withValues(alpha: ...)` on newer Flutter analyzer rules; splash/role/login partially updated. |
| **Localization `translate(key) ??`** | Analyzer flags **dead null-aware** use because `translate` returns non-nullable `String`. Prefer `loc.translate('key')` only. |

---

## 5. Remaining duplication (do not blindly merge)

Potential shared extractions (**only after** product signs off parity):

| Pair / cluster | Observation |
|----------------|---------------|
| **User vs helper chat** | Different cubits/SIGNALR payloads; UX can align (input bar, quick replies) but extraction to `core/widgets` should stay cautious. |
| **Booking list row vs helper dashboard card** | Shared concepts (chip, avatar, price); `BookingStatusChip` already centralized. |
| **Rating / SOS sheets** | Similar sheet chrome; unified padding/radius tokens help before merging behavior. |

---

## 6. Metrics snapshot (`lib/`, approximate)

Collected via ripgrep-style counts — treat as **order-of-magnitude** (paths may appear twice on case-insensitive duplicates).

| Signal | Approximate scale (from `lib/`, `rg`-style; **dedupe path casing** when interpreting) |
|--------|-------------------|
| **Dart files touching `BrandTokens.`** | **~60+** unique presentation paths (plus `core/theme`, `core/widgets/brand/*` by design). |
| **Dart files touching `AppTheme.(space|radius)`** | **~90+** unique paths (router, hero header, auth, booking, helper profile, payments). |
| **Dart files touching `ScaffoldMessenger.of`** | **~35+** (auth, booking sheets, helper profile, SOS, ratings). |
| **`dart analyze lib` (latest)** | **321 issues**; **0 errors**; **66 warnings**; **255 infos**. |

---

## 7. Analyzer — clusters worth fixing next

**Warnings (examples)**

- **Dead code / redundant `??`** after non-nullable `translate` — role selection fixed; same pattern appears in **helper OTP**, **verify login OTP**, **user register / enter password**, and one **domain** file (`get_current_location_use_case.dart`) that should be fixed with the same nullability reasoning (no behavior change if types are already non-nullable).
- **Unused imports / locals** — e.g. helper `profile_image_helper`, ratings page `isDark` unused.

**Infos (examples)**

- **Deprecated Mapbox ** `cameraOptions` on `MapWidget` — migrate to **`viewport`** when you adopt the newer map API across both tracking screens.
- **Curly braces** in single-line `if` bodies (helper bookings / SOS paths).
- **Other style hints** (`use_build_context_synchronously` pockets, etc.) — address opportunistically when touching files.

---

## 8. Safe deletions — still pending methodology

No bulk widget/page deletion is recommended **without**:

1. `rg` / workspace search on **route path strings**, **`pushNamed`**, **notification/deeplink routers**, **tests**.
2. A short **per-symbol** justification in the MR.

Historical audit docs (`UI_USER_BOOKING_USER_CHAT_PHASE_AUDIT.md`, `UI_MAP_TRACKING_PHASE_AUDIT.md`) already note **no safe route removals** for those scopes.

---

## 9. Performance-sensitive areas (revisit list)

Already improved where noted; optional next steps:

| Area | Idea |
|------|------|
| **Trip tracking / active booking map** | Keep heavy widgets under `RepaintBoundary`; avoid rebuilding map subtree on unrelated bloc emissions (BlocSelector/buildWhen patterns). |
| **Long booking lists / chat** | `ListView.builder` + `addAutomaticKeepAlives: false` where safe; throttle expensive `BackdropFilter` overlays on low-end profiles if profiling shows jank. |
| **Mandatory rating overlay** | Ensure overlay does not rebuild entire tree on ticker unless necessary. |

---

## 10. Responsive QA checklist (manual)

Run on **small phone** (~360 px width), **large phone**, **tablet**:

- Splash → role selection → traveler login → home.
- Helper login → dashboard → active trip map + sheet fractions + SOS button vertical clearance.
- Traveler booking details + cancel dialog/snackbar flows.
- Account settings logout dialog + navigation to login.

Verify **Arabic RTL** on role selection + login if localized builds ship.

---

## 11. Intentionally deferred improvements

| Item | Reason |
|------|--------|
| Full **BrandTokens** purge | High churn, risk of subtle brand regression; migrate file-by-file with screenshots. |
| Mapbox **`viewport`** migration | API-wide change; do when upgrading plugin + testing both roles. |
| Mass **`ScaffoldMessenger` → AppSnackbar`** | Mechanical; batch by feature to keep reviews small. |
| **Single bottom-sheet primitive** wrapping every `showModalBottomSheet` | Requires negotiating scroll vs fixed-CTA patterns across SOS, cancel, picker sheets. |
| **Auth helper OTP `??` localization cleanup** | Tied to warning cluster; purely presentation but touches many strings. |

---

## 12. Final architecture / UI posture (one paragraph)

The app now centers visual and interaction consistency on **`AppColors` + `AppDimens` + named core widgets**, with **`BrandTokens`/`BrandTypography`** retained for RAFIQ-brand richness. Navigation remains **router-driven** with compatibility preserved for existing paths. Presentation refactors prioritized **isolate-friendly** updates around **tracking and lists** without altering **data or realtime** boundaries—leaving the codebase in a **stabilizable** state where further work is incremental token migration, dialog/snackbar uniformity, and analyzer hygiene rather than architectural churn.

---

*Generated as part of the final stabilization sweep; update this file when major new flows land or analyzer baselines shift materially.*