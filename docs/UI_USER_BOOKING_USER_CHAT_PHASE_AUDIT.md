# User booking + User chat phase audit

## Routing (verified in app_router.dart)

Primary named routes impacting these flows:

- booking-home
- booking-details (unified instant + scheduled)
- my-bookings
- instant-* (trip details, helpers, review, waiting, alternatives, confirmed, tracking, pay-now)
- user-chat (path userChat)
- payments, rate-booking, tracking as handoffs from booking/chat

Navigation uses pushNamed / extras in places; structural route removal risks deep links — **none recommended** this phase.

## Duplicate / overlap (defer core extraction)

- **Traveler booking row cards** (my_bookings_page) vs **helper** booking cards/chips share concepts (avatar, status, price); **BookingStatusChip** already lives in core. Promote a shared **booking list row** to core/widgets only after both sides stabilize visually.

- **User vs Helper chat bubbles + input bars** behave similarly but use different SignalR enums and Cubits; duplicate **quick replies sheet** retained under user_chat (same UX pattern as helper) without coupling feature folders.

## Safe deletions this phase

- **None** — audit-only; removals would need grep across Deep links / NotificationRouter.

## Constraints (contract)

- No changes to repositories, datasources, use cases, Cubit/Bloc signatures or emit logic.
- Presentation, navigation **names**/paths unchanged; pushNamed preserved where already used.

## Delivered this pass (presentation-only)

- **user_chat**: Fixed `user_chat_quick_replies_sheet.dart` on-disk encoding (UTF-8); quick replies sheet matches `AppSpacing` / `AppRadius` / `AppColors.surfaceElevated`.
- **user_booking — `my_bookings_page.dart`**: `AppScaffold`, `AppLoading`, `AppErrorState`, `AppEmptyState`; `RefreshIndicator` uses theme `AppColors.primary`; list uses `ListView.builder` + `addAutomaticKeepAlives: false`; paddings migrated to tokens where numerical literals stood in for scale. **`BookingStatusChip` and `pushNamed('booking-details', …)` unchanged.**
- **user_booking — `booking_home_page.dart`**: `AppScaffold`, `AppSpacing` on main gutters and inner chips, root `ListView` uses scroll physics for consistent overscroll/pull behavior. **Router pushes unchanged.**

**Still deferred**: `trip_tracking_page` map + bottom-sheet chrome (align with helper active booking), `booking_details_page` and other instant/scheduled subflows — next slice when ready.

