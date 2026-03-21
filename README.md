# PlanTogether Flutter Application

> Application mobile multi-plateforme (iOS, Android) et web PWA pour la planification collaborative de voyages

## Rôle dans l'architecture

L'application Flutter est le client unique de PlanTogether. Elle communique avec les microservices backend
**uniquement via Traefik** (reverse proxy) à travers des endpoints REST unifiés. Elle ne connaît pas la
décomposition en microservices. La résolution des noms d'utilisateurs se fait côté Flutter (à partir de la
liste des membres maintenue en mémoire), ce qui évite tout stockage de PII côté serveur dans les services
autre que le Trip Service.

## Fonctionnalités

- Authentification OIDC + PKCE via Keycloak (flux Authorization Code)
- Gestion complète des voyages (création, membres, invitations QR code)
- Sondages de dates (vote YES / MAYBE / NO)
- Propositions et votes de destinations
- Gestion du budget partagé (dépenses, répartition, équilibrage)
- To-do list collaborative (tâches, sous-tâches, deadlines)
- Chat groupe temps réel (WebSocket STOMP)
- Notifications push (FCM) et in-app
- Mode offline (cache Hive)

## Architecture technique

L'application suit une **Clean Architecture** avec des modules par feature :

```
plantogether-app/
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp, GoRouter, Material 3 theme
│   ├── core/
│   │   ├── auth/                     # PKCE (flutter_appauth), token storage sécurisé
│   │   ├── network/                  # DioClient, AuthInterceptor, StompClient
│   │   ├── theme/                    # Material 3 theme
│   │   └── constants/                # Gateway URL, Keycloak config
│   ├── features/
│   │   ├── home/                     # Dashboard
│   │   ├── trip/                     # data/ domain/ presentation/
│   │   ├── poll/
│   │   ├── destination/
│   │   ├── expense/
│   │   ├── task/
│   │   ├── chat/                     # Client STOMP
│   │   ├── notification/
│   │   └── profile/                  # Settings, préférences notifications
│   └── shared/                       # Widgets, providers, utils
├── test/
└── pubspec.yaml
```

Chaque feature contient trois couches :
- `data/` — repositories, datasources (Dio + Hive), DTOs
- `domain/` — entités métier, use cases, interfaces repository
- `presentation/` — widgets, pages, Riverpod providers

## Flux d'authentification (OIDC + PKCE)

1. L'utilisateur appuie sur « Se connecter »
2. Flutter génère un `code_verifier` + `code_challenge` (SHA-256)
3. Flutter ouvre le navigateur système vers Keycloak (`/realms/plantogether/protocol/openid-connect/auth`)
4. L'utilisateur s'authentifie (email/mdp ou OAuth Google/Apple/Facebook)
5. Keycloak redirige vers `com.plantogether://callback?code={code}`
6. Flutter échange `code` + `code_verifier` contre `access_token` (5 min) + `refresh_token` (30 jours)
7. Tokens stockés dans `flutter_secure_storage` (Keychain iOS / Keystore Android)
8. Chaque appel API inclut le header `Authorization: Bearer {access_token}`
9. Traefik route vers le microservice cible qui valide le JWT

## Packages principaux

| Package | Usage |
|---------|-------|
| `flutter_appauth` | Flux OIDC + PKCE avec Keycloak |
| `flutter_secure_storage` | Stockage sécurisé des tokens (Keychain / Keystore) |
| `dio` | Client HTTP avec intercepteurs (auth, retry, logging) |
| `flutter_riverpod` | State management réactif |
| `go_router` | Navigation déclarative, deep linking |
| `stomp_dart_client` | Client WebSocket STOMP (chat temps réel) |
| `hive_flutter` | Cache local pour le mode offline |
| `fl_chart` | Graphiques (camembert budget) |
| `firebase_messaging` | Notifications push FCM |
| `qr_flutter` | Génération QR codes (invitations) |
| `freezed` + `json_serializable` | Modèles immuables + sérialisation JSON |
| `intl` | Internationalisation et formatage |

## Commandes

```bash
cd plantogether-app

# Installer les dépendances
flutter pub get

# Générer les modèles (freezed, Hive adapters)
flutter packages pub run build_runner build

# Lancer en développement
flutter run -d chrome                        # Web
flutter run                                  # Mobile (émulateur ou device)

# Tests
flutter test                                 # Tous les tests
flutter test test/features/trip/             # Feature spécifique
flutter test --coverage                      # Avec rapport de couverture

# Build
flutter build apk                            # Android
flutter build ipa                            # iOS
flutter build web                            # Web PWA
```

## Configuration

La Gateway URL et la configuration Keycloak sont définies dans `lib/core/constants/` :

```dart
// gateway_config.dart
const String gatewayBaseUrl = String.fromEnvironment(
  'GATEWAY_URL',
  defaultValue: 'http://localhost:80',
);

// keycloak_config.dart
const String keycloakUrl = 'http://localhost:8080';
const String keycloakRealm = 'plantogether';
const String keycloakClientId = 'plantogether-app';
const String redirectUri = 'com.plantogether://callback';
```

## Stratégie de déploiement

- **Web PWA** : déployé sur Vercel via GitHub Actions
- **Android** : `flutter build appbundle` + upload Google Play (Fastlane)
- **iOS** : `flutter build ipa` + upload TestFlight (Fastlane)

## Architecture des tests

| Niveau | Outil | Cible | Couverture |
|--------|-------|-------|------------|
| Unitaires | `flutter_test` | Riverpod providers, use cases, repositories | > 80% |
| Widget | `flutter_test` (widget) | Composants UI, formulaires | > 70% |
| E2E | `integration_test` | Parcours complets sur émulateur | Parcours critiques |

## Sécurité

- Tokens stockés exclusivement dans `flutter_secure_storage` (jamais en localStorage)
- TLS 1.3 sur toutes les communications réseau
- PKCE protège contre l'interception de l'`authorization_code`
- Refresh token rotation automatique via `flutter_appauth`
