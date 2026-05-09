# Map + tracking UI phase audit (May 2026)

## Scope

- Traveler: trip_tracking_page.dart — aligned with helper active booking map chrome.
- Helper: active_booking_page.dart, ActiveTrackingSheet in active_booking_components.dart.
- Handoff: booking_details_page.dart — AppScaffold + AppSnackbar + AppSpacing padding.

## Routes / safe deletions

- No route or page removals. Tracking remains on existing GoRouter paths; hub subscriptions unchanged.

## Presentation changes (contract preserved)

### New core module

- lib/core/widgets/map_tracking_chrome.dart — MapRouteInfoChip, MapFloatingGlassButton (light/dark tones), MapTrackingDragHandle, MapTrackingSheetSurface, MapTrackingLayout (floating action inset + responsive TrackingSheetExtents).

### Trip tracking

- Rebuild scope: ValueNotifier for live location + ValueListenableBuilder in sheet; BlocSelector on BookingDetail? for map subtree; route chip and SOS in outer Stack.
- Chrome: shared chips, glass buttons, sheet surface; AppSnackbar for dialer/SOS.
- Responsive sheet fractions via shortestSide breakpoints.

### Helper active booking

- Shared MapRouteInfoChip and MapFloatingGlassButton (dark); RepaintBoundary on map; SOS offset tied to helperSheetExtents.
- ActiveTrackingSheet uses MapTrackingSheetSurface, MapTrackingDragHandle, AppColors/AppSpacing on summary card.

### Booking details

- AppScaffold; cancel flow uses AppSnackbar; sliver padding tokens.

## Not changed

- APIs, repositories, Cubit/Bloc logic, Mapbox Directions, SignalR contracts, navigation targets.

## Follow-ups

- Migrate remaining BrandTokens in helper stat rows and route panels.
- Optional: Mapbox cameraOptions to viewport when upgrading plugin.
- Auth and profile polish per roadmap.