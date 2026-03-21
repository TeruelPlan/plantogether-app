# CLAUDE.md

This file provides guidance to Claude when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Generate code (freezed models + json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on change)
flutter pub run build_runner watch --delete-conflicting-outputs

# Run on Chrome
flutter run -d chrome

# Run on emulator / device
flutter run

# Run all tests
flutter test

# Run a specific test file
flutter test test/features/trip/bloc_test.dart

# Analyse (lint)
flutter analyze

# Build for production
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android App Bundle (Play Store)
flutter build ios --release          # iOS
flutter build web --release          # Web
```

## Architecture

Flutter 3.19+ / Dart 3.x cross-platform app (iOS, Android, Web). Clean Architecture with feature-based modules.
The app communicates exclusively with Traefik (`/api/v1/`) via REST — it has no awareness of the
microservices behind it.

### Project structure

```
lib/
├── main.dart                   # App entry point + Firebase init
├── app.dart                    # MaterialApp + GoRouter + theme
├── core/
│   ├── auth/                   # OIDC/PKCE flow (flutter_appauth + flutter_secure_storage)
│   ├── constants/              # Gateway URL, Keycloak config, route names
│   ├── network/                # DioClient (BaseOptions, interceptors), StompClient
│   ├── security/               # Token refresh interceptor, secure storage helpers
│   ├── theme/                  # Material 3 theme (Inter font, color scheme)
│   └── utils/                  # Formatters, validators, extensions
├── features/
│   ├── auth/                   # Login / PKCE callback / logout
│   ├── home/                   # Dashboard — user's trips list
│   ├── trip/                   # Trip CRUD, members, invitations (QR / deep link)
│   ├── poll/                   # Date polls — matrix view, YES/MAYBE/NO voting
│   ├── destination/            # Destination proposals + voting + comments
│   ├── expense/                # Budget tracking, splits, balance chart
│   ├── task/                   # Task lists, subtasks, assignments, deadlines
│   ├── chat/                   # Real-time STOMP chat
│   ├── notification/           # Notification preferences + FCM token registration
│   ├── file/                   # Presigned URL upload/download helpers
│   └── profile/                # User profile settings
└── shared/
    ├── providers/              # Shared BLoC / state
    ├── widgets/                # Reusable UI components (MemberAvatar, TripCard, etc.)
    └── utils/                  # Shared helpers
```

Each feature follows Clean Architecture layers: `data/` (repositories, DTOs, datasources), `domain/`
(entities, use cases, repository interfaces), `presentation/` (BLoC, pages, widgets).

### State management

**BLoC** (`flutter_bloc` v8) for all features. Pattern:
- `*Bloc` — event/state machine
- `*Event` — immutable inputs (Equatable)
- `*State` — immutable outputs (Freezed)

### Navigation

**GoRouter** (`go_router` v13) — declarative, deep-link-aware. Routes defined in `core/constants/`.
Auth guard redirects unauthenticated users to `/login`.

### Authentication (OIDC + PKCE)

`flutter_appauth` handles the Authorization Code + PKCE flow against Keycloak:
1. Opens system browser → Keycloak `/realms/plantogether/protocol/openid-connect/auth`
2. Redirect to `com.plantogether://callback`
3. Exchanges code + code_verifier for `access_token` (5 min) + `refresh_token` (30 days)
4. Tokens stored in `flutter_secure_storage` (Keychain iOS / Keystore Android)

Every HTTP request includes `Authorization: Bearer {access_token}`. The Dio `AuthInterceptor` in
`core/network/` handles transparent token refresh on 401.

### HTTP client

**Dio** (`dio` v5) configured in `core/network/DioClient`. Interceptors:
- `AuthInterceptor` — injects Bearer token, refreshes on 401
- Logging interceptor (debug only)

Base URL: `GATEWAY_URL` constant in `core/constants/` (e.g. `https://api.plantogether.com/api/v1`).

### WebSocket (STOMP)

`stomp_dart_client` connects to `/ws` on Traefik. Used in `features/chat/`:
- Subscribe `/topic/trips/{tripId}/chat` — receive messages
- Subscribe `/topic/trips/{tripId}/updates` — real-time updates (expenses, votes, etc.)
- Subscribe `/user/queue/notifications` — private notifications
- Send `/app/trips/{tripId}/chat` — send a message

Bearer token passed in STOMP `connect` headers.

### Local storage

`shared_preferences` for non-sensitive user preferences (theme, language, notification settings).
`flutter_secure_storage` exclusively for auth tokens.

### Push notifications (FCM)

`firebase_messaging` receives FCM push notifications. On first launch, the FCM token is registered via
`PUT /api/v1/notifications/fcm-token`. Background notifications handled via `FirebaseMessaging.onBackgroundMessage`.

### Code generation

Freezed (`freezed` + `freezed_annotation`) for immutable models and union types. `json_serializable` +
`json_annotation` for JSON serialisation. Run `build_runner` after modifying any annotated class.

### Key packages

| Package | Version | Purpose |
|---|---|---|
| `flutter_bloc` | ^8.1.5 | State management (BLoC pattern) |
| `go_router` | ^13.2.0 | Navigation + deep links |
| `dio` | ^5.4.3 | HTTP client with interceptors |
| `flutter_appauth` | ^7.0.1 | OIDC/PKCE authentication |
| `flutter_secure_storage` | ^9.0.0 | Secure token storage |
| `stomp_dart_client` | ^1.1.0 | WebSocket STOMP (chat) |
| `shared_preferences` | ^2.2.3 | Non-sensitive local preferences |
| `firebase_core` + `firebase_messaging` | ^2 / ^14 | FCM push notifications |
| `freezed` + `freezed_annotation` | ^2.5 / ^2.4 | Immutable models + unions |
| `json_serializable` + `json_annotation` | ^6.8 / ^4.9 | JSON serialisation |
| `cached_network_image` | ^3.3.1 | Image loading + caching |
| `image_picker` + `file_picker` | ^1.1 / ^8.0 | File/image selection for uploads |
| `intl` | ^0.19.0 | Internationalisation + date formatting |
| `equatable` | ^2.0.5 | Value equality for BLoC events/states |
| `uuid` | ^4.4.0 | UUID generation client-side |

### Environment / configuration

Keycloak and API URLs are defined as constants in `lib/core/constants/`. For multi-environment builds,
use `--dart-define` flags or a `config/` directory with per-environment files.

```
GATEWAY_URL=https://api.plantogether.com
KEYCLOAK_URL=https://auth.plantogether.com
KEYCLOAK_REALM=plantogether
KEYCLOAK_CLIENT_ID=plantogether-app
KEYCLOAK_REDIRECT_URI=com.plantogether://callback
```

### Testing conventions

- **Unit:** BLoC tests with `bloc_test`, repository tests with `mocktail`
- **Widget:** `flutter_test` for individual components and forms
- **Integration:** `integration_test` package for full end-to-end flows on emulator

Test files mirror the `lib/` structure under `test/`.
