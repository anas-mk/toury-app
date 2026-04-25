# Touresta — Booking Flow Complete Reference

> **Audience:** Flutter engineer integrating the Touresta mobile apps (User + Helper) with the production backend — **and/or** an AI assistant helping that engineer.
> **Why this file exists:** the booking flow involves two actors, two databases, a state machine, a payment sub-flow, and a SignalR hub. This document is the single source of truth so you never have to guess what's required, what's optional, or when the server pushes what.
> **Style:** contract-first. Every endpoint lists its full request, every hub event lists its full payload, every state transition lists what triggers it. No prose you have to skim — look it up, read the row, ship the feature.

---

## Table of Contents

1. [Environment & Base URLs](#1-environment--base-urls)
2. [Auth & Request/Response Envelope](#2-auth--requestresponse-envelope)
3. [Actors & Two-Channel Architecture](#3-actors--two-channel-architecture)
4. [The Booking State Machine](#4-the-booking-state-machine)
5. [The SignalR Hub — Deep Dive](#5-the-signalr-hub--deep-dive)
6. [Domain Enums (Wire Values)](#6-domain-enums-wire-values)
7. [Scheduled Booking — End-to-End Flow](#7-scheduled-booking--end-to-end-flow)
8. [Instant Booking — End-to-End Flow](#8-instant-booking--end-to-end-flow)
9. [Payment Flow (Deposit / Remaining / Full)](#9-payment-flow-deposit--remaining--full)
10. [Trip Tracking & Live Location](#10-trip-tracking--live-location)
11. [Chat Integration](#11-chat-integration)
12. [Complete Endpoint Catalog](#12-complete-endpoint-catalog)
13. [Complete Real-Time Event Catalog](#13-complete-real-time-event-catalog)
14. [Flutter Implementation Blueprint](#14-flutter-implementation-blueprint)
15. [Failure Modes & What to Do](#15-failure-modes--what-to-do)
16. [Developer Checklist](#16-developer-checklist)

---

## 1. Environment & Base URLs

| Purpose                  | URL                                                                 |
| ------------------------ | ------------------------------------------------------------------- |
| Production REST base     | `https://tourestaapi.runasp.net`                                    |
| Swagger UI               | `https://tourestaapi.runasp.net/swagger/index.html`                 |
| SignalR Booking Hub      | `https://tourestaapi.runasp.net/hubs/booking`                       |
| Mock payment page (card) | `https://tourestaapi.runasp.net/mock-payment.html?paymentId={id}`   |

All dates on the wire are **UTC ISO-8601** (`2026-04-24T17:30:00Z`). All `TimeSpan` values serialize as `"HH:mm:ss"` (e.g. `"10:00:00"`). All enums serialize as their **string name** (e.g. `"AvailableNow"`, not `1`).

---

## 2. Auth & Request/Response Envelope

### 2.1 JWT

Every protected endpoint and the hub connection require a bearer token obtained from the auth endpoints:

```
Authorization: Bearer <jwt>
```

The JWT contains two claims that the backend reads:

| Claim  | Values                    | Purpose                                                   |
| ------ | ------------------------- | --------------------------------------------------------- |
| `id`   | Aspnet user id (GUID-ish) | Caller identity; hub resolves SignalR UserIdentifier from this. |
| `type` | `"user"` or `"helper"`    | Controls which controllers / hub branches the caller can enter. |

> If you try to open the hub with an expired JWT you'll get `401` at handshake. Always refresh-then-reconnect.

### 2.2 Response envelope

Every REST endpoint returns this shape. The mobile app should have one generic type for it.

```json
{
  "success": true,
  "message": "Booking created.",
  "data": { /* endpoint-specific payload, may be null on errors */ }
}
```

- **200** with `success=true` → success, read `data`.
- **400** with `success=false` → business rule failed, show `message` to the user.
- **401** → JWT missing/invalid → force re-login.
- **403** → authenticated but not allowed (e.g. user trying to read someone else's booking).
- **404** → resource doesn't exist.

### 2.3 Paginated responses

List endpoints return:

```json
{
  "success": true,
  "data": {
    "items": [ /* page payload */ ],
    "page": 1,
    "pageSize": 10,
    "totalCount": 57,
    "totalPages": 6
  }
}
```

---

## 3. Actors & Two-Channel Architecture

### 3.1 The two actors

| Actor      | Authenticates as | Base route prefix      | Hub role on `/hubs/booking` |
| ---------- | ---------------- | ---------------------- | --------------------------- |
| Traveler   | `type=user`      | `/api/user/bookings/*` | Receives push events on `user:{userId}` and (when engaged) `booking:{bookingId}`. |
| Helper     | `type=helper`    | `/api/helper/bookings/*` | Receives push events on `helper:{helperId}` and (when engaged) `booking:{bookingId}`. Additionally streams live GPS **up** via `SendLocation`. |

### 3.2 Two channels that work together

```
┌──────────┐  REST (HTTPS, request/response, authoritative)   ┌────────────┐
│ Flutter  │ ◄─────────────────────────────────────────────►  │  Backend   │
│   app    │                                                  │            │
│          │  SignalR (WebSocket, persistent, server → app)   │ (SQL + Mongo)
│          │ ◄─────────────────────────────────────────────►  │            │
└──────────┘                                                  └────────────┘
```

- **REST = source of truth.** Use on app start, on screen open, on reconnect, and whenever the user taps a button.
- **SignalR = UI stays live.** Use to update a screen that is already open while something happens on the server.

**Golden rule:** if you receive a hub event and your local state looks off, **re-fetch via REST**. Events are fire-and-forget; a dropped connection means lost events.

---

## 4. The Booking State Machine

Every booking carries a **`Status`** and an independent **`PaymentStatus`**. The status transitions below are the only legal ones.

```
              ┌──────────────────────┐
              │ PendingHelperResponse│  ← created by user
              └──────────┬───────────┘
                         │ helper accepts
                         ▼
               ┌──────────────────────┐      ┌───────────────────────────┐
               │   AcceptedByHelper   │ ───► │ ConfirmedAwaitingPayment  │  (scheduled, deposit due)
               └──────────┬───────────┘      └──────────────┬────────────┘
                          │                                 │ deposit paid
                          │                                 ▼
                          │                          ┌──────────────┐
                          │                          │ ConfirmedPaid │
                          │                          └──────┬────────┘
                          ▼                                 ▼
                   ┌─────────────┐                   ┌─────────────┐
                   │   Upcoming  │ ◄──── T-minutes ──│ ConfirmedPaid
                   └──────┬──────┘                   └─────────────┘
                          │ helper taps "Start Trip"
                          ▼
                    ┌──────────────┐
                    │  InProgress  │  ◄─ live GPS, chat, SOS, etc.
                    └──────┬───────┘
                           │ helper taps "End Trip"
                           ▼
                    ┌──────────────┐
                    │   Completed  │  ← ratings & (instant) final payment due
                    └──────────────┘

  ─── Alternate endings ────────────────────────────────────────────────
  • DeclinedByHelper         ← helper declined the request
  • ExpiredNoResponse        ← response deadline lapsed
  • ReassignmentInProgress   ← system trying the next helper
  • WaitingForUserAction     ← retries exhausted, user must pick a new helper
  • CancelledByUser / CancelledByHelper / CancelledBySystem
```

### 4.1 Payment status (independent dimension)

| Value             | Meaning                                                                |
| ----------------- | ---------------------------------------------------------------------- |
| `NotRequired`     | No payment needed yet (still pending / declined).                      |
| `AwaitingPayment` | Payment is due. The app should show "Pay now".                        |
| `PaymentPending`  | Initiated, waiting for the mock gateway callback.                     |
| `Paid`            | Settled.                                                               |
| `Refunded`        | Admin refunded; refund amount captured in the row.                    |
| `Failed`          | Gateway rejected the payment; user may retry.                         |

### 4.2 Payment phase (scheduled split)

| Phase       | Meaning                                                                          |
| ----------- | -------------------------------------------------------------------------------- |
| `Full`      | Instant bookings pay 100% once, after the trip.                                  |
| `Deposit`   | Scheduled bookings: the up-front hold, paid **before** the trip.                |
| `Remaining` | Scheduled bookings: the balance, paid **after** `Completed`.                    |

---

## 5. The SignalR Hub — Deep Dive

Everything real-time flows through **one** connection per app session.

### 5.1 Connection contract

| Property              | Value                                                        |
| --------------------- | ------------------------------------------------------------ |
| URL                   | `https://tourestaapi.runasp.net/hubs/booking`                |
| Transport             | WebSockets preferred, SSE fallback, long-polling fallback    |
| Auth                  | `?access_token=<jwt>` query string **or** `Authorization` header |
| Required JWT claims   | `id`, `type` (`user` or `helper`) — connection is rejected otherwise. |
| Automatic reconnect   | **You** must enable it in the client. Server does not reconnect for you. |

### 5.2 What the server does at `OnConnectedAsync`

```
1. Read JWT claims "id" and "type".
2. If type == "user":
     • join group "user:{userId}"
     • look up user's active bookings in SQL
     • join every "booking:{bookingId}" room those produce
3. If type == "helper":
     • resolve Helper from user id (fails → abort)
     • join group "helper:{helperId}"
     • look up helper's active bookings
     • join every "booking:{bookingId}" room those produce
```

> **You do NOT call any "Join" method yourself.** The server manages every group membership. Do not try to send arbitrary group join requests — there are no such hub methods.

### 5.3 Group naming (server-internal, shown for reference only)

| Group             | Membership                                              | Used for                                            |
| ----------------- | ------------------------------------------------------- | --------------------------------------------------- |
| `user:{userId}`   | All connections of the authenticated user               | Status changes on any of their bookings, chat, reports, SOS. |
| `helper:{helperId}` | All connections of the authenticated helper           | Incoming requests, dashboard deltas, availability, chat, moderation events. |
| `booking:{bookingId}` | Engaged user + engaged helper for that booking        | Live trip state: start / end / live GPS.           |
| `admin:*`         | Admin hub only (separate hub at `/hubs/admin`, not covered here). | — |

### 5.4 Client → server methods you can invoke

Only two. Everything else is one-way (server push).

| Method         | Who can call | Signature                                                                 | Purpose                                   |
| -------------- | ------------ | ------------------------------------------------------------------------- | ----------------------------------------- |
| `Ping`         | Any          | `Ping() → Pong(long serverTimestampMs)`                                   | Diagnostic round-trip.                    |
| `SendLocation` | **Helper only** | `SendLocation(double lat, double lng, double? heading, double? speedKmh, double? accuracyMeters)` | Stream a GPS sample. User callers are silently dropped. |

> `SendLocation` arguments are **positional, not an object.** See §10 for usage.

### 5.5 Server → client events (handlers you register)

Register these handler names **exactly** — SignalR dispatches by string match.

| Handler name              | Who receives it     | When                                                             |
| ------------------------- | ------------------- | ---------------------------------------------------------------- |
| `RequestIncoming`         | Helper              | A new booking request was dispatched to this helper.            |
| `RequestRemoved`          | Helper              | An earlier incoming request is no longer actionable.            |
| `BookingStatusChanged`    | User + Helper       | Booking moved from one lifecycle state to another.              |
| `BookingCancelled`        | User + Helper       | A terminal cancellation fired (by whom is in the payload).      |
| `BookingPaymentChanged`   | User + Helper       | A payment row went to `Paid` / `Failed` / `Refunded`.           |
| `BookingTripStarted`      | User + Helper       | Helper tapped "Start Trip".                                      |
| `BookingTripEnded`        | User + Helper       | Helper tapped "End Trip".                                        |
| `HelperLocationUpdate`    | User + Helper (booking room) | Live GPS sample (throttled server-side).                  |
| `HelperDashboardChanged`  | Helper              | Delta to the helper dashboard counters.                         |
| `HelperAvailabilityChanged` | Helper            | Availability state transitioned (manual or automatic).          |
| `HelperApprovalChanged`   | Helper              | Admin approved / revoked.                                       |
| `HelperBanStatusChanged`  | Helper              | Admin banned / unbanned.                                        |
| `HelperSuspensionChanged` | Helper              | Admin suspended / lifted.                                       |
| `HelperDeactivatedByDrugTest` | Helper          | Automatic deactivation following drug-test failure.             |
| `InterviewDecision`       | Helper              | Admin finalized an interview review.                            |
| `HelperReportResolved`    | User                | A report the user filed against a helper was resolved.          |
| `ReportResolved`          | User / Helper       | Bidirectional report outcome.                                    |
| `SosTriggered`            | User / Helper       | The other party on your active booking raised an SOS.           |
| `SosResolved`             | User / Helper       | Your own SOS event was resolved (admin or self-cancel).         |
| `ChatMessage`             | User / Helper       | A new chat message addressed to **you** (never to the sender).  |
| `Pong`                    | Caller              | Response to a `Ping` you sent.                                   |

Full payload schemas in §13.

### 5.6 Envelope shared by every event

Every event (including booking and chat) has:

```jsonc
{
  "eventId":  "3f9c...-...-...",   // Guid, idempotency key — dedupe on this
  "occurredAt": "2026-04-24T18:02:33Z",
  "v": 1,                          // wire-format version (future-proofing)
  // ...event-specific fields
}
```

Treat `eventId` as the dedup key in your local cache. Never let the UI render the same event twice.

---

## 6. Domain Enums (Wire Values)

All enums are sent as **string names**.

### `BookingType`
```
"Scheduled" | "Instant"
```

### `BookingStatus`
```
"PendingHelperResponse"
"AcceptedByHelper"
"ConfirmedAwaitingPayment"
"ConfirmedPaid"
"Upcoming"
"InProgress"
"Completed"
"DeclinedByHelper"
"ExpiredNoResponse"
"ReassignmentInProgress"
"WaitingForUserAction"
"CancelledByUser"
"CancelledByHelper"
"CancelledBySystem"
```

### `PaymentStatus`
```
"NotRequired" | "AwaitingPayment" | "PaymentPending" | "Paid" | "Refunded" | "Failed"
```

### `PaymentPhase`
```
"Full" | "Deposit" | "Remaining"
```

### `PaymentMethod`
```
"Cash" | "MockCard"
```

### `HelperAvailabilityState`
```
"Offline" | "AvailableNow" | "ScheduledOnly" | "Busy"
```

### `MeetingPointType`
```
"Hotel" | "Airport" | "Custom"
```

### `RequestRemovalReason`
```
"AcceptedByOther" | "Expired" | "CancelledByUser"
"CancelledBySystem" | "Reassigned" | "Declined"
```

---

## 7. Scheduled Booking — End-to-End Flow

A Scheduled booking is a future trip the traveler arranges with a specific helper. Payment is split into a **Deposit** (before the trip) and a **Remaining** balance (after).

### 7.1 Required data (authoritative list)

When creating a Scheduled booking (`POST /api/user/bookings/scheduled`):

| Field                    | Required? | Notes                                                                 |
| ------------------------ | --------- | --------------------------------------------------------------------- |
| `helperId`               | **Yes**   | From the search / profile screen.                                    |
| `destinationCity`        | **Yes**   | Used for service-area matching.                                      |
| `destinationName`        | **Yes**   | Human-readable label for the destination (2–500 chars).              |
| `destinationLatitude`    | **Yes**   | Decimal degrees, range `-90..90`.                                     |
| `destinationLongitude`   | **Yes**   | Decimal degrees, range `-180..180`.                                   |
| `requestedDate`          | **Yes**   | UTC date-time. Must be in the future.                                |
| `startTime`              | **Yes**   | `"HH:mm:ss"`.                                                         |
| `durationInMinutes`      | **Yes**   | Integer in `[60, 1440]`.                                             |
| `meetingPointType`       | **Yes**   | `"Hotel"` / `"Airport"` / `"Custom"`.                                 |
| `travelersCount`         | **Yes**   | Integer in `[1, 20]`.                                                |
| `pickupLocationName`     | Optional  | Human label when pickup is pre-chosen.                               |
| `pickupAddress`          | Optional  | Full address line.                                                    |
| `pickupLatitude`         | Optional  | If omitted, only destination drives pricing.                         |
| `pickupLongitude`        | Optional  | Must be provided together with `pickupLatitude`.                     |
| `requestedLanguage`      | Optional  | ISO 639-1 (`"en"`, `"ar"`, …).                                        |
| `requiresCar`            | Optional  | Boolean. Defaults `false`.                                            |
| `notes`                  | Optional  | Free text, ≤ 1000 chars.                                              |

> **Why destination coords are required:** Scheduled trips always need at least one concrete geo-point so the helper can plan and the price formula can compute distance cost. Pickup is optional because travelers often book days in advance without yet knowing the exact pickup address.

### 7.2 Sequence (happy path)

```
USER                     BACKEND                     HELPER
 │ search helpers         │                            │
 │───────────────────────►│  /api/user/bookings/scheduled/search
 │◄──────────── list ─────│
 │                        │                            │
 │ view profile           │                            │
 │───────────────────────►│  /api/user/bookings/helpers/{id}/profile
 │◄──────────── data ─────│                            │
 │                        │                            │
 │ create booking         │                            │
 │───────────────────────►│  /api/user/bookings/scheduled
 │◄── 200 (Pending...) ───│                            │
 │                        │── RequestIncoming ────────►│  (hub)
 │                        │                            │
 │                        │                            │ accept
 │                        │◄───────────────────────────│  /api/helper/bookings/requests/{id}/accept
 │◄── BookingStatusChanged ───(hub, user)              │
 │    OldStatus: PendingHelperResponse                 │
 │    NewStatus: ConfirmedAwaitingPayment              │
 │    PaymentStatus: AwaitingPayment                   │
 │                        │                            │
 │ pay deposit            │                            │
 │───────────────────────►│  /api/payments/booking/{id}/initiate  (Method=MockCard)
 │◄── paymentUrl ─────────│                            │
 │ (webview) user picks "succeed"                      │
 │───────────────────────►│  /api/payments/mock/{paymentId}/complete
 │                        │                            │
 │◄── BookingPaymentChanged (hub, user)                │
 │    Status: Paid, Phase: Deposit                     │
 │◄── BookingStatusChanged (hub, user + helper)        │
 │    NewStatus: ConfirmedPaid                         │
 │                        │                            │
 │  --- time passes, trip day arrives ---              │
 │                        │                            │
 │                        │                            │ tap "Start Trip"
 │                        │◄───────────────────────────│  /api/helper/bookings/{id}/start
 │◄── BookingTripStarted (hub, booking room)           │
 │◄── HelperLocationUpdate (hub, booking room) ◄── SendLocation ◄── helper streams GPS
 │                        │                            │
 │                        │                            │ tap "End Trip"
 │                        │◄───────────────────────────│  /api/helper/bookings/{id}/end
 │◄── BookingTripEnded (hub, booking room)             │
 │                        │                            │
 │ pay remaining          │                            │
 │───────────────────────►│  /api/payments/booking/{id}/initiate  (Phase=Remaining)
 │◄── BookingPaymentChanged (Paid, Remaining)          │
```

### 7.3 Cancellation rules (scheduled)

| When user cancels                                                 | Effect on deposit   |
| ----------------------------------------------------------------- | ------------------- |
| Before helper accepts                                             | No deposit charged. |
| After `ConfirmedAwaitingPayment` / before deposit paid            | No deposit charged. |
| After deposit paid, outside the "late-cancel" window              | Refunded.           |
| After deposit paid, inside the late-cancel window                 | **Forfeited** — reflected as `depositForfeited=true` in the detail response, the refund is **not** issued, and the helper keeps their share. |
| After trip started (`InProgress`)                                 | Cancellation is not allowed.                                         |

---

## 8. Instant Booking — End-to-End Flow

An Instant booking is "I need a helper right now". The system matches the nearest `AvailableNow` helper and the traveler pays **once, after** the trip.

### 8.1 Required data (authoritative list)

`POST /api/user/bookings/instant`:

| Field                    | Required? | Notes                                                               |
| ------------------------ | --------- | ------------------------------------------------------------------- |
| `helperId`               | Optional  | If omitted, the backend picks the best `AvailableNow` helper.      |
| `pickupLocationName`     | **Yes**   | Human-readable label.                                              |
| `pickupLatitude`         | **Yes**   | Decimal degrees.                                                    |
| `pickupLongitude`        | **Yes**   | Decimal degrees.                                                    |
| `destinationName`        | Optional  | If not set up-front, the helper will capture it in person.         |
| `destinationLatitude`    | Optional  |                                                                     |
| `destinationLongitude`   | Optional  |                                                                     |
| `durationInMinutes`      | **Yes**   | Integer in `[60, 1440]`.                                           |
| `travelersCount`         | **Yes**   | Integer in `[1, 20]`.                                              |
| `requestedLanguage`      | Optional  |                                                                     |
| `requiresCar`            | Optional  | Boolean.                                                            |
| `notes`                  | Optional  |                                                                     |

### 8.2 Sequence

```
USER                     BACKEND                     HELPER
 │ search AvailableNow    │                            │
 │───────────────────────►│  /api/user/bookings/instant/search
 │◄─── nearby list ───────│                            │
 │                        │                            │
 │ create instant         │                            │
 │───────────────────────►│  /api/user/bookings/instant
 │◄── 200 (Pending...) ───│                            │
 │                        │── RequestIncoming ────────►│
 │                        │                            │
 │                        │                            │ accept (short deadline, default 60s)
 │                        │◄───────────────────────────│  /api/helper/bookings/requests/{id}/accept
 │◄── BookingStatusChanged (NewStatus: AcceptedByHelper / ConfirmedAwaitingPayment...)
 │                        │                            │
 │                        │                            │ tap "Start Trip"
 │                        │◄───────────────────────────│  /api/helper/bookings/{id}/start
 │◄── BookingTripStarted                               │
 │◄── HelperLocationUpdate ◄───────── SendLocation ◄───│  (streamed)
 │                        │                            │
 │                        │                            │ tap "End Trip"
 │                        │◄───────────────────────────│  /api/helper/bookings/{id}/end
 │◄── BookingTripEnded (PaymentStatus: AwaitingPayment)
 │                        │                            │
 │ pay full               │                            │
 │───────────────────────►│  /api/payments/booking/{id}/initiate  (Phase=Full)
 │◄── BookingPaymentChanged (Paid, Full)               │
```

### 8.3 Reassignment & auto-retry

If the chosen helper declines or misses the deadline, the booking moves to:

- `ReassignmentInProgress` → server automatically tries the next best candidate (loops while auto-retry attempts remain). The user's UI should keep showing "Finding another helper…".
- `WaitingForUserAction` → retries exhausted. The user app shows `/api/user/bookings/{id}/alternatives` and lets the traveler pick.

Both transitions are communicated via `BookingStatusChanged`. When a request is pulled from a helper's list, that helper receives `RequestRemoved` with a `Reason`.

---

## 9. Payment Flow (Deposit / Remaining / Full)

### 9.1 The two methods

| Method     | Gateway involved? | End-state after `initiate`                                    |
| ---------- | ----------------- | ------------------------------------------------------------- |
| `Cash`     | No                | Server short-circuits to `Paid`. UI closes the pay screen.    |
| `MockCard` | Yes (mock HTML)   | Server responds with `paymentUrl`. Open it in a webview; the user clicks one of the outcome buttons; the page posts back to the server, which then fires `BookingPaymentChanged`. |

### 9.2 Initiate

```
POST /api/payments/booking/{bookingId}/initiate
Authorization: Bearer <user jwt>

{ "method": "MockCard" }
```

Response:

```jsonc
{
  "success": true,
  "data": {
    "paymentId": "abc123...",
    "bookingId": "bk_...",
    "amount": 450.00,
    "currency": "EGP",
    "method": "MockCard",
    "status": "PaymentPending",   // or "Paid" for Cash
    "phase": "Deposit",           // Full | Deposit | Remaining — depends on booking state
    "paymentUrl": "https://tourestaapi.runasp.net/mock-payment.html?paymentId=abc123..."
  }
}
```

### 9.3 Mock gateway outcome (testing)

The mock HTML page in a webview will `POST /api/payments/mock/{paymentId}/complete` with one of:

| `action`            | Resulting status | `BookingPaymentChanged.Status` |
| ------------------- | ---------------- | ------------------------------ |
| `"succeed"`         | `Paid`           | `"Paid"`                       |
| `"fail_insufficient"` | `Failed`       | `"Failed"` (+ `failureReason`) |
| `"fail_network"`    | `Failed`         | `"Failed"` (+ `failureReason`) |
| `"cancel"`          | `Failed`         | `"Failed"`                     |

The app does **not** call this endpoint directly — it's invoked by the mock page. After the webview closes, rely on the hub event (and optionally re-fetch `/api/payments/{paymentId}`).

### 9.4 Which phase is `initiate` settling?

The backend picks the phase automatically based on the booking's payment state:

| Booking situation                                                         | Phase returned |
| ------------------------------------------------------------------------- | -------------- |
| Scheduled, status `ConfirmedAwaitingPayment`, no deposit row yet          | `Deposit`      |
| Scheduled, status `Completed`, deposit paid but remaining unpaid          | `Remaining`    |
| Instant, status `Completed`, no payment yet                               | `Full`         |

The app should surface this as "Pay deposit" / "Pay balance" / "Pay" respectively.

### 9.5 Reading payment state

- `GET /api/payments/booking/{bookingId}/latest` — most recent row for the booking.
- `GET /api/payments/{paymentId}` — a specific payment.

---

## 10. Trip Tracking & Live Location

### 10.1 Who sends what

| Actor  | What they do                                                                                     |
| ------ | ------------------------------------------------------------------------------------------------ |
| Helper | Streams GPS samples **up** to the server via `SendLocation` on the hub. HTTP fallback: `POST /api/helper/location/update`. |
| User   | Does **not** send location. Only receives `HelperLocationUpdate` events on the booking room.   |

### 10.2 `SendLocation` signature (helper app)

```dart
await hub.invoke('SendLocation', args: [
  latitude,           // double, -90..90
  longitude,          // double, -180..180
  heading,            // double? | null   (0..360)
  speedKmh,           // double? | null
  accuracyMeters,     // double? | null
]);
```

Call this whenever the OS emits a location update. Do **not** pre-throttle; the server applies a min-distance / min-interval filter before persisting and broadcasting. Aim for the system default cadence (roughly 3–5 seconds is plenty).

### 10.3 `HelperLocationUpdate` payload (what the user app receives)

```jsonc
{
  "eventId": "...", "occurredAt": "...", "v": 1,
  "bookingId": "bk_...",
  "helperId":  "hlp_...",
  "latitude":  30.0461,
  "longitude": 31.2331,
  "heading":   148.0,          // nullable
  "speedKmh":  42.0,           // nullable
  "capturedAt": "2026-04-24T18:02:33Z",
  "distanceToPickupKm":       2.4,   // nullable — computed server-side
  "etaToPickupMinutes":       6,     // nullable
  "distanceToDestinationKm":  null,
  "etaToDestinationMinutes":  null,
  "phase": "OnTheWay"          // "OnTheWay" | "InProgress" | …
}
```

### 10.4 Reconnect priming

When the user app (re)opens during a trip, before subscribing to `HelperLocationUpdate` do:

```
GET /api/booking/{bookingId}/tracking/latest   → last known point
GET /api/booking/{bookingId}/tracking/history  → full polyline
```

This way the map isn't blank for the first 10 seconds while you wait for the next live sample.

### 10.5 Helper availability side-effects

- Starting a trip automatically flips `HelperAvailabilityState` to `Busy` and emits `HelperAvailabilityChanged`.
- Ending a trip flips it back to `AvailableNow` (or the value it held before, if different).

---

## 11. Chat Integration

Chat is **MongoDB-backed**, exposed via REST for history/pagination, with push via `ChatMessage` on the hub.

### 11.1 When chat opens / closes

| Booking state                                            | Chat status |
| -------------------------------------------------------- | ----------- |
| `PendingHelperResponse`                                  | Closed.     |
| `AcceptedByHelper` → `ConfirmedAwaitingPayment` → `Completed` | **Open**.   |
| `Completed`, `Cancelled*`, terminal                      | Archived (read-only). |

The `chatEnabled` flag on the booking detail response is the single source of truth.

### 11.2 Sending a message (REST)

```
POST /api/chat/bookings/{bookingId}/messages
{
  "messageType": "Text",         // "Text" | "Image" | "Location" (see chat docs)
  "content":     "See you at 10",
  "attachmentUrl": null
}
```

The sender does **not** receive a self-push. The recipient receives a `ChatMessage` event (§13) and/or an FCM push if offline.

### 11.3 Reading history

```
GET /api/chat/bookings/{bookingId}/messages?page=1&pageSize=30
```

---

## 12. Complete Endpoint Catalog

> All paths are under `https://tourestaapi.runasp.net`. `u` = user JWT required, `h` = helper JWT required.

### 12.1 User — Bookings (`/api/user/bookings`)

| Verb   | Path                                   | Auth | Purpose                                                           |
| ------ | -------------------------------------- | :--: | ----------------------------------------------------------------- |
| POST   | `/scheduled/search`                    |  u   | Rank helpers available on a future date.                          |
| POST   | `/instant/search`                      |  u   | Rank helpers available right now (`AvailableNow`).                |
| GET    | `/helpers/{helperId}/profile`          |  u   | Full booking profile of one helper (rating, languages, car, …).   |
| POST   | `/scheduled`                           |  u   | Create a Scheduled booking. See §7.1 for required fields.         |
| POST   | `/instant`                             |  u   | Create an Instant booking. See §8.1.                              |
| GET    | `/{bookingId}`                         |  u   | Full booking detail (status, helper, payment, timeline).          |
| GET    | ` `   (root `/api/user/bookings`)      |  u   | Paginated list of my bookings. Optional `status`, `type`, `page`, `pageSize`. |
| POST   | `/{bookingId}/cancel`                  |  u   | Cancel. Body requires `reason` (5–1000 chars).                    |
| GET    | `/{bookingId}/alternatives`            |  u   | Reassignment info when current helper declined / timed out.       |
| GET    | `/{bookingId}/status`                  |  u   | Lightweight status endpoint (polling friendly).                   |

### 12.2 Helper — Bookings (`/api/helper/bookings`)

| Verb   | Path                              | Auth | Purpose                                                                  |
| ------ | --------------------------------- | :--: | ------------------------------------------------------------------------ |
| GET    | `/dashboard`                      |  h   | Today's earnings + counters + active trip summary.                       |
| POST   | `/availability`                   |  h   | Update `HelperAvailabilityState`. Body: `{ "availabilityState": "..." }`. |
| GET    | `/requests`                       |  h   | Paginated incoming requests. Optional `type` filter.                     |
| GET    | `/requests/{bookingId}`           |  h   | Full request detail for the accept/decline decision.                     |
| POST   | `/requests/{bookingId}/accept`    |  h   | Accept. Body: none.                                                      |
| POST   | `/requests/{bookingId}/decline`   |  h   | Decline. Body: `{ "reason": "..." }` (optional, ≤ 1000 chars).           |
| GET    | `/upcoming`                       |  h   | Confirmed future bookings assigned to me.                                |
| GET    | `/active`                         |  h   | The currently `InProgress` booking, or `null`.                           |
| POST   | `/{bookingId}/start`              |  h   | Start the trip (state → `InProgress`). Body: none.                       |
| POST   | `/{bookingId}/end`                |  h   | End the trip (state → `Completed`). Body: none.                          |
| GET    | `/history`                        |  h   | Past bookings. Optional `status`, `from`, `to`.                          |
| GET    | `/earnings`                       |  h   | Today / week / month totals + recent items.                              |
| GET    | `/{bookingId}`                    |  h   | Full helper-side booking detail.                                         |

### 12.3 Helper — Location & Tracking

| Verb | Path                                           | Auth | Purpose                                                             |
| ---- | ---------------------------------------------- | :--: | ------------------------------------------------------------------- |
| POST | `/api/helper/location/update`                  |  h   | **HTTP fallback** for `SendLocation`. Use hub whenever possible.    |
| GET  | `/api/helper/location/status`                  |  h   | Is my location fresh? Am I eligible for Instant?                    |
| GET  | `/api/helper/location/instant-eligibility`     |  h   | Diagnostic: explains every reason the helper might be excluded.     |

### 12.4 Trip tracking (both actors — participants only)

| Verb | Path                                         | Auth | Purpose                                   |
| ---- | -------------------------------------------- | :--: | ----------------------------------------- |
| GET  | `/api/booking/{bookingId}/tracking/latest`   | u/h  | Latest known helper position.             |
| GET  | `/api/booking/{bookingId}/tracking/history`  | u/h  | Full polyline (capped).                   |

### 12.5 Payments

| Verb | Path                                           | Auth  | Purpose                                         |
| ---- | ---------------------------------------------- | :---: | ----------------------------------------------- |
| POST | `/api/payments/booking/{bookingId}/initiate`   |  u    | Start a payment attempt (see §9).              |
| GET  | `/api/payments/{paymentId}`                    |  u    | Read one payment row.                          |
| GET  | `/api/payments/booking/{bookingId}/latest`     |  u    | Latest payment for a booking.                  |
| POST | `/api/payments/mock/{paymentId}/complete`      | none  | **Used by the mock HTML page only** — do not call from the app. |

### 12.6 Chat

| Verb   | Path                                              | Auth  | Purpose                  |
| ------ | ------------------------------------------------- | :---: | ------------------------ |
| GET    | `/api/chat/bookings/{bookingId}/messages`         | u/h   | Paginated history.       |
| POST   | `/api/chat/bookings/{bookingId}/messages`         | u/h   | Send a new message.      |
| POST   | `/api/chat/bookings/{bookingId}/messages/read`    | u/h   | Mark messages as read.   |

---

## 13. Complete Real-Time Event Catalog

All payloads include the standard envelope (`eventId`, `occurredAt`, `v`).

### 13.1 `RequestIncoming` (helper only)

```jsonc
{
  "bookingId": "bk_...", "helperId": "hlp_...", "userId": "usr_...",
  "bookingType": "Instant",    // or "Scheduled"
  "isUrgent": true,            // Instant → true
  "travelerName": "Ahmed A.",
  "travelerCountry": "Egypt",            // nullable
  "travelerProfileImage": "https://...", // nullable
  "destinationCity": "Cairo",
  "destinationName": "Giza Pyramids",    // nullable for instant, required for scheduled
  "requestedDate": "2026-04-24T00:00:00Z",
  "startTime": "10:00:00",
  "durationInMinutes": 240,
  "requestedLanguage": "en",             // nullable
  "requiresCar": true,
  "travelersCount": 3,
  "estimatedPayout": 320.00,             // nullable
  "attemptOrder": 1,
  "responseDeadline": "2026-04-24T10:00:30Z"  // nullable
}
```

### 13.2 `RequestRemoved` (helper only)

```jsonc
{
  "bookingId": "bk_...", "helperId": "hlp_...",
  "reason": "AcceptedByOther"   // see RequestRemovalReason enum
}
```

### 13.3 `BookingStatusChanged` (user + helper)

```jsonc
{
  "bookingId": "bk_...", "userId": "usr_...",
  "helperId": "hlp_...",         // nullable until accepted
  "oldStatus": "PendingHelperResponse",
  "newStatus": "ConfirmedAwaitingPayment",
  "paymentStatus": "AwaitingPayment"   // nullable
}
```

### 13.4 `BookingCancelled` (user + helper + booking room)

```jsonc
{
  "bookingId": "bk_...", "userId": "usr_...",
  "helperId": "hlp_...",              // nullable
  "cancelledBy": "User",              // "User" | "Helper" | "System"
  "reason": "Plans changed."          // nullable
}
```

### 13.5 `BookingPaymentChanged`

```jsonc
{
  "bookingId": "bk_...", "userId": "usr_...", "helperId": "hlp_...",
  "paymentId": "pay_...",
  "amount": 450.00, "currency": "EGP",
  "method": "MockCard",
  "status": "Paid",                   // Paid | Failed | Refunded
  "failureReason": null,              // populated when status=Failed
  "refundedAmount": null              // populated when status=Refunded
}
```

### 13.6 `BookingTripStarted` (booking room)

```jsonc
{
  "bookingId": "...", "userId": "...", "helperId": "...",
  "startedAt": "2026-04-24T09:58:00Z"
}
```

### 13.7 `BookingTripEnded` (booking room)

```jsonc
{
  "bookingId": "...", "userId": "...", "helperId": "...",
  "completedAt": "2026-04-24T13:58:00Z",
  "finalPrice": 620.00,                   // nullable
  "paymentStatus": "AwaitingPayment"      // NotRequired | AwaitingPayment | Paid
}
```

### 13.8 `HelperLocationUpdate` (booking room)

See §10.3.

### 13.9 `HelperDashboardChanged` (helper)

```jsonc
{
  "helperId": "hlp_...",
  "pendingRequestsDelta": -1,
  "upcomingTripsDelta":   +1,
  "completedTripsDelta":  0,
  "todayEarningsDelta":   150.00,
  "bookingId": "bk_..."    // nullable
}
```

### 13.10 `HelperAvailabilityChanged` (helper)

```jsonc
{
  "helperId": "hlp_...",
  "availabilityState": "Busy",
  "isOnline": true
}
```

### 13.11 `ChatMessage` (whichever side is the recipient)

```jsonc
{
  "bookingId": "bk_...",
  "conversationId": "conv_...",
  "messageId": "msg_...",
  "senderId": "usr_...",    "senderType": "User",    "senderName": "Ahmed",
  "recipientId": "hlp_...", "recipientType": "Helper",
  "messageType": "Text",
  "preview": "See you at the hotel at 10.",
  "sentAt": "2026-04-24T17:12:10Z"
}
```

### 13.12 Other events (not booking-specific, but delivered on the same connection)

| Handler                         | One-line description |
| ------------------------------- | -------------------- |
| `HelperApprovalChanged`         | `{ helperId, isApproved }` + timestamps. |
| `HelperBanStatusChanged`        | `{ helperId, isBanned, reason }` |
| `HelperSuspensionChanged`       | `{ helperId, isSuspended, until }` |
| `HelperDeactivatedByDrugTest`   | `{ helperId, reason }` |
| `InterviewDecision`             | `{ helperId, decision, note }` |
| `HelperReportResolved`          | `{ reportId, outcome }` |
| `ReportResolved`                | `{ reportId, direction, outcome }` |
| `SosTriggered`                  | `{ sosId, bookingId, triggeredBy }` |
| `SosResolved`                   | `{ sosId, resolution }` |
| `Pong`                          | `long serverTimestampMs` |

---

## 14. Flutter Implementation Blueprint

### 14.1 One hub per session — service skeleton

```dart
import 'package:signalr_netcore/signalr_client.dart';

class BookingHubService {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  HubConnection? _hub;

  BookingHubService({required this.baseUrl, required this.tokenProvider});

  Future<void> start() async {
    final url = '$baseUrl/hubs/booking';

    _hub = HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => (await tokenProvider()) ?? '',
            skipNegotiation: false,
            transport: HttpTransportType.WebSockets,
          ),
        )
        .withAutomaticReconnect(retryDelays: const [0, 2000, 5000, 10000, 15000])
        .build();

    _registerHandlers();   // MUST happen before start()

    await _hub!.start();
  }

  Future<void> stop() async => _hub?.stop();

  Future<void> sendLocation(double lat, double lng,
      {double? heading, double? speedKmh, double? accuracyMeters}) async {
    // positional args, not an object
    await _hub!.invoke('SendLocation', args: <Object?>[
      lat, lng, heading, speedKmh, accuracyMeters,
    ]);
  }

  void _registerHandlers() {
    _hub!
      ..on('RequestIncoming',        (args) => _onRequestIncoming(args!.first))
      ..on('RequestRemoved',         (args) => _onRequestRemoved(args!.first))
      ..on('BookingStatusChanged',   (args) => _onStatusChanged(args!.first))
      ..on('BookingCancelled',       (args) => _onCancelled(args!.first))
      ..on('BookingPaymentChanged',  (args) => _onPaymentChanged(args!.first))
      ..on('BookingTripStarted',     (args) => _onTripStarted(args!.first))
      ..on('BookingTripEnded',       (args) => _onTripEnded(args!.first))
      ..on('HelperLocationUpdate',   (args) => _onHelperLocation(args!.first))
      ..on('ChatMessage',            (args) => _onChatMessage(args!.first))
      // …register every other handler you care about (see §13)
      ;
  }

  // Each handler: parse the Map<String, dynamic> → typed model → push to stream/BLoC.
}
```

### 14.2 Lifecycle hooks

- **Sign in** → obtain JWT → `hub.start()`.
- **Sign out** → `hub.stop()` and dispose.
- **App goes to background**: on iOS, the connection drops; on Android, it depends on battery policy. On return to foreground, call `start()` again if disconnected — automatic reconnect will try first.
- **On `reconnected` callback**: immediately **REST-refetch** any booking detail currently open on screen. Events that fired while you were offline are lost.

### 14.3 State sync pattern

Every screen should follow this pattern:

1. `initState` → REST fetch the authoritative state.
2. Subscribe to the relevant hub events via your BLoC/Provider.
3. On event → update local state via the same reducer used for the REST response (so both paths converge on the same model).
4. On hub reconnect or on refresh-pull → REST re-fetch.

---

## 15. Failure Modes & What to Do

| Symptom                                          | Root cause                                                           | Fix                                                                                          |
| ------------------------------------------------ | -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Hub closes with `401` during handshake           | JWT expired                                                          | Refresh auth, then `start()` again.                                                         |
| Helper keeps getting dropped to `Offline`        | No location updates for longer than `LocationStaleMinutes`           | Keep a background location stream alive; call `SendLocation` at least every few seconds.    |
| User's map is blank for 10 s after reopening     | Waiting for next live GPS sample                                     | Prime via `GET /api/booking/{id}/tracking/latest` before subscribing.                       |
| `BookingStatusChanged` arrives twice             | App re-subscribed a duplicate handler                                | Register handlers exactly once; deduplicate by `eventId`.                                   |
| `SendLocation` invoked from the user app silently no-ops | Server rejects non-helper callers                                    | Only the helper app should call `SendLocation`. The user app is read-only on the hub.       |
| Payment webview closes and app doesn't update    | Hub missed the `BookingPaymentChanged` event                         | On webview close, `GET /api/payments/{paymentId}` as a fallback before trusting local state. |
| Search returns no helpers for Instant            | No helper is `AvailableNow` **and** within radius **and** fresh     | Surface a clear empty state; optionally call the helper location diagnostic endpoint to debug a specific helper. |
| `RequestIncoming` never arrives on a new helper  | Helper didn't register `user` vs `helper` type in JWT correctly      | JWT `type` claim must be exactly `"helper"`. Verify on login.                                |

---

## 16. Developer Checklist

### Before building screens
- [ ] Confirmed base URL is `https://tourestaapi.runasp.net` in release config.
- [ ] Implemented a shared `ApiClient` that injects the JWT and unwraps the envelope.
- [ ] Added `signalr_netcore` and created `BookingHubService` as a singleton.
- [ ] Wrote enum parsers for every enum in §6 (string → dart enum, dart enum → string).

### When connecting to the hub
- [ ] Hub is started **once** per signed-in session, not per screen.
- [ ] All event handlers registered **before** `hub.start()`.
- [ ] `withAutomaticReconnect` configured.
- [ ] On reconnect → REST re-fetch open screens.

### User app — Scheduled booking screen
- [ ] `POST /scheduled/search` wired to the search form.
- [ ] `POST /scheduled` wired with **all required fields from §7.1** (destination lat/lng + name mandatory).
- [ ] Subscribe to `BookingStatusChanged` for pending → accepted transition.
- [ ] Handle `ReassignmentInProgress` and `WaitingForUserAction` via the alternatives screen.
- [ ] Pay deposit → `POST /api/payments/booking/{id}/initiate` with `method=MockCard`.
- [ ] Wait for `BookingPaymentChanged` → `Paid`, Phase `Deposit`.
- [ ] Show "Trip started" when `BookingTripStarted` arrives; open live map.
- [ ] Show "Pay balance" when `BookingTripEnded` arrives with `PaymentStatus=AwaitingPayment`.

### User app — Instant booking screen
- [ ] `POST /instant/search` wired with pickup lat/lng required.
- [ ] `POST /instant` with required pickup fields; destination optional.
- [ ] Show "Searching for another helper…" while `ReassignmentInProgress`.
- [ ] On `BookingTripEnded` → route to payment screen (`Phase=Full`).

### Helper app
- [ ] Availability toggle wired to `POST /api/helper/bookings/availability`.
- [ ] Keep live GPS stream alive (OS permission + background mode) while `AvailableNow` or `Busy`.
- [ ] Call `SendLocation` over the hub (positional args), not HTTP, whenever possible.
- [ ] Subscribe to `RequestIncoming` → show accept/decline sheet with countdown to `responseDeadline`.
- [ ] Subscribe to `RequestRemoved` → drop the sheet if reason says it's no longer actionable.
- [ ] Accept → `POST /requests/{id}/accept`. Decline → `POST /requests/{id}/decline` with optional reason.
- [ ] Start trip → `POST /{id}/start`. End trip → `POST /{id}/end`.
- [ ] Handle `HelperDashboardChanged` to animate counters without a full refresh.

### Both apps
- [ ] `ChatMessage` handler updates the chat list badge AND the open conversation if it's on screen.
- [ ] `BookingCancelled` handler clears any in-flight booking state and routes to a terminal screen.
- [ ] All dates parsed as UTC and displayed in the user's local timezone.
- [ ] Dedup every event by `eventId` before rendering.

### Before release
- [ ] Tested the full happy path on Scheduled (create → accept → deposit → trip → balance → rate).
- [ ] Tested the full happy path on Instant (create → accept → trip → full payment → rate).
- [ ] Tested helper decline + reassignment.
- [ ] Tested user cancel inside and outside the late-cancel window.
- [ ] Tested hub reconnect after forced network loss (airplane mode on/off).

---

**That's the whole booking module in one file.** If a specific endpoint's request/response changes, the only other place to look is the live Swagger UI at `https://tourestaapi.runasp.net/swagger/index.html` — this document and Swagger are designed to agree.
