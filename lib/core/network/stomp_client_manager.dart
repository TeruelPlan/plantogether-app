import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../security/device_id_service.dart';

class StompClientManager {
  StompClient? _client;
  final DeviceIdService _deviceIdService;

  StompClientManager(this._deviceIdService);

  Future<void> connect({required String tripId}) async {
    final deviceId = await _deviceIdService.getOrCreateDeviceId();
    _client = StompClient(
      config: StompConfig.sockJS(
        url: const String.fromEnvironment(
          'WS_URL',
          defaultValue: 'http://10.0.2.2:8080/ws',
        ),
        stompConnectHeaders: {'X-Device-Id': deviceId},
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
