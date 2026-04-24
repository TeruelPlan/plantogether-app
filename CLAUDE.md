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
The app communicates exclusively with the backend via REST — routed through Traefik (`/api/v1/`) in production, or directly to a service in development.

### Project structure

```
lib/
├── main.dart                   # App entry point
├── app.dart                    # MaterialApp + GoRouter + theme + RepositoryProviders
├── core/
│   ├── constants/              # API base URL, route names
│   ├── network/                # DioClient (BaseOptions, X-Device-Id interceptor), StompClientManager
│   ├── router/                 # AppRouter (GoRouter config, onboarding redirect)
│   ├── security/               # DeviceIdService (device UUID + display name via flutter_secure_storage)
│   ├── theme/                  # Material 3 theme (AppTheme light/dark)
│   └── utils/                  # Formatters, validators, extensions
├── features/
│   ├── splash/                 # Splash screen (initialization gate)
│   ├── onboarding/             # First-launch display name setup
│   ├── home/                   # Dashboard — user's trips list + FAB to create trip
│   ├── trip/                   # Trip CRUD, members, invitations (QR / deep link)
│   ├── poll/                   # Date polls — matrix view, YES/MAYBE/NO voting
│   ├── destination/            # Destination proposals + voting + comments
│   ├── expense/                # Budget tracking, splits, balance chart
│   ├── task/                   # Task lists, subtasks, assignments, deadlines
│   ├── chat/                   # Real-time STOMP chat
│   ├── notification/           # Notification preferences + FCM token registration
│   ├── file/                   # Presigned URL upload/download helpers
│   └── profile/                # User profile + settings (display name)
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

**Do NOT use Riverpod** — this project uses `flutter_bloc` exclusively.

### Navigation

**GoRouter** (`go_router` v13) — declarative, deep-link-aware. Routes defined in `core/constants/route_constants.dart`.
Onboarding guard redirects to `/onboarding` if no display name is set.
Use `context.push()` for stack navigation, `context.go()` for replacement.

### Authentication (Device-Based Identity)

**No login, no JWT, no Keycloak, no OIDC.** Identity is anonymous and device-based:

1. On first launch, `DeviceIdService` generates a UUID v4 and stores it in `flutter_secure_storage`
2. Every HTTP request includes `X-Device-Id: {device-uuid}` header (injected automatically by `DioClient` interceptor)
3. The backend `DeviceIdFilter` validates the UUID and sets the SecurityContext principal
4. No tokens, no expiry, no refresh logic

`DeviceIdService` (`lib/core/security/device_id_service.dart`) also manages the local display name:
- `getOrCreateDeviceId()` — returns existing or generates new UUID
- `getDisplayName()` / `setDisplayName(name)` — local display name in `flutter_secure_storage`

### HTTP client

**Dio** (`dio` v5) configured in `core/network/DioClient`. Interceptors:
- `X-Device-Id` interceptor — injects device UUID header on every request
- Logging interceptor (debug only)

Base URL: `API_BASE_URL` env var (defaults to `http://127.0.0.1:8081` in dev).
In production, points to Traefik gateway (`https://api.plantogether.com`).

### WebSocket (STOMP)

`stomp_dart_client` connects to `/ws` on Traefik. Used in `features/chat/`:
- Subscribe `/topic/trips/{tripId}/chat` — receive messages
- Subscribe `/topic/trips/{tripId}/updates` — real-time updates (expenses, votes, etc.)
- Subscribe `/user/queue/notifications` — private notifications
- Send `/app/trips/{tripId}/chat` — send a message

Device ID passed in STOMP `connect` headers.

### Local storage

`flutter_secure_storage` exclusively for device UUID and display name.
No `shared_preferences` currently used.

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
| `flutter_secure_storage` | ^9.0.0 | Device UUID + display name storage |
| `stomp_dart_client` | ^1.1.0 | WebSocket STOMP (chat) |
| `firebase_core` + `firebase_messaging` | ^2 / ^14 | FCM push notifications |
| `freezed` + `freezed_annotation` | ^2.5 / ^2.4 | Immutable models + unions |
| `json_serializable` + `json_annotation` | ^6.8 / ^4.9 | JSON serialisation |
| `cached_network_image` | ^3.3.1 | Image loading + caching |
| `image_picker` + `file_picker` | ^1.1 / ^8.0 | File/image selection for uploads |
| `intl` | ^0.19.0 | Internationalisation + date formatting |
| `equatable` | ^2.0.5 | Value equality for BLoC events/states |
| `uuid` | ^4.4.0 | UUID generation client-side |
| `qr_flutter` | — | QR code generation (trip invitations) |
| `fl_chart` | — | Charts (budget pie chart) |

### Environment / configuration

API URL is defined via `--dart-define` flag or defaults:

```
API_BASE_URL=https://api.plantogether.com   # production (Traefik gateway)
API_BASE_URL=http://127.0.0.1:8081          # development (direct to trip-service)
```

### Testing conventions

- **Unit:** BLoC tests with `bloc_test`, repository tests with `mocktail` (NOT mockito)
- **Widget:** `flutter_test` for individual components and forms
- **Integration:** `integration_test` package for full end-to-end flows on emulator
- **Runtime driver:** `marionette_flutter` is initialized in `main.dart` (debug-only, skipped under `FLUTTER_TEST`). Drive the running app from AI agents / Marionette MCP via VM service URI.

### ValueKey convention (MANDATORY for interactive widgets)

Every **interactive widget** MUST carry a stable `ValueKey<String>`. This is non-negotiable: Marionette MCP, widget tests, and integration tests rely on keys to locate elements reliably — text matching is brittle (localization, truncation) and coordinate matching is fragile (layout changes). Apply this rule to new code and to any existing widget you edit.

**Required on:**
- All `TextFormField` / `TextField`
- All buttons: `ElevatedButton`, `FilledButton`, `TextButton`, `OutlinedButton`, `IconButton`, `FloatingActionButton`
- All toggles: `Checkbox`, `Switch`, `Radio`, `SegmentedButton`
- All `DropdownButton` / `DropdownButtonFormField`
- `ListView` / `GridView` that tests scroll through (e.g. `destinations_list`)
- Per-item cards in dynamic lists (include the domain id, e.g. `destination_card_${d.id}`)
- Empty states, error states, loading indicators when they are asserted by tests

**Naming rules:**
- Format: `snake_case`, feature-prefixed, purpose-suffixed. Examples: `propose_name_field`, `propose_submit_button`, `vote_simple_button`, `vote_mode_selector`, `destinations_empty_state`, `destination_card_<id>`.
- Use `const ValueKey('...')` except when the key embeds a runtime value (then just `ValueKey('...')`).
- Keep keys stable across refactors — tests and MCP scripts depend on them.

**Example:**

```dart
TextFormField(
  key: const ValueKey('propose_name_field'),
  controller: _nameController,
  // ...
)

FilledButton(
  key: const ValueKey('propose_submit_button'),
  onPressed: _submit,
  child: const Text('Propose'),
)

DestinationProposalCard(
  key: ValueKey('destination_card_${d.id}'),
  destination: d,
)
```

**Also: make whole rows tappable.** When a row contains a small control (radio, checkbox) plus a label, wrap the `Row` in an `InkWell` / `GestureDetector` so tapping the label or whitespace also triggers the action. A tiny hit target is unreachable for both users and Marionette text-based taps.

Test files mirror the `lib/` structure under `test/`.
