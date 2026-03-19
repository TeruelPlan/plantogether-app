# PlanTogether Flutter Application

> Application mobile multi-plateforme (iOS, Android) et web PWA pour la planification collaborative de voyages

## Rôle

PlanTogether est l'application front-end Flutter qui offre une interface utilisateur intuitive pour la planification
collaborative de voyages. Elle supporte iOS, Android et Web (PWA) avec synchronisation en temps réel, authentification
Keycloak OIDC et notifications push FCM.

### Fonctionnalités

- **Authentification** : OIDC/PKCE avec Keycloak
- **Gestion des voyages** : Création, édition, suppression de trips collaboratifs
- **Sondages de dates** : Vote sur les dates de voyage
- **Destinations** : Sélection et vote sur les destinations
- **Budget partagé** : Suivi des dépenses et règlement des comptes
- **To-do list** : Tâches assignées avec statuts
- **Chat en temps réel** : Communication instant avec STOMP WebSocket
- **Notifications** : Push notifications via FCM
- **Stockage local** : Cache offline avec Hive
- **Navigation intuitive** : GoRouter pour la navigation performante

## Architecture

```
┌─────────────────────────────────────────┐
│   Flutter 3.x Application               │
│   (iOS, Android, Web)                   │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  lib/core/                        │  │
│  │  ├── theme/ (Colors, Styles)     │  │
│  │  ├── constants/ (URLs, Keys)     │  │
│  │  └── config/ (Keycloak setup)    │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  lib/features/                   │  │
│  │  ├── auth/                       │  │
│  │  ├── trip/                       │  │
│  │  ├── poll/                       │  │
│  │  ├── destination/                │  │
│  │  ├── expense/                    │  │
│  │  ├── task/                       │  │
│  │  ├── chat/                       │  │
│  │  └── notification/               │  │
│  │                                  │  │
│  │  (each feature has):             │  │
│  │  ├── data/                       │  │
│  │  ├── domain/                     │  │
│  │  └── presentation/               │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  lib/shared/                     │  │
│  │  ├── widgets/                    │  │
│  │  ├── utils/                      │  │
│  │  └── models/                     │  │
│  └───────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
         ▲
         │ HTTP/REST + WebSocket
         │
    ┌────┴──────────────────┐
    │  API Gateway          │
    │  (port 8080)          │
    └──────────────────────┘
```

## Concepts clés

### Clean Architecture

- **Data Layer** : Repositories, API clients, local cache
- **Domain Layer** : Use cases, entities, business logic
- **Presentation Layer** : BLoC state management, widgets, UI

### BLoC State Management

Pattern pour gérer l'état de l'application de manière réactive.

### OIDC/PKCE Authentication

Authentification sécurisée via OpenID Connect avec code verifier pour les applications mobiles.

### WebSocket STOMP

Pour la communication bidirectionnelle en temps réel (chat, notifications).

### Local Cache avec Hive

Base de données locale NoSQL pour le stockage offline et le cache.

## Lancer en local

### Prérequis

- Flutter 3.x (SDK 3.10+)
- Dart 3.0+
- Xcode 14+ (pour iOS)
- Android Studio / Android SDK (pour Android)
- Node.js (optionnel, pour le web)

### Installation et configuration

```bash
# Cloner le repository
git clone <repo-url>
cd plantogether-app

# Installer les dépendances
flutter pub get

# Générer les fichiers Hive
flutter packages pub run build_runner build

# Configuration Keycloak (voir lib/core/config/)
# Mettre à jour les URLs en fonction de votre environnement
```

### Démarrage

```bash
# Démarrer sur Android
flutter run -d <device_id>

# Ou sur un emulator Android (après avoir lancé l'emulator)
flutter run

# Pour iOS (macOS uniquement)
flutter run -d <iOS_device_id>

# Ou sur le simulateur iOS
open -a Simulator
flutter run

# Pour le Web
flutter run -d chrome

# Build iOS (requiert Apple Developer account)
flutter build ios

# Build Android
flutter build apk
flutter build appbundle

# Build Web
flutter build web
```

## Architecture du projet

```
plantogether-app/
├── android/                      # Configuration Android
├── ios/                          # Configuration iOS
├── web/                          # Configuration Web
├── pubspec.yaml                  # Dépendances Flutter
├── pubspec.lock                  # Lock file
│
├── lib/
│   ├── main.dart                 # Point d'entrée
│   │
│   ├── core/
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_styles.dart
│   │   │   └── app_theme.dart
│   │   │
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── api_endpoints.dart
│   │   │   └── keycloak_config.dart
│   │   │
│   │   ├── config/
│   │   │   ├── keycloak_setup.dart
│   │   │   ├── hive_setup.dart
│   │   │   └── fcm_setup.dart
│   │   │
│   │   └── di/
│   │       └── service_locator.dart  # GetIt dependency injection
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   ├── repositories/
│   │   │   │   └── models/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       └── screens/
│   │   │
│   │   ├── trip/
│   │   ├── poll/
│   │   ├── destination/
│   │   ├── expense/
│   │   ├── task/
│   │   ├── chat/
│   │   └── notification/
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── common_app_bar.dart
│       │   ├── trip_card.dart
│       │   ├── custom_button.dart
│       │   └── ... (autres widgets)
│       ├── utils/
│       │   ├── extensions/
│       │   ├── validators/
│       │   └── formatters/
│       └── models/
│           └── ... (modèles partagés)
│
└── test/                         # Tests unitaires et integration
```

## Configuration

### pubspec.yaml - Dépendances principales

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Navigation
  go_router: ^12.0.0

  # State Management
  flutter_bloc: ^8.1.0
  bloc: ^8.1.0

  # Authentication
  flutter_appauth: ^6.1.0

  # HTTP Client
  dio: ^5.3.0

  # Local Storage
  hive: ^2.2.0
  hive_flutter: ^1.1.0

  # WebSocket
  stomp_dart_client: ^2.0.0

  # Push Notifications
  firebase_core: ^2.24.0
  firebase_messaging: ^14.6.0

  # Date/Time
  intl: ^0.19.0

  # UI/UX
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0

  # Utilities
  get_it: ^7.6.0      # Dependency injection
  equatable: ^2.0.0   # Value equality

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code generation
  build_runner: ^2.4.0
  hive_generator: ^2.0.0

  # Testing
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter
```

### lib/core/config/keycloak_setup.dart

```dart
import 'package:flutter_appauth/flutter_appauth.dart';

class KeycloakConfig {
  static const String discoveryUrl = 'http://localhost:8080/realms/plantogether/.well-known/openid-configuration';
  static const String clientId = 'plantogether-mobile';
  static const String redirectUrl = 'com.plantogether.app://oauth-callback';
  static const String scopes = ['openid', 'profile', 'email'];
  
  static final FlutterAppAuth _appAuth = const FlutterAppAuth();
  
  static Future<AuthorizationTokenResponse?> login() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl: discoveryUrl,
          scopes: scopes.split(','),
          promptValues: ['login'],
          additionalParameters: {
            'access_type': 'offline',
          },
        ),
      );
      return result;
    } catch (e) {
      print('Keycloak login error: $e');
      return null;
    }
  }
  
  static Future<void> logout(String? idTokenHint) async {
    try {
      await _appAuth.endSession(
        EndSessionRequest(
          discoveryUrl: discoveryUrl,
          idTokenHint: idTokenHint,
        ),
      );
    } catch (e) {
      print('Keycloak logout error: $e');
    }
  }
}
```

### Dio HTTP Client avec Bearer Token

```dart
class DioClient {
  late Dio _dio;
  
  DioClient(String baseUrl, String? accessToken) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    
    // Interceptor pour ajouter le Bearer token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onError: (error, handler) {
          // Gestion des erreurs 401 (redirection login)
          if (error.response?.statusCode == 401) {
            // Trigger logout
          }
          return handler.next(error);
        },
      ),
    );
  }
  
  Future<Response> get(String path) => _dio.get(path);
  Future<Response> post(String path, dynamic data) => _dio.post(path, data: data);
  Future<Response> put(String path, dynamic data) => _dio.put(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
}
```

### Hive Local Storage

```dart
@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String email;
  
  @HiveField(2)
  final String name;
  
  UserModel({
    required this.id,
    required this.email,
    required this.name,
  });
}

// Initialization
void setupHive() {
  Hive.registerAdapter(UserModelAdapter());
  Hive.init(getApplicationDocumentsDirectory().path);
}

// Usage
Future<void> cacheUser(UserModel user) async {
  final box = await Hive.openBox<UserModel>('users');
  await box.put(user.id, user);
}
```

### WebSocket STOMP pour Chat

```dart
class ChatStompClient {
  late StompClient _stompClient;
  final String _url = 'ws://localhost:8080/api/chat/ws';
  
  void connect(String token) {
    _stompClient = StompClient(
      config: StompConfig(
        url: _url,
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
    _stompClient.activate();
  }
  
  void onConnect(StompFrame connectFrame) {
    // S'abonner aux messages
    _stompClient.subscribe(
      destination: '/user/queue/messages',
      callback: (StompFrame frame) {
        // Recevoir les messages
        print('Message reçu: ${frame.body}');
      },
    );
  }
  
  void sendMessage(String tripId, String content) {
    _stompClient.send(
      destination: '/app/chat/send',
      body: jsonEncode({
        'tripId': tripId,
        'content': content,
      }),
    );
  }
  
  void onDisconnect(StompFrame disconnectFrame) {
    print('Disconnected');
  }
  
  void disconnect() {
    _stompClient.deactivate();
  }
}
```

### Firebase Cloud Messaging (Push Notifications)

```dart
void setupFCM() {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Demander la permission
  messaging.requestPermission();
  
  // Récupérer le token device
  messaging.getToken().then((token) {
    print('FCM Token: $token');
    // Envoyer au serveur pour enregistrement
  });
  
  // Écouter les messages en foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Message reçu: ${message.notification?.title}');
    // Afficher une notification
  });
  
  // Gérer le tap sur la notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Naviguer vers l'écran approprié
  });
}
```

## Dépendances / Prérequis

### Services externes

- **API Gateway** (port 8080) : Pour les requêtes REST
- **Keycloak** (port 8080) : Pour l'authentification OIDC
- **Firebase** : Pour les push notifications
- **Chat WebSocket** : Pour les messages en temps réel

### Outils de développement

- **Flutter SDK** 3.10+
- **Dart** 3.0+
- **Xcode** 14+ (macOS)
- **Android Studio** + Android SDK
- **VS Code** ou **IntelliJ IDEA** avec plugins Flutter/Dart

## Testing

### Tests unitaires

```bash
# Lancer tous les tests
flutter test

# Lancer un fichier de test spécifique
flutter test test/features/trip/bloc_test.dart

# Avec couverture
flutter test --coverage
```

### Tests d'intégration

```bash
# Lancer les tests d'intégration
flutter test integration_test/

# Sur un device spécifique
flutter test integration_test/ -d <device_id>
```

## Building et Distribution

### iOS

```bash
# Build pour iOS
flutter build ios --release

# Ouvrir dans Xcode pour configurer les signing
open ios/Runner.xcworkspace

# Build pour App Store
flutter build ios --release
# Ensuite archiver et soumettre via Xcode
```

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (pour Play Store)
flutter build appbundle --release

# Build avec obfuscation
flutter build appbundle --release --obfuscate --split-debug-info=build/app/profile
```

### Web

```bash
# Build Web
flutter build web --release

# Servir en local
python -m http.server 8000 --directory build/web
```

## Troubleshooting

### Keycloak authentication fails

- Vérifier l'URL de découverte OpenID
- Vérifier le clientId et redirectUrl
- Vérifier les permissions dans le realm Keycloak

### WebSocket connection issues

- Vérifier que le serveur de chat est actif
- Vérifier les logs du serveur
- Vérifier la configuration CORS

### Push notifications not received

- Vérifier que FCM est correctement configuré
- Vérifier le token FCM enregistré auprès du serveur
- Vérifier les permissions sur l'appareil

### Build failures

- Exécuter `flutter clean`
- Exécuter `flutter pub get`
- Mettre à jour Flutter SDK : `flutter upgrade`

## Documentation supplémentaire

- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter BLoC Library](https://bloclibrary.dev/)
- [Go Router Navigation](https://pub.dev/packages/go_router)
- [Flutter AppAuth](https://pub.dev/packages/flutter_appauth)
- [Firebase Cloud Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [Hive Database](https://docs.hivedb.dev/)
- [STOMP Client Dart](https://pub.dev/packages/stomp_dart_client)
