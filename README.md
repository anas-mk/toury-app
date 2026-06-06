# Toury

**Toury** is a smart tourism platform that connects **tourists visiting Egypt** with professional **local tour guides** who speak their language — like **Uber, but for tourism**.

Tourists can book a guide instantly or schedule a trip in advance. Guides manage their profile, availability, and active trips from a dedicated dashboard. The app supports **Arabic & English**, **light/dark themes**, **live trip tracking**, **real-time updates**, and **push notifications**.

---

## Features

### Tourist

- **Authentication** — Email/password, Google sign-in, OTP verification, password reset
- **Instant booking** — Pick location, duration, and nearby helpers; pay and track the trip live
- **Scheduled booking** — Search helpers by date, language, and preferences; review and confirm
- **Live tracking** — Real-time helper location on Mapbox maps via SignalR
- **In-app chat** — Message your guide during the trip
- **Payments** — Secure payment flow with WebView integration
- **Ratings & reviews** — Rate completed trips; browse helper reviews
- **Invoices** — View and download trip invoices
- **My bookings** — History and active trip management

### Guide (Helper)

- **Authentication & onboarding** — Register, verify email/phone, complete profile
- **Profile & verification** — Identity documents, selfie, vehicle info, certificates
- **Language interview** — Language exams and interview flow
- **Service areas** — Define where you operate
- **Availability & bookings** — Accept/reject requests, manage active trips, end trips
- **Live location sharing** — Background location tracking during active trips
- **Dashboard** — Earnings, wallet, invoices, and booking center
- **Chat & notifications** — Real-time messages and FCM push alerts
- **Ratings & reports** — View ratings and submit reports
- **SOS** — Emergency assistance during active trips

### Shared

- **Role selection** — Tourist or Guide at launch
- **Bilingual UI** — English & Arabic with RTL support
- **Dark & light themes**
- **Real-time sync** — SignalR hub for booking status, tracking, and chat events

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x (Dart ^3.9) |
| State management | `flutter_bloc` (Cubit) |
| Architecture | Clean Architecture (data / domain / presentation) |
| DI | `get_it` |
| Routing | `go_router` |
| HTTP | `dio` + `retrofit` |
| Real-time | `signalr_netcore` |
| Maps | `mapbox_maps_flutter` |
| Push notifications | `firebase_messaging` + `flutter_local_notifications` |
| Location | `geolocator`, `geocoding`, background service |
| Local storage | `shared_preferences` |

---

## Project Structure

```
lib/
├── app.dart                  # MaterialApp, theme & locale
├── main.dart                 # Bootstrap (Firebase, Mapbox, DI, SignalR)
├── core/
│   ├── config/               # API endpoints & constants
│   ├── di/                   # Dependency injection
│   ├── localization/         # i18n (en / ar)
│   ├── network/              # Dio, interceptors
│   ├── router/               # GoRouter routes
│   ├── services/             # SignalR, FCM, location, SOS
│   ├── theme/                # Design system & themes
│   └── widgets/              # Shared UI components
└── features/
    ├── splash/               # Splash & role selection
    ├── user/                 # Tourist flows
    │   ├── auth/
    │   ├── home/
    │   ├── user_booking/     # Instant & scheduled booking
    │   ├── user_chat/
    │   ├── payments/
    │   ├── user_ratings/
    │   └── user_invoices/
    └── helper/               # Guide flows
        ├── auth/
        ├── profile/
        ├── helper_bookings/
        ├── helper_location/
        ├── helper_chat/
        ├── helper_invoices/
        ├── language_interview/
        ├── helper_service_areas/
        ├── helper_sos/
        └── ...
```

---

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.9
- Android Studio / VS Code with Flutter extensions
- A [Mapbox](https://www.mapbox.com/) access token (public `pk.` token)
- A [Firebase](https://firebase.google.com/) project for push notifications

---

## Getting Started

### 1. Clone & install dependencies

```bash
git clone https://github.com/<your-username>/toury.git
cd toury
flutter pub get
```

### 2. Firebase setup

Firebase config files are **not included** in this repository (see `.gitignore`).

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Generate firebase_options.dart and google-services.json
flutterfire configure
```

Required files after setup:

| File | Platform |
|------|----------|
| `lib/firebase_options.dart` | Dart |
| `android/app/google-services.json` | Android |
| `ios/Runner/GoogleService-Info.plist` | iOS |

> Without Firebase config the app still runs, but push notifications will be disabled.

### 3. Mapbox token

Pass your Mapbox public token at build/run time:

```bash
flutter run --dart-define=MAPBOX_TOKEN=pk.your_mapbox_token_here
```

Or set it in `lib/core/config/api_config.dart` for local development only — **do not commit real tokens to a public repo**.

### 4. Run the app

```bash
# Debug
flutter run --dart-define=MAPBOX_TOKEN=pk.your_token

# Release APK (Android)
flutter build apk --release --dart-define=MAPBOX_TOKEN=pk.your_token
```

---

## API

The app connects to the Toury REST API. Base URL is configured in `lib/core/config/api_config.dart`:

```
https://tourestaapi.runasp.net/api
```

Realtime events are delivered via a SignalR hub at `/hubs/booking`.

---

## Assets & Localization

| Path | Contents |
|------|----------|
| `assets/lang/` | `en.json`, `ar.json` translation files |
| `assets/logo/` | App logo & branding |
| `assets/images/` | Static images |
| `fonts/` | Custom fonts (Pacifico, Permanent Marker) |

---

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2025 Anas-MK

---

## Author

**Anas MK** — Flutter developer
