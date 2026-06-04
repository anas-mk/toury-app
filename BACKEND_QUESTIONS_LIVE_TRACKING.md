# Live Tracking — Open Questions for Backend Team

> **Context**: The user app's live-track screen is empty after the helper
> accepts an instant booking. We don't see helper position, ETA, or any
> `HelperLocationUpdate` events on the user side. We've confirmed the
> client wiring is correct against the realtime guide (`Flutter-Booking-
> Realtime-Guide.md`); these are the questions we still need answered to
> close out the feature.

---

## What we already verified on our side ✅

The client wiring matches the docs verbatim:

1. **One SignalR connection** to `/hubs/booking` opened on login (confirmed
   via `BookingTrackingHubService` logs).
2. **Bearer token** is forwarded on the negotiate request (HttpConnectionOptions
   `accessTokenFactory`).
3. **Subscribed handlers** include `HelperLocationUpdate`,
   `BookingStatusChanged`, `BookingTripStarted`, `BookingTripEnded`, and
   `ChatMessage` (visible in `_registeredHandlers` on the diagnostics page).
4. **Auto-reconnect** via `signalr_netcore`'s `withAutomaticReconnect`.
5. We do **not** call `JoinBookingRoom` for tracking — the doc (§ 4) says the
   server auto-joins us to every active booking room.
6. We **prime** the map on mount via `GET /api/booking/{id}/tracking/latest`
   (§ 10.3) — this 404s today because no GPS has been broadcast yet.

Given the above, on the user side everything is in place. The events just
aren't flowing. So the questions below are about the **server-side
broadcast policy** + a few minor schema confirmations.

---

## Critical question 1 — When does the server start broadcasting `HelperLocationUpdate`?

**Observation**: After helper accepts an instant booking
(`status = AcceptedByHelper`), the user opens the live-track screen and
sees no map / no ETA. We never receive a `HelperLocationUpdate` event
on the user's hub.

The helper app does call `hub.invoke('SendLocation', …)` on every GPS
sample once they open the active-booking page (i.e. the moment they
accept). We can confirm this from the helper app logs.

The doc says (§ 10):
> Only active during `InProgress`. Both parties see the helper's live
> position on a map.

So we need to confirm:

1. **Is GPS broadcast gated on `status == InProgress` only?**
   I.e. do you discard / stop relaying `SendLocation` calls from the
   helper app while the booking is still `AcceptedByHelper`?
2. If yes — that's the spec, and we'll just match the user's UI accordingly
   (we already render a friendly "Helper accepted · Heading your way"
   pre-start state).
3. If no — i.e. you're supposed to relay the helper's GPS during
   `AcceptedByHelper` as well — then we likely have a server bug; could
   you check the broadcast logic in the SignalR hub for that status?

> **Why it matters**: in the instant-booking UX, between `AcceptedByHelper`
> and `InProgress` is exactly when the user wants to see the helper
> approaching the pickup point. If the spec is "no GPS until `/start`",
> we need to surface that explicitly to the user.

---

## Critical question 2 — When exactly do you push `BookingTripStarted`?

**Observation**: Even after the helper hits `POST /api/helper/bookings/{id}/start`
on their app, the user side doesn't visibly transition into "trip in
progress" mode. We need to confirm the wiring.

Could you confirm:

1. The user is **always** in the `booking:{bookingId}` room as soon as
   the booking is created (per § 4), and stays there through `Completed`?
2. `BookingTripStarted` is broadcast to **both** `user:{userId}` AND
   `booking:{bookingId}` groups, or to just one?
3. The event payload exact field names — we're matching against:
   ```json
   {
     "bookingId": "…",
     "userId": "…",
     "helperId": "…",
     "startedAt": "ISO-8601",
     "eventId": "…",
     "occurredAt": "ISO-8601"
   }
   ```

If any of these differ, we'd need to know.

---

## Critical question 3 — `GET /api/booking/{id}/tracking/latest` returns 404 — is that expected?

When the user opens the live-track screen for a booking in
`AcceptedByHelper` status (helper hasn't started yet), this endpoint
returns 404. We currently swallow it silently and rely on the SignalR
event later.

Could you confirm:

1. **Is the 404 the canonical "no tracking data yet" response?** Or
   should we expect 200 with an empty body / null fields?
2. Once the helper presses Start, does the next call to `tracking/latest`
   return a real position (lat/lng + ETA) immediately, or is there a
   delay until the next GPS sample arrives?
3. Does the response include the same fields as the `HelperLocationUpdate`
   event payload (`distanceToPickupKm`, `etaToPickupMinutes`,
   `distanceToDestinationKm`, `etaToDestinationMinutes`, `phase`)?
   We've extended our model to read these — if the REST shape differs
   we need to know.

---

## Critical question 4 — `phase` field values?

The `HelperLocationUpdate.phase` field — what string values does the
server send today? Our code currently handles:

- `"ToPickup"` — helper is heading to the user's pickup point.
- `"ToDestination"` — user has been picked up, heading to destination.
- `"OnTheWay"` — legacy alias for ToPickup.
- `"InProgress"` — legacy alias for ToDestination.

If you send other phase strings, please share the full enum so we can
map them correctly.

---

## Critical question 5 — Do you want us to subscribe differently for instant vs scheduled?

The doc treats both flows the same way for tracking, but our experience
suggests instant might need an earlier broadcast (during accepted phase,
not just InProgress).

If the product decision is **"instant tracking starts at accept"** while
**"scheduled tracking starts at /start"**, we'd love to see that codified
in the broadcast logic. Today both behave like scheduled (no broadcast
until /start).

---

## Helpful — but not blocking

### Q6: Is there a "request ETA preview" REST endpoint?

Pre-trip-start, when the helper accepted but hasn't begun, can we call
something like `GET /api/booking/{id}/eta-preview` that returns a
backend-computed ETA based on the helper's last known position +
pickup point? This would let the user app show "Helper is ~ N min
away from pickup" before the trip starts, giving a nicer UX between
accept and start.

If this isn't planned, no problem — we'll just keep the friendly
"Heading your way" copy.

### Q7: SignalR diagnostics

When we call `Ping()` from the user side, do you log it server-side?
We'd love to be able to verify "yes user X is in booking Y's room" from
your end during debugging. If there's an admin endpoint for that we'd
appreciate the URL.

---

## Summary of the smallest-possible asks

To unblock the feature **today** we only need answers to **Q1, Q2, Q3,
Q4**. Everything else is polish.

If the answer to Q1 is "GPS only flows during `InProgress`", then this
is **not** a bug in either app — it's the spec, and we'll keep the
"pre-start" UX as-is. Please confirm so we can close the ticket.
