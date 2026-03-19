import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keycloakBaseUrl = String.fromEnvironment(
  'KEYCLOAK_URL',
  defaultValue: 'http://10.0.2.2:8180',
);
const _realm          = 'plantogether';
const _clientId       = 'plantogether-app';
const _redirectUri    = 'com.plantogether.app://callback';
const _issuer         = '$_keycloakBaseUrl/realms/$_realm';

class AuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  Future<void> login() async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        _clientId,
        _redirectUri,
        issuer: _issuer,
        scopes: ['openid', 'profile', 'email', 'offline_access'],
      ),
    );
    if (result != null) {
      await _storage.write(key: 'access_token',  value: result.accessToken);
      await _storage.write(key: 'refresh_token', value: result.refreshToken);
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
