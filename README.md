# PlanTogether Flutter Application

> Cross-platform mobile (iOS, Android) and web PWA application for collaborative travel planning

## Role in the Architecture

The Flutter app is the single client of PlanTogether. It communicates with the backend microservices
**exclusively via Traefik** (reverse proxy) through unified REST endpoints. It is unaware of the
microservice decomposition. User name resolution is performed client-side by Flutter (from the member
list kept in memory), which avoids any PII storage on the server side in services other than the Trip Service.

## Features

- Anonymous device-based identity (no login, no account creation)
- Full trip management (creation, members, QR code / deep link invitations)
- Date polls (vote YES / MAYBE / NO)
- Destination proposals and voting
- Shared budget tracking (expenses, splits, balance chart)
- Collaborative to-do list (tasks, subtasks, deadlines)
- Real-time group chat (WebSocket STOMP)
- Push notifications (FCM) and in-app
- Offline mode (local cache)

## Technical Architecture

The application follows a **Clean Architecture** with feature-based modules:

```
plantogether-app/
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp, GoRouter, Material 3 theme
│   ├── core/
│   │   ├── security/                 # DeviceIdService (UUID generation + storage)
│   │   ├── network/                  # DioClient (X-Device-Id interceptor), StompClient
│   │   ├── theme/                    # Material 3 theme
│   │   └── constants/                # Gateway URL
│   ├── features/
│   │   ├── home/                     # Dashboard
│   │   ├── trip/                     # data/ domain/ presentation/
│   │   ├── poll/
│   │   ├── destination/
│   │   ├── expense/
│   │   ├── task/
│   │   ├── chat/                     # STOMP client
│   │   ├── notification/
│   │   └── profile/                  # Settings, notification preferences
│   └── shared/                       # Widgets, providers, utils
├── test/
└── pubspec.yaml
```

Each feature contains three layers:
- `data/` — repositories, datasources (Dio + local cache), DTOs
- `domain/` — business entities, use cases, repository interfaces
- `presentation/` — widgets, pages, BLoC providers

## Authentication (Device-Based Identity)

**No login, no JWT, no Keycloak, no OIDC, no tokens, no sessions.**

1. On first launch, `DeviceIdService` generates a UUID v4 and stores it in `flutter_secure_storage` (Keychain iOS / Keystore Android)
2. Every API call includes the `X-Device-Id: {device-uuid}` header (injected automatically by the Dio interceptor)
3. The backend `DeviceIdFilter` validates the UUID and sets the SecurityContext principal
4. No token expiry, no refresh logic

## Key Packages

| Package | Usage |
|---------|-------|
| `flutter_secure_storage` | Device UUID and display name storage (Keychain / Keystore) |
| `flutter_bloc` | State management (BLoC pattern) |
| `dio` | HTTP client with interceptors (X-Device-Id, retry, logging) |
| `go_router` | Declarative navigation, deep linking |
| `stomp_dart_client` | WebSocket STOMP client (real-time chat) |
| `firebase_messaging` | FCM push notifications |
| `freezed` + `json_serializable` | Immutable models + JSON serialization |
| `fl_chart` | Charts (budget pie chart) |
| `qr_flutter` | QR code generation (invitations) |
| `intl` | Internationalization and formatting |

## Commands

```bash
cd plantogether-app

# Install dependencies
flutter pub get

# Generate models (freezed, adapters)
flutter packages pub run build_runner build

# Run in development
flutter run -d chrome                        # Web
flutter run                                  # Mobile (emulator or device)

# Tests
flutter test                                 # All tests
flutter test test/features/trip/             # Specific feature
flutter test --coverage                      # With coverage report

# Build
flutter build apk                            # Android
flutter build ipa                            # iOS
flutter build web                            # Web PWA
```

## Configuration

The Gateway URL is defined in `lib/core/constants/`:

```dart
// gateway_config.dart
const String gatewayBaseUrl = String.fromEnvironment(
  'GATEWAY_URL',
  defaultValue: 'http://localhost:80',
);
```

## Deployment Strategy

- **Web PWA**: deployed on Vercel via GitHub Actions
- **Android**: `flutter build appbundle` + upload to Google Play (Fastlane)
- **iOS**: `flutter build ipa` + upload to TestFlight (Fastlane)

## Test Architecture

| Level | Tool | Target | Coverage |
|-------|------|--------|----------|
| Unit | `flutter_test` | BLoC providers, use cases, repositories | > 80% |
| Widget | `flutter_test` (widget) | UI components, forms | > 70% |
| E2E | `integration_test` | Full flows on emulator | Critical paths |

## Security

- Device UUID stored exclusively in `flutter_secure_storage` (never in localStorage)
- TLS 1.3 on all network communications
- `X-Device-Id` header injected automatically on every request
- No tokens, no secrets stored client-side beyond the device UUID
