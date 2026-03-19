import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../security/auth_service.dart';

class StompClientManager {
  StompClient? _client;
  final AuthService _authService;

  StompClientManager(this._authService);

  Future<void> connect({required String tripId}) async {
    final token = await _authService.getAccessToken();
    _client = StompClient(
      config: StompConfig.SockJS(
        url: const String.fromEnvironment('WS_URL', defaultValue: 'http://10.0.2.2:8080/ws'),
        connectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (frame) {
          _client!.subscribe(
            destination: '/topic/trips/$tripId',
            callback: (frame) {/* handle message */},
          );
        },
      ),
    );
    _client!.activate();
  }

  void disconnect() => _client?.deactivate();
}
