import 'dart:async';

import 'package:plantogether_app/core/network/stomp_client_manager.dart';

/// Test harness for STOMP-aware blocs. Captures the last [onTripUpdate]
/// callback and exposes a connection-state controller for emitting state
/// transitions in tests.
class FakeStompClientManager implements StompClientManager {
  final StreamController<StompConnectionState> stateController =
      StreamController<StompConnectionState>.broadcast();
  void Function(Map<String, dynamic>)? lastCallback;
  FakeTripStompSubscription? lastSubscription;
  int connectCount = 0;

  @override
  Future<TripStompSubscription> connect({
    required String endpointPath,
    required String tripId,
    required void Function(Map<String, dynamic>) onTripUpdate,
  }) async {
    connectCount++;
    lastCallback = onTripUpdate;
    final sub = FakeTripStompSubscription(stateController.stream);
    lastSubscription = sub;
    return sub;
  }
}

class FakeTripStompSubscription implements TripStompSubscription {
  final Stream<StompConnectionState> _stream;
  bool disconnectCalled = false;

  FakeTripStompSubscription(this._stream);

  @override
  Stream<StompConnectionState> get connectionState => _stream;

  @override
  void disconnect() {
    disconnectCalled = true;
  }
}
