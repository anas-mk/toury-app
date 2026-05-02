# RAFIQ Mobile (Flutter) — Booking & Real-Time Integration Guide

> **Audience:** Flutter developer integrating the RAFIQ user/helper mobile apps with the backend.
> **Assumed knowledge:** REST + JSON. **No prior SignalR / WebSocket experience required.**
> **Scope:** Booking lifecycle, chat, live trip tracking, payment, ratings, invoices, SOS, reports, push notifications.
> **Out of scope:** Authentication / OTP — you already implemented that side. All endpoints below assume you already have a valid JWT for the signed-in user or helper.

---

## Table of Contents

1. [The Big Picture](#1-the-big-picture)
2. [SignalR 101 — What You Need to Know](#2-signalr-101--what-you-need-to-know)
3. [One-Time Setup](#3-one-time-setup)
4. [Connecting to the Booking Hub](#4-connecting-to-the-booking-hub)
5. [Booking Business Logic](#5-booking-business-logic)
   - 5.3 [Service areas vs. live GPS](#53-service-areas-scheduled-vs-live-gps-instant)
   - 5.4 [Helper service areas — map picker UX](#54-how-the-helper-manages-service-areas-map-picker-ux)
   - 5.5 [Helper prerequisites to receive bookings](#55-helper-prerequisites-to-receive-any-booking)
   - 5.6 [Toggling availability](#56-toggling-availability-from-the-helper-app)
   - 5.7 [Keeping the helper's GPS alive](#57-keeping-the-helpers-gps-alive-critical-for-instant)
   - 5.8 [User-side pickup picker on a map](#58-how-the-user-picks-pickup-on-a-map)
6. [Booking Lifecycle States](#6-booking-lifecycle-states)
7. [Scheduled Booking — End-to-End Flow](#7-scheduled-booking--end-to-end-flow)
8. [Instant Booking — End-to-End Flow](#8-instant-booking--end-to-end-flow)
9. [Chat](#9-chat)
10. [Live Trip Tracking & GPS Streaming](#10-live-trip-tracking--gps-streaming)
11. [Payment (Mock Gateway for Now)](#11-payment-mock-gateway-for-now)
12. [Ending the Trip, Ratings & Invoices](#12-ending-the-trip-ratings--invoices)
13. [SOS (Panic Button)](#13-sos-panic-button)
14. [Reports (Complaints)](#14-reports-complaints)
15. [Push Notifications (FCM)](#15-push-notifications-fcm)
16. [Full Server → Client Event Catalog](#16-full-server--client-event-catalog)
17. [Common Pitfalls — Do / Don't](#17-common-pitfalls--do--dont)
18. [Quick Checklist](#18-quick-checklist)

---

## 1. The Big Picture

The app talks to the backend over **two channels** that work together:

| Channel | Purpose | Example |
|---------|---------|---------|
| **REST (HTTPS)** | Create / read / update / delete. Authoritative source of truth. Use on app launch and whenever you need the "current state". | `POST /api/user/bookings/scheduled`, `GET /api/user/bookings/{id}` |
| **SignalR hub** (`/hubs/booking`) | Real-time push from server → app. Keeps the UI in sync while the app is open, without polling. | "Your booking was accepted", "helper is 3 km away", "new chat message" |

**Rule of thumb:**

- **Did the user tap a button?** → REST call.
- **Did something happen in the background that the UI needs to reflect?** → Listen to a SignalR event.
- **Is your local state unsure (reconnect, app resumed from background, deep-link)?** → REST re-fetch is the source of truth. Never trust only the hub for state.

Both channels use the **same JWT** you already obtained during login.

---

## 2. SignalR 101 — What You Need to Know

SignalR is Microsoft's real-time library. Think of it as a persistent WebSocket connection with two super-powers:

1. **Server pushes events to you.** You register a handler with a **method name string** (e.g. `"BookingStatusChanged"`) and the server's payload is delivered to that handler as JSON-deserialized arguments.
2. **You can call methods on the server** over the same connection (e.g. `SendLocation(lat, lng, …)`).

**Mental model:**
- You open **one** connection per app session, after login.
- You register **all** the event handlers you care about **before** you start the connection.
- You keep the connection alive for the whole session; on reconnect, **you must re-fetch state from REST** because any events fired while you were disconnected are lost.

### Flutter package

Use `signalr_netcore` — the most actively maintained SignalR client for Dart.

```yaml
# pubspec.yaml
dependencies:
  signalr_netcore: ^1.4.0
  logging: ^1.2.0
```

> Do **not** use raw `web_socket_channel` — SignalR has its own framing/handshake protocol. You must use a SignalR client library.

---

## 3. One-Time Setup

### 3.1 Base URLs

| Environment | Base URL |
|-------------|----------|
| **Deployed (use this)** | `https://tourestaapi.runasp.net` |
| Local dev | `http://10.0.2.2:5107` (Android emulator) / `http://localhost:5107` (iOS simulator) |

Swagger UI for the deployed build: [https://tourestaapi.runasp.net/swagger/index.html](https://tourestaapi.runasp.net/swagger/index.html)

**SignalR hub URL on the deployed build:**
```
https://tourestaapi.runasp.net/hubs/booking?access_token={JWT}
```

> The deployment runs on **HTTPS**. Use `https://` for REST and `wss://` is handled automatically by the SignalR client when the base URL is `https://`. Do **not** mix `http` and `https` — Android/iOS will block mixed content.

### 3.2 REST: attach the JWT on every request

```dart
final dio = Dio(BaseOptions(
  baseUrl: API_BASE_URL,
  headers: {'Accept': 'application/json'},
));
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (opts, handler) {
    final jwt = authStore.currentJwt; // your existing token store
    if (jwt != null) opts.headers['Authorization'] = 'Bearer $jwt';
    handler.next(opts);
  },
));
```

### 3.3 Response envelope

Every JSON response from the backend is wrapped:

```json
{
  "success": true,
  "message": "Booking created successfully.",
  "data": { /* payload */ }
}
```

On error:

```json
{
  "success": false,
  "message": "Helper is not available for that time slot.",
  "error": "ValidationException"
}
```

Always read `data` (for success) or `message` (for display). Http status codes are meaningful: `200` OK, `400` validation error, `401` expired token, `403` forbidden, `404` not found, `500` server error.

---

## 4. Connecting to the Booking Hub

This is the core piece. **Every** real-time feature (booking updates, chat, live GPS, SOS, reports, ratings) flows through **one connection** to `/hubs/booking`.

### 4.1 Connection URL

```
{API_BASE_URL}/hubs/booking?access_token={JWT}
```

Deployed:
```
https://tourestaapi.runasp.net/hubs/booking?access_token={JWT}
```

The backend reads two claims from the JWT:
- `type` must be `"user"` or `"helper"`.
- `id` is the current principal id.

If the JWT is missing, expired, or has the wrong `type`, the server **aborts the connection immediately**. You'll see a disconnected state with an auth error — re-login and retry.

### 4.2 Minimal wire-up (Dart)

```dart
import 'package:signalr_netcore/signalr_client.dart';

class RafiqHub {
  HubConnection? _conn;
  final String baseUrl;
  final Future<String> Function() accessTokenFactory;

  RafiqHub(this.baseUrl, this.accessTokenFactory);

  Future<void> start() async {
    _conn = HubConnectionBuilder()
      .withUrl(
        '$baseUrl/hubs/booking',
        options: HttpConnectionOptions(
          accessTokenFactory: accessTokenFactory,
          // keep the default WebSockets transport
        ),
      )
      .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 30000])
      .build();

    // 1) Register EVERY handler BEFORE start()
    _registerBookingHandlers();
    _registerChatHandler();
    _registerTrackingHandler();
    _registerSosHandlers();
    _registerReportHandlers();
    _registerHelperLifecycleHandlers(); // helper app only

    // 2) On reconnect → re-fetch authoritative state (see §17).
    _conn!.onreconnected(({connectionId}) async {
      await appState.rehydrateFromRest();
    });

    // 3) Go live
    await _conn!.start();
  }

  Future<void> stop() => _conn?.stop() ?? Future.value();
}
```

**Call `start()` exactly once**, right after a successful login. Do **not** open a new connection per screen.

### 4.3 What happens server-side when you connect

- The server adds you to your personal group: `user:{userId}` or `helper:{helperId}`.
- It auto-joins you to every **active** booking room you participate in (`booking:{bookingId}`). You do **not** need to call a "JoinBooking" method — the server handles it.
- When a booking becomes active later (e.g. you just accepted a new one), the server adds you to that booking's room automatically.

> There is **no** client-invokable `JoinBooking` method. Don't try to call it — the server will reject the call.

### 4.4 Client → server methods (what you can invoke)

Only **two** methods are callable by clients:

| Method | Who calls it | Purpose |
|--------|--------------|---------|
| `Ping()` | Anyone | Diagnostic round-trip. Server responds with `Pong(serverTimestampMs)`. Useful for latency metrics. |
| `SendLocation(latitude, longitude, heading, speedKmh, accuracyMeters)` | **Helper app only** | Streams live GPS position over the existing connection. See §10. |

Everything else is **server → client**, registered with `connection.on("MethodName", handler)`.

---

## 5. Booking Business Logic

RAFIQ has two booking flavors driven by a single enum `BookingType`:

| Type | When to use | Payment timing | Matching |
|------|-------------|----------------|----------|
| **Scheduled** | Pre-planned trip, picks a specific helper for a future date/time. | **Before** trip starts (on acceptance). | User picks the helper explicitly from search results. |
| **Instant** | Uber-style, right now. | **After** trip ends. | User either picks a helper from search OR lets the system auto-pick the top candidate. |

### 5.1 Pricing

Price is computed server-side at booking creation time and returned in `BookingDetailResponse.estimatedPrice` + `priceBreakdown`. Formula (simplified):

```
distanceCost       = distanceKm * pricePerKm
durationCost       = (durationInMinutes / 60) * helperHourlyRate
subtotal           = basePrice + distanceCost + durationCost
instantSurcharge   = subtotal * instantSurchargePercentage   (Instant only)
total              = max(minimumTripPrice, subtotal + instantSurcharge)
```

- `distanceKm` priority ladder:
  1. If **you** send `distanceKm` in the request AND it's within `[haversine, haversine × 3]` → use your value.
  2. If your `distanceKm` is out of range → clamp to that window.
  3. If you didn't send `distanceKm` but sent both pickup + destination coordinates → use Haversine.
  4. No coordinates → distance cost = 0.
- You **should** send `distanceKm` from your Google Directions response when available — it's more accurate than straight-line Haversine.

### 5.2 Helper availability

A helper has an `availabilityState` that gates which bookings they can receive:

| State | Instant search | Scheduled search |
|-------|----------------|------------------|
| `Offline` | ❌ | ❌ |
| `AvailableNow` | ✅ (if location is fresh ≤ 10 min) | ✅ |
| `ScheduledOnly` | ❌ | ✅ |
| `Busy` | ❌ (on a trip) | ❌ |

`Busy` is set **automatically** by the backend when a helper starts a trip, and flipped back to `AvailableNow` when the trip ends. Helpers only manually choose between `Offline` / `AvailableNow` / `ScheduledOnly`.

### 5.3 Service areas (scheduled) vs. live GPS (instant)

Two **completely different** mechanisms gate whether a helper shows up in a search — don't mix them up:

| | Scheduled matching | Instant matching |
|---|---|---|
| **What the backend matches against** | The **city** in `DestinationCity` | The helper's **live GPS** (`CurrentLatitude/Longitude`) within `DefaultRadiusKm` of the user's pickup |
| **What the helper has to configure** | At least one **service area** (row in `HelperServiceAreas`) | Keep their GPS fresh (≤ 10 min) and stay `AvailableNow` |
| **Required fields** | `country`, `city`, (optional `areaName`), `latitude`, `longitude`, `radiusKm`, `isPrimary` | — |
| **Helper endpoint** | `/api/helper/service-areas` (GET / POST / PUT / DELETE) | `/api/helper/location/update` (HTTP) or `SendLocation` over SignalR |

So:
- **No service area** → helper is invisible to **scheduled** searches (but can still get instant requests).
- **App closed / stale GPS** → helper is invisible to **instant** searches (but can still get scheduled requests).

### 5.4 How the helper manages service areas (map picker UX)

The helper **never types lat/lng manually**. Build a map screen like this:

1. Show Google Maps centered on the helper's current city.
2. Let the helper **tap** to drop a center pin (or hold → drag).
3. Show a **circle overlay** whose radius follows a slider (e.g. 5 → 100 km, default 25).
4. Auto-fill `city` / `country` from a **reverse geocode** on the dropped pin (use `geocoding` Flutter package with a fallback to a text field if reverse geocode fails).
5. Submit:

```http
POST /api/helper/service-areas
```
Body — `ServiceAreaRequest`:
```json
{
  "country": "Egypt",
  "city": "Cairo",
  "areaName": "Downtown",     // optional, purely for display
  "latitude": 30.0444,
  "longitude": 31.2357,
  "radiusKm": 25,
  "isPrimary": true
}
```

**Rules the helper UI must enforce:**

- **At least one service area** before the helper can be approved / receive scheduled requests. Block the "Submit for review" CTA until `GET /api/helper/service-areas` returns ≥ 1 row.
- **Only one primary** area per helper. If the helper marks a new area primary, the backend auto-demotes the old one — you just refresh the list after the call.
- **No duplicates** on the same `(city, areaName)` pair — the backend rejects with 400. Pre-validate locally for a nicer UX.
- **Deleting the last area** is allowed but shows a warning: "you will no longer appear in scheduled searches". The backend explicitly returns that message.

Other endpoints:
```
GET    /api/helper/service-areas          # list
PUT    /api/helper/service-areas/{id}     # update (same body)
DELETE /api/helper/service-areas/{id}
```

### 5.5 Helper prerequisites to receive ANY booking

For the helper to be matchable at all, **all** of the following must be true at search time:

| Gate | How the helper app maintains it |
|------|------------------------------------|
| `IsApproved = true` | Admin-controlled after onboarding. Helper just waits. |
| `IsActive = true`, not banned, not suspended | Admin-controlled. The helper app receives `HelperApprovalChanged` / `HelperBanStatusChanged` / `HelperSuspensionChanged` if any of this flips. |
| `AvailabilityState = AvailableNow` (for instant) or `AvailableNow`/`ScheduledOnly` (for scheduled) | Helper toggles this in-app — see §5.6. |
| **At least one service area** | See §5.4. |
| **Fresh live GPS** (≤ 10 min old) — **instant only** | App must keep the location stream running while foreground AND keep it alive in the background while `AvailableNow`. See §5.7. |
| Language / car match | Filled on the helper profile (languages list) and car documents. |

If an instant search returns 0 helpers and you're testing with a specific helper account, call this diagnostic as that helper:

```http
GET /api/helper/location/instant-eligibility?pickupLatitude=30.04&pickupLongitude=31.23&requestedLanguage=en&requiresCar=false
```

It returns a checklist of every gate with pass/fail + a human-readable reason (e.g. `"Location is stale (updated 42 minutes ago, threshold is 10 minutes)"`).

### 5.6 Toggling availability from the helper app

```http
POST /api/helper/bookings/availability
```
Body:
```json
{ "availabilityState": "AvailableNow" }
```

Allowed values: `"Offline"`, `"AvailableNow"`, `"ScheduledOnly"`. `"Busy"` is set **by the backend only** when a trip starts — don't send it manually.

When the helper toggles, the backend pushes `HelperAvailabilityChanged` to the helper's own connection so any other device they're logged in on stays in sync. Listen for it and sync the toggle UI.

### 5.7 Keeping the helper's GPS alive (critical for Instant)

To receive instant requests, the helper app **must** be sending fresh location samples. Two things matter:

**Foreground behavior:**
- Use `geolocator` or `location` Flutter packages.
- Start the stream on login (once availability ≠ Offline) and push samples via `hub.invoke('SendLocation', [...])`.

**Background behavior (the hard part):**
Mobile OSes aggressively kill background location. To stay eligible in instant searches while the app is backgrounded, you need a **foreground service** (Android) and **"Always" location permission** (iOS).

- **Android:** use `flutter_background_geolocation` or a custom foreground service. Keep a persistent notification so Android doesn't kill you. Your service calls `POST /api/helper/location/update` every ~30 s (safe HTTP fallback — the SignalR connection may be paused by Doze).
- **iOS:** request `Always` location authorization + enable the "Location updates" background mode in the Xcode capabilities. Use `locationManager.allowsBackgroundLocationUpdates = true`.

**UX contract for the helper:**
On the availability toggle screen, if the helper picks `AvailableNow` but background-location permission isn't granted, show a permission prompt with a clear message:

> "To receive instant requests while the app is minimized, RAFIQ needs permission to track your location in the background. Without this, you will only appear online for ~10 minutes at a time before disappearing from searches."

**Battery disclosure:** Android 12+ and iOS require you to disclose that your app uses location continuously. Add a line to the Play Store listing / App Store description.

**Recommended cadence from the helper app:**

| Situation | Cadence |
|---|---|
| Foreground, `AvailableNow`, not on a trip | `SendLocation` every 10–30 s (server throttles anyway). |
| Foreground, `InProgress` trip | As fast as the OS emits (e.g. every 2–5 s). Server broadcasts to the user live. |
| Background, `AvailableNow` | `POST /api/helper/location/update` every ~30 s from a foreground-service worker. |
| Helper turned Offline or logged out | **Stop** all streams. Cancel the foreground service. |

### 5.8 How the user picks pickup on a map

The user **never types coordinates either**. Build a pickup-picker like:

1. Full-screen Google Maps with a center pin (the pin stays fixed; the map moves under it — standard Uber-style).
2. Optional search bar that uses Google Places Autocomplete.
3. When the map stops panning, reverse-geocode the center → fill the address field. You send **both** to the backend:
   - `pickupLocationName`: the reverse-geocoded/typed label (shown to the helper).
   - `pickupLatitude` / `pickupLongitude`: the map center.
4. For **scheduled** bookings with `MeetingPointType = Hotel` / `Airport`, let the user pick from a dropdown of popular hotels/terminals you preload, or just tap their hotel on the map.
5. When the user also picks a destination (required for instant, optional for scheduled), compute the route with Google Directions and pass the resulting **distance in km** as `distanceKm` — this improves pricing accuracy vs. straight-line Haversine (see §5.1).

---

## 6. Booking Lifecycle States

Serialized as **string names** everywhere (both REST responses and SignalR events).

```
                    ┌─────────────────────────┐
                    │   PendingHelperResponse │ ← created
                    └────────┬────────────────┘
           decline/timeout   │   accept
           ┌─────────────────┤
           ▼                 ▼
    DeclinedByHelper     AcceptedByHelper
    ExpiredNoResponse          │
           │                   │ (if Scheduled)
           ▼                   ▼
   ReassignmentInProgress  ConfirmedAwaitingPayment
           │                   │ pay
           ▼                   ▼
    WaitingForUserAction   ConfirmedPaid
                               │
                               ▼ start-window
                            Upcoming
                               │ helper taps Start
                               ▼
                           InProgress
                               │ helper taps End
                               ▼
                           Completed
```

`CancelledByUser`, `CancelledByHelper`, `CancelledBySystem` can happen from most of the above.

**For Instant bookings**, after `AcceptedByHelper` we skip the payment states and go straight into `Upcoming → InProgress → Completed`. Payment is captured after `Completed`.

---

## 7. Scheduled Booking — End-to-End Flow

Everything numbered here happens in the user app **unless stated**.

### 7.1 Search helpers

```
POST /api/user/bookings/scheduled/search
```

Body: `ScheduledSearchRequest` (destination city, date, time, duration, language, car). Response: `List<HelperSearchResult>` with `helperId`, `fullName`, `profileImageUrl`, `rating`, `completedTrips`, `estimatedPrice`.

### 7.2 View a helper's profile

```
GET /api/user/bookings/helpers/{helperId}/profile
```

### 7.3 Create the booking

```
POST /api/user/bookings/scheduled
```

Body: `CreateScheduledBookingRequest` (see §5.1 for pricing fields). Response: `BookingDetailResponse` with `bookingId` and `status = "PendingHelperResponse"`.

The server now pushes a `RequestIncoming` event to the helper app. **The helper has ~24 hours (configurable) to respond.** While waiting, listen on the hub:

```dart
connection.on('BookingStatusChanged', (args) {
  final evt = args!.first as Map; // BookingStatusChangedEvent
  if (evt['bookingId'] == currentBookingId) {
    // evt['newStatus'] = "AcceptedByHelper" | "DeclinedByHelper" | "ExpiredNoResponse" | ...
    bookingStore.setStatus(evt['newStatus']);
  }
});
```

### 7.4 Helper accepts / declines

- **On the helper app:**

  ```
  GET  /api/helper/bookings/requests                       # list incoming
  GET  /api/helper/bookings/requests/{bookingId}           # detail
  POST /api/helper/bookings/requests/{bookingId}/accept    # accept
  POST /api/helper/bookings/requests/{bookingId}/decline   # decline (optional reason)
  ```

- On **accept**, the user receives `BookingStatusChanged` → `newStatus = "AcceptedByHelper"`. Move the user's UI into the "confirmed pending payment" state.

### 7.5 User pays (scheduled only)

After acceptance, `paymentStatus` = `"AwaitingPayment"`. See §11 for the full payment flow. When the payment succeeds the booking moves to `ConfirmedPaid → Upcoming`.

### 7.6 Trip day

When the trip start time approaches, the backend moves status to `Upcoming`. Both sides can see the upcoming trip:

- User: `GET /api/user/bookings/{bookingId}`
- Helper: `GET /api/helper/bookings/active` (the active one), or `GET /api/helper/bookings/upcoming` (list).

### 7.7 Helper starts trip

```
POST /api/helper/bookings/{bookingId}/start
```

Server pushes `BookingTripStarted` to `booking:{BookingId}` — **both** apps receive it. Move UI into "trip in progress" mode, open map, subscribe to `HelperLocationUpdate`.

### 7.8 Helper ends trip

```
POST /api/helper/bookings/{bookingId}/end
```

Server pushes `BookingTripEnded` (with `finalPrice` + `paymentStatus`). Status = `Completed`. Helper's availability flips back to `AvailableNow`.

### 7.9 Both rate each other

See §12.

---

## 8. Instant Booking — End-to-End Flow

### 8.1 (Helper app) Keep the helper's location fresh

This is **critical**. A helper is only eligible for instant matching if their `CurrentLocationUpdatedAt` is **within 10 minutes**. The helper app has two ways to update it (pick one, don't do both):

**Option A — HTTP fallback (simple, every 30s):**
```
POST /api/helper/location/update
```
Body: `UpdateLocationRequest` (`latitude`, `longitude`, `heading?`, `speedKmh?`, `accuracyMeters?`).

**Option B — SignalR stream (preferred while online):**
```dart
await hub.invoke('SendLocation', args: [lat, lng, heading, speedKmh, accuracyMeters]);
```

> **Recommendation:** the helper app should call `SendLocation` on the hub whenever the OS emits a location sample while the helper is `AvailableNow`. The server throttles (min 10 s / min 20 m) before persisting and broadcasting. If the WebSocket is down, fall back to `POST /api/helper/location/update`.

If instant search returns 0 helpers, call the diagnostic endpoint to see exactly which gate failed:
```
GET /api/helper/location/instant-eligibility?pickupLatitude=...&pickupLongitude=...&requestedLanguage=...&requiresCar=false
```

### 8.2 (User app) Search for nearby helpers

```
POST /api/user/bookings/instant/search
```
Body: `InstantSearchRequest` (pickup lat/lng, duration, optional language, optional `requiresCar`). Response: ranked list of nearby, available helpers with estimated price.

### 8.3 Create the instant booking

```
POST /api/user/bookings/instant
```
Body: `CreateInstantBookingRequest`. Notice:
- `helperId` is **optional** — if null, the system auto-picks the top candidate.
- Payment is **not** collected here.

Response: `BookingDetailResponse`, usually in `PendingHelperResponse`.

### 8.4 Wait for helper accept

Same as §7.3 — listen to `BookingStatusChanged`. The instant flow uses a **shorter timeout** (5 minutes by default). If the assigned helper doesn't respond, the backend reassigns up to 3 times; if still no match the booking moves to `WaitingForUserAction` and the app should show alternatives:

```
GET /api/user/bookings/{bookingId}/alternatives
```

### 8.5 Trip happens (no payment step here)

After accept → `AcceptedByHelper`. Helper hits `/start` → `InProgress`, then `/end` → `Completed`. No scheduled payment step in between.

### 8.6 User pays AFTER the trip

When `BookingTripEnded` arrives, `paymentStatus = "AwaitingPayment"`. Route to the payment screen. See §11.

### 8.7 Both rate each other

See §12.

---

## 9. Chat

Chat is a mix of REST (history, send, read) + SignalR (live delivery).

### 9.1 REST endpoints

User app:
```
GET  /api/user/bookings/{bookingId}/chat/messages?page=1&pageSize=50&before=2026-04-20T10:00:00Z
POST /api/user/bookings/{bookingId}/chat/messages            # body: SendMessageRequest { text, messageType? }
POST /api/user/bookings/{bookingId}/chat/read                # mark all as read
```

Helper app: identical routes under `/api/helper/bookings/{bookingId}/chat/…`.

### 9.2 When chat is available

Chat opens automatically once the booking reaches `AcceptedByHelper` and stays open through `Completed`. Before acceptance, chat endpoints return `403`. The `BookingDetailResponse.chatEnabled` flag tells you when to show the chat tab.

### 9.3 Live incoming messages (SignalR)

Register one handler:

```dart
connection.on('ChatMessage', (args) {
  final evt = args!.first as Map; // ChatMessageEvent
  // evt fields: bookingId, conversationId, messageId, senderId, senderType,
  //             senderName, recipientId, recipientType, messageType, preview, sentAt
  if (evt['recipientId'] == currentUserId) {
    chatStore.pushIncoming(evt);
  }
});
```

**Important:**
- The sender **never** receives a `ChatMessage` echo for their own message. The `POST /messages` response carries the persisted row — use that to append to the local conversation.
- `preview` is truncated to 100 chars. For the full text, show the one you just sent (sender side) or re-fetch messages (recipient side, if needed).
- If the recipient is **offline** (no hub connection), the event is also delivered as an FCM push (§15) — no action needed on your side except handling the push.

---

## 10. Live Trip Tracking & GPS Streaming

Only active during `InProgress`. Both parties see the helper's live position on a map.

### 10.1 Helper app — send GPS

While the booking is `InProgress`, the helper app streams the device's GPS over the hub:

```dart
locationStream.listen((pos) {
  hub.invoke('SendLocation', args: [
    pos.latitude, pos.longitude,
    pos.heading, pos.speedKmh, pos.accuracyMeters,
  ]);
});
```

You can send samples at whatever rate the OS emits them (e.g. every 1 s). The server applies server-side throttling before broadcasting: **min 10 seconds** between samples **OR** **min 20 meters** moved (configurable). This prevents battery drain on the user app.

> The helper only needs to stream while `AvailableNow` (for instant eligibility) or while `InProgress` (for live tracking). When offline or between trips, stop the stream.

### 10.2 User + helper app — receive GPS

```dart
connection.on('HelperLocationUpdate', (args) {
  final evt = args!.first as Map; // HelperLocationUpdateEvent
  if (evt['bookingId'] != currentBookingId) return;
  mapStore.movePin(
    lat: evt['latitude'],
    lng: evt['longitude'],
    heading: evt['heading'],
    capturedAt: DateTime.parse(evt['capturedAt']),
  );
  etaStore.update(
    toPickupMin: evt['etaToPickupMinutes'],
    toDestMin: evt['etaToDestinationMinutes'],
  );
});
```

### 10.3 On reconnect — prime the map

When the app resumes or the hub reconnects, the user app has no idea where the helper currently is. Re-fetch the latest known position before re-opening the stream:

```
GET /api/booking/{bookingId}/tracking/latest
```

For a post-trip replay / polyline:
```
GET /api/booking/{bookingId}/tracking/history
```

Only booking participants (the user or the engaged helper) can read tracking.

---

## 11. Payment (Mock Gateway for Now)

We use a **mock gateway** today. The real gateway (Stripe / Paymob) plugs in later without changing your contract.

### 11.1 When to pay

| Booking type | When |
|---|---|
| Scheduled | Right after the helper accepts (`status = AcceptedByHelper`, `paymentStatus = AwaitingPayment`). |
| Instant | After the trip ends (`status = Completed`, `paymentStatus = AwaitingPayment`). |

### 11.2 Start the payment

```
POST /api/payments/booking/{bookingId}/initiate
```
Body: `InitiatePaymentRequest { method: "Cash" | "MockCard" }`

Response: `InitiatePaymentResponse`:
- `paymentId`, `bookingId`, `amount`, `currency`, `method`, `status`
- `paymentUrl` — absolute URL. **Only non-null for `MockCard`.**

### 11.3 Cash flow

Status returned is already `Paid`. No webview. Just show "Payment confirmed, helper will collect cash in person".

### 11.4 MockCard flow

Open `paymentUrl` in a webview (`flutter_inappwebview`) or external browser. The mock page shows four buttons: **Succeed / Insufficient funds / Network error / Cancel**. When the user taps one, the page POSTs to `/api/payments/mock/{paymentId}/complete` — you do **not** need to call this yourself.

The result comes back over SignalR:

```dart
connection.on('BookingPaymentChanged', (args) {
  final evt = args!.first as Map;
  // evt['status'] = "Paid" | "Failed" | "Refunded"
  // evt['failureReason'] carries a machine tag if Failed
  paymentStore.update(evt);
});
```

**Close the webview and route based on the event.** Never rely on webview URL sniffing alone — the SignalR event is the source of truth.

> When the webview user just closes the sheet without tapping anything, the payment stays `PaymentPending`. Poll `GET /api/payments/{paymentId}` or `GET /api/payments/booking/{bookingId}/latest` when your app regains focus, and use that to reconcile.

### 11.5 Status enum reference

```
NotRequired | AwaitingPayment | PaymentPending | Paid | Failed | Refunded
```

Refunds are admin-initiated for now; user just receives `BookingPaymentChanged` with `status = "Refunded"` and a `refundedAmount`.

---

## 12. Ending the Trip, Ratings & Invoices

### 12.1 After `BookingTripEnded`

Show both apps a "Leave a rating" prompt.

### 12.2 Submit rating

User → Helper:
```
POST /api/ratings/booking/{bookingId}/helper
```
Helper → User:
```
POST /api/helper/ratings/booking/{bookingId}/user
```
Body: `SubmitRatingRequest { stars (1-5), comment?, tags? }`.

### 12.3 Has-rated state

```
GET /api/ratings/booking/{bookingId}              # user
GET /api/helper/ratings/booking/{bookingId}       # helper
```
Both return `BookingRatingStateResponse` — use `callerHasRated` to hide the CTA once submitted, and `canRate` to know if the booking is in a state that accepts ratings.

### 12.4 Invoice

A receipt is auto-issued on trip completion.

User: `GET /api/invoices/booking/{bookingId}` → `InvoiceDetailResponse`.
Helper: `GET /api/helper/invoices/booking/{bookingId}` → same DTO (commission split included).
HTML view (handy for share-sheet): `GET /api/invoices/{invoiceId}/view` and `GET /api/helper/invoices/{invoiceId}/view`.

---

## 13. SOS (Panic Button)

Panic button displayed while `InProgress`. Either party can trigger it.

### 13.1 Trigger

User app:
```
POST /api/sos/bookings/{bookingId}
```
Helper app:
```
POST /api/helper/sos/bookings/{bookingId}
```
Body: `TriggerSosRequest { reason?, note?, latitude?, longitude? }`.

**Always send the best-known GPS** — admins use it to dispatch response. If you omit it, the server falls back to the last tracking point, which can be stale.

### 13.2 Hub events

The counterparty on the booking receives:
```dart
connection.on('SosTriggered', (args) {
  // evt: sosId, bookingId, triggeredByType, triggeredById, recipientType, recipientId, reason
  // Show a "SOS active — support is engaged" banner. Do NOT leave the scene.
});
```

The triggerer (the one who pressed the button) receives the resolution later:
```dart
connection.on('SosResolved', (args) {
  // evt: sosId, bookingId, triggeredByType, triggeredById, finalStatus, resolutionNote, resolutionAction
  // finalStatus = "Handled" | "FalseAlarm" | "Cancelled"
  // Close the "SOS active" UI and show the outcome.
});
```

### 13.3 Cancel their own SOS (before admin acts)

```
PATCH /api/sos/{id}/cancel                   # user
PATCH /api/helper/sos/{id}/cancel            # helper
```

### 13.4 History

```
GET /api/sos/mine                            # user
GET /api/helper/sos/mine                     # helper
GET /api/sos/mine/{id}                       # detail
```

---

## 14. Reports (Complaints)

Non-urgent complaints against the other party. Can be tied to a specific booking or out-of-booking.

### 14.1 Submit

User → Helper:
```
POST /api/reports
```
Helper → User:
```
POST /api/helper/reports
```
Body: `CreateReportRequest { bookingId? OR targetId, reason, details?, evidence?[] }`.

Either supply `bookingId` (preferred — the target is derived automatically) **or** `targetId` (for out-of-booking complaints).

### 14.2 Resolution event

Admin triages the report. When they mark it `Resolved` or `Dismissed`, the **reporter** receives:

```dart
connection.on('ReportResolved', (args) {
  // evt: reportId, direction, recipientType, recipientId, finalStatus, resolutionNote, resolutionAction
  // finalStatus = "Resolved" | "Dismissed"
});
```

> The legacy `HelperReportResolved` event is still emitted for user-reported helpers but should be treated as an alias of `ReportResolved` — prefer the unified handler.

### 14.3 History

```
GET /api/reports/mine                        # user
GET /api/helper/reports/mine                 # helper
```

---

## 15. Push Notifications (FCM)

Push is how the user learns about events when the app is **not connected** to the hub (backgrounded, killed, no internet for a moment).

### 15.1 Register the device token

Call this every time FCM gives you a fresh token (on app start + on `onTokenRefresh`):

```
POST /api/notifications/devices
```
Body: `RegisterDeviceTokenRequest`:
```json
{
  "fcmToken": "dHj6…XYZ",
  "deviceId": "a1b2c3d4-stable-install-id",   // Android ID hash / iOS IDFV
  "appType": "UserApp",                        // or "HelperApp"
  "platform": "Android",                       // or "iOS" / "Web"
  "appVersion": "1.0.0+1"
}
```

**Rules:**
- `appType` must match the JWT role. Registering `HelperApp` from a user JWT is rejected.
- `deviceId` is the idempotency key — same device + appType → row updated in place (no duplicates).
- On logout: `DELETE /api/notifications/devices/all` (clears all tokens for this account) — skip this if the user just kills the app, only do it on explicit logout.

### 15.2 What triggers a push

The backend fans-out to **both** channels for most events:

| Event | Hub group | FCM |
|-------|-----------|-----|
| Booking lifecycle (status, cancelled, payment, trip-started / ended) | ✅ | ✅ |
| Helper availability / dashboard | ✅ | ❌ (not useful when app is closed) |
| Live helper location | ✅ | ❌ (too chatty for push) |
| Chat message | ✅ | ✅ (only if recipient is offline) |
| SOS triggered / resolved | ✅ | ✅ |
| Report resolved | ✅ | ✅ |
| Helper approval / ban / suspension / drug-test expiry | ✅ | ✅ |
| Interview decision | ✅ | ✅ |

### 15.3 Avoiding double-notifications

If your app is connected to the hub **and** receives an FCM push for the same event, show the UI effect only **once**. Strategy: every event carries an `eventId` — keep a small ring buffer of seen ids (last 200) and dedupe.

---

## 16. Full Server → Client Event Catalog

All method names are case-sensitive. Every event carries an envelope `{ eventId, occurredAt, v, ... }` — show the payload-specific fields below to the UI.

### 16.1 Booking & trip

| Method | Audience | Key fields |
|--------|----------|-----------|
| `RequestIncoming` | Helper | bookingId, userId, travelerName, destinationCity, requestedDate, startTime, durationInMinutes, requestedLanguage, requiresCar, travelersCount, estimatedPayout, responseDeadline |
| `RequestRemoved` | Helper | bookingId, reason (`AcceptedByOther` / `Expired` / `CancelledByUser` / `CancelledBySystem` / `Reassigned` / `Declined`) |
| `BookingStatusChanged` | User + Helper | bookingId, userId, helperId?, oldStatus, newStatus, paymentStatus? |
| `BookingCancelled` | User + Helper + booking room | bookingId, cancelledBy (`User` / `Helper` / `System`), reason? |
| `BookingPaymentChanged` | User + Helper | bookingId, paymentId, amount, currency, method, status, failureReason?, refundedAmount? |
| `BookingTripStarted` | Booking room | bookingId, userId, helperId, startedAt |
| `BookingTripEnded` | Booking room | bookingId, userId, helperId, completedAt, finalPrice?, paymentStatus |
| `HelperLocationUpdate` | Booking room | bookingId, helperId, latitude, longitude, heading?, speedKmh?, capturedAt, distanceToPickupKm?, etaToPickupMinutes?, distanceToDestinationKm?, etaToDestinationMinutes?, phase |

### 16.2 Helper-facing lifecycle

| Method | Key fields |
|--------|-----------|
| `HelperDashboardChanged` | helperId, pendingRequestsDelta, upcomingTripsDelta, completedTripsDelta, todayEarningsDelta, bookingId? |
| `HelperAvailabilityChanged` | helperId, availabilityState, isOnline |
| `HelperApprovalChanged` | helperId, newApprovalStatus (`Approved`/`Rejected`/`ChangesRequested`/`UnderReview`), reason?, isActive |
| `HelperBanStatusChanged` | helperId, isBanned, reason? |
| `HelperSuspensionChanged` | helperId, isSuspended, reason? |
| `HelperDeactivatedByDrugTest` | helperId, expiredOn? |
| `InterviewDecision` | interviewId, helperId, languageCode, languageName, decision (`Approved`/`Rejected`), reason?, nextEligibleTestAt? |

### 16.3 Chat / SOS / Reports (both apps)

| Method | Key fields |
|--------|-----------|
| `ChatMessage` | bookingId, conversationId, messageId, senderId, senderType, senderName, recipientId, recipientType, messageType, preview, sentAt |
| `SosTriggered` | sosId, bookingId, triggeredByType, triggeredById, recipientType, recipientId, reason? |
| `SosResolved` | sosId, bookingId, triggeredByType, triggeredById, finalStatus (`Handled`/`FalseAlarm`/`Cancelled`), resolutionNote?, resolutionAction? |
| `ReportResolved` | reportId, direction, recipientType, recipientId, finalStatus (`Resolved`/`Dismissed`), resolutionNote?, resolutionAction? |
| `HelperReportResolved` | reportId, userId, helperId, resolutionNote? _(legacy — prefer `ReportResolved`)_ |

### 16.4 Diagnostic

| Method | Key fields |
|--------|-----------|
| `Pong` | serverTimestampMs (long) |

---

## 17. Common Pitfalls — Do / Don't

### ❌ Don't — open a new hub connection per screen
Open **one** in your DI/root, keep it alive the whole session.

### ❌ Don't — register handlers after `connection.start()`
Register **all** `connection.on(...)` handlers first, then call `start()`. Otherwise you'll miss the first bursts of events.

### ❌ Don't — assume events are a reliable source of truth
Network drops, app backgrounding, process death — all of these can cause you to miss events. **After every `onreconnected` and every app resume, re-fetch the authoritative state from REST:**
- Current booking: `GET /api/user/bookings/{id}` or `GET /api/helper/bookings/{id}`
- Active helper booking: `GET /api/helper/bookings/active`
- Unread chat: refresh messages list
- Latest GPS on the tracking map: `GET /api/booking/{id}/tracking/latest`

### ❌ Don't — call `JoinBooking` / `JoinUser` / `JoinHelper`
These methods don't exist. The server auto-joins you to every room you need when you connect. Attempting to call them will throw a server-side error.

### ❌ Don't — invoke `SendLocation` with a JSON object
The method takes **positional** arguments:
```dart
hub.invoke('SendLocation', args: [lat, lng, heading, speedKmh, accuracyMeters]);
```
Don't pass `{lat: ..., lng: ...}` — the server will 500.

### ❌ Don't — fire `SendLocation` 10× per second
The OS may sample that fast, but the backend discards anything closer than 10 s / 20 m. Flood = wasted battery + bandwidth. On Android, use `locationSettings.intervalDuration = 5s` or similar.

### ❌ Don't — stream GPS from the user app
Only the **helper** sends location. The user's position is entered manually at booking time (pickup). The server rejects `SendLocation` from user connections.

### ❌ Don't — trust the sender-side echo for chat
When you `POST /messages`, you get the persisted row back — render that. You will **not** receive `ChatMessage` for your own messages.

### ❌ Don't — double-render an event you received via both FCM and SignalR
Dedupe by `eventId`.

### ❌ Don't — block the UI on `hub.start()`
It can take several seconds on cold networks. Kick it off on a Future and let REST-driven screens render in parallel.

### ✅ Do — handle reconnect visibly
Show a small "Reconnecting…" banner when `onreconnecting` fires. Clear it on `onreconnected`.

### ✅ Do — stop the hub on logout
```dart
await hub.stop();
await dio.delete('/api/notifications/devices/all');
```

### ✅ Do — treat dates as **UTC** on the wire
All server timestamps are ISO-8601 with `Z`. Convert to local only for display.

### ✅ Do — display enums as strings
Status enums (`BookingStatus`, `PaymentStatus`, etc.) are serialized as **string names** in JSON. Don't code defensively against numeric values.

---

## 18. Quick Checklist

Use this during implementation. Tick each item for user app and helper app.

### Startup
- [ ] Store JWT from login.
- [ ] Build Dio client with `Authorization` interceptor.
- [ ] Register FCM device token → `POST /api/notifications/devices`.
- [ ] Register FCM `onTokenRefresh` → same endpoint.
- [ ] Open **one** SignalR connection to `/hubs/booking` with `accessTokenFactory`.
- [ ] Register **all** event handlers **before** `connection.start()`.
- [ ] Wire `onreconnecting` → show banner; `onreconnected` → re-fetch state + hide banner.

### Booking (user)
- [ ] Pickup/destination picker: fullscreen map with fixed center pin (Uber-style), reverse geocode → send `pickupLocationName` + `pickupLatitude/Longitude`. User never types coordinates.
- [ ] When both pickup and destination coordinates are available, run Google Directions and send `distanceKm` with the booking — the backend clamps it against Haversine and uses it for pricing.
- [ ] Scheduled: `POST /api/user/bookings/scheduled/search` → pick helper → `POST /api/user/bookings/scheduled`.
- [ ] Instant: `POST /api/user/bookings/instant/search` → `POST /api/user/bookings/instant`.
- [ ] Listen: `BookingStatusChanged`, `BookingCancelled`, `BookingPaymentChanged`, `BookingTripStarted`, `BookingTripEnded`.
- [ ] On accept (scheduled): open payment screen → `POST /api/payments/booking/{id}/initiate`.
- [ ] On trip end (instant): open payment screen → same endpoint.
- [ ] On `InProgress`: open map, subscribe to `HelperLocationUpdate`, pre-load `GET /tracking/latest`.
- [ ] On `Completed`: prompt rating → `POST /api/ratings/booking/{id}/helper`. Show invoice.

### Helper onboarding (before the helper goes live)
- [ ] Service-area map picker screen: tap center + radius slider → `POST /api/helper/service-areas`.
- [ ] Block the "submit for review" CTA until `GET /api/helper/service-areas` returns ≥ 1 row.
- [ ] Allow edit/delete via `PUT` / `DELETE /api/helper/service-areas/{id}`.
- [ ] Request background-location permission (Android foreground service + iOS "Always" authorization) **before** the helper flips to `AvailableNow`.
- [ ] If the permission is denied, show a clear explainer and keep the toggle disabled for Instant (allow Scheduled-only as a fallback).

### Booking (helper)
- [ ] Mark availability → `POST /api/helper/bookings/availability`.
- [ ] While `AvailableNow`: start the GPS stream (`SendLocation` on hub). Foreground-service fallback to `POST /api/helper/location/update` every 30 s when backgrounded.
- [ ] Listen: `RequestIncoming`, `RequestRemoved`, `HelperDashboardChanged`, `HelperAvailabilityChanged`.
- [ ] Accept / decline: `POST /api/helper/bookings/requests/{id}/accept` | `/decline`.
- [ ] On start day → `POST /api/helper/bookings/{id}/start`.
- [ ] On end → `POST /api/helper/bookings/{id}/end`.
- [ ] On `Completed`: prompt rating → `POST /api/helper/ratings/booking/{id}/user`. Show invoice from `/api/helper/invoices/booking/{id}`.
- [ ] Listen to moderation events: `HelperApprovalChanged`, `HelperBanStatusChanged`, `HelperSuspensionChanged`, `InterviewDecision`, `HelperDeactivatedByDrugTest`.

### Chat
- [ ] Show chat tab only when `bookingDetail.chatEnabled == true`.
- [ ] Paged history: `GET /chat/messages`.
- [ ] Send: `POST /chat/messages` → append response.
- [ ] Listen: `ChatMessage` (recipient only).
- [ ] Mark as read when user opens conversation: `POST /chat/read`.

### SOS / Reports
- [ ] SOS button during `InProgress` → `POST /api/sos/bookings/{id}` (user) or `/api/helper/sos/bookings/{id}` (helper). Send live GPS.
- [ ] Listen: `SosTriggered` (counterparty), `SosResolved` (triggerer).
- [ ] Submit report: `POST /api/reports` (user) or `POST /api/helper/reports` (helper).
- [ ] Listen: `ReportResolved` (reporter).

### Shutdown
- [ ] On logout: `connection.stop()` + `DELETE /api/notifications/devices/all`.

---

## 19. Reference Swagger

Swagger UI (deployed): [https://tourestaapi.runasp.net/swagger/index.html](https://tourestaapi.runasp.net/swagger/index.html)

From the dropdown in the top-right of the Swagger page, pick the group you want:

| Group | What's in it | JSON |
|---|---|---|
| **User App** | All `/api/user/...` + shared endpoints (payments, invoices, ratings, sos, reports, device tokens) | `https://tourestaapi.runasp.net/swagger/user/swagger.json` |
| **Helper App** | All `/api/helper/...` endpoints + shared endpoints | `https://tourestaapi.runasp.net/swagger/helper/swagger.json` |
| **Admin** | Admin dashboard (not used by mobile) | `https://tourestaapi.runasp.net/swagger/admin/swagger.json` |
| **Realtime (SignalR)** | Every hub method + every server-to-client event with its payload shape | `https://tourestaapi.runasp.net/swagger/realtime/swagger.json` |

> Use the **Realtime (SignalR)** group as the source of truth for event payloads. Every method listed there maps 1-to-1 to a `connection.on("...", ...)` registration in your Flutter code.

---

## 20. When in doubt

- **"Did the event get lost?"** → Re-fetch from REST. That's always the truth.
- **"Is the helper online?"** → Check `HelperAvailabilityChanged` events + `helper.availabilityState` from the booking detail response.
- **"Why does instant search return 0 helpers?"** → Call `GET /api/helper/location/instant-eligibility` while signed in as the helper — it shows every gate (Approved, Active, AvailableNow, Fresh location, Within radius, Language match, Car match) with pass/fail reasons.
- **"The payment webview closed but I don't know the outcome."** → Poll `GET /api/payments/{paymentId}` and wait for the next `BookingPaymentChanged` — don't assume success.
- **"Stuck booking in dev."** → `POST /api/dev/bookings/{id}/force-finish` (dev env only) clears it.

Ping the backend team any time you hit something undocumented — we'll either add it here or extend the API.
