import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../constants/api_constants.dart';
import '../security/device_id_service.dart';

enum StompConnectionState { connecting, connected, reconnecting, disconnected, rejected }

const List<int> kStompReconnectBackoffMs = [1000, 2000, 4000, 8000, 16000];

class StompClientManager {
  final DeviceIdService _deviceIdService;

  StompClientManager(this._deviceIdService);

  Future<TripStompSubscription> connect({
    required String endpointPath,
    required String tripId,
    required void Function(Map<String, dynamic>) onTripUpdate,
  }) async {
    final deviceId = await _deviceIdService.getOrCreateDeviceId();
    final controller = StreamController<StompConnectionState>.broadcast();
    final sub = TripStompSubscription._(controller);

    StompClient buildClient() {
      late StompClient client;
      client = StompClient(
        config: StompConfig.sockJS(
          url: '${ApiConstants.wsUrl}$endpointPath',
          stompConnectHeaders: {ApiConstants.deviceIdHeader: deviceId},
          onConnect: (_) {
            if (sub._isClosed || sub._isRejected) return;
            sub._attempt = 0;
            controller.add(StompConnectionState.connected);
            client.subscribe(
              destination: '/topic/trips/$tripId/updates',
              callback: (frame) {
                final body = frame.body;
                if (body == null || body.isEmpty) return;
                try {
                  final decoded = json.decode(body);
                  if (decoded is Map<String, dynamic>) {
                    onTripUpdate(decoded);
                  }
                } catch (_) {}
              },
            );
          },
          onDisconnect: (_) {
            if (sub._isClosed) return;
            controller.add(StompConnectionState.disconnected);
          },
          onWebSocketError: (_) {
            sub._scheduleRetry();
          },
          onStompError: (_) {
            // Server-emitted STOMP ERROR (e.g. non-member SUBSCRIBE rejected).
            // Terminal authorization failure — stop retrying.
            sub._markRejected();
          },
          // Disable the library's auto-reconnect; we drive retries manually with exponential backoff.
          reconnectDelay: Duration.zero,
        ),
      );
      return client;
    }

    sub._reactivate = () {
      if (sub._isClosed || sub._isRejected) return;
      sub._client?.deactivate();
      final next = buildClient();
      sub._client = next;
      next.activate();
    };

    final initial = buildClient();
    sub._client = initial;
    controller.add(StompConnectionState.connecting);
    initial.activate();

    return sub;
  }
}

class TripStompSubscription {
  final StreamController<StompConnectionState> _controller;

  int _attempt = 0;
  bool _isClosed = false;
  bool _isRejected = false;
  Timer? _retryTimer;
  StompClient? _client;
  void Function()? _reactivate;

  TripStompSubscription._(this._controller);

  Stream<StompConnectionState> get connectionState => _controller.stream;

  void _scheduleRetry() {
    if (_isClosed || _isRejected) return;
    if (_attempt >= kStompReconnectBackoffMs.length) {
      if (!_controller.isClosed) _controller.add(StompConnectionState.disconnected);
      _client?.deactivate();
      return;
    }
    final delayMs = kStompReconnectBackoffMs[_attempt];
    _attempt++;
    if (!_controller.isClosed) _controller.add(StompConnectionState.reconnecting);
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_isClosed || _isRejected) return;
      _reactivate?.call();
    });
  }

  void _markRejected() {
    if (_isClosed || _isRejected) return;
    _isRejected = true;
    _retryTimer?.cancel();
    if (!_controller.isClosed) _controller.add(StompConnectionState.rejected);
    _client?.deactivate();
  }

  void disconnect() {
    if (_isClosed) return;
    _isClosed = true;
    _retryTimer?.cancel();
    _client?.deactivate();
    if (!_controller.isClosed) _controller.close();
  }
}
